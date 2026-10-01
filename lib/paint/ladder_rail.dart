import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:tickrail/domain/money.dart';
import 'package:tickrail/domain/odds.dart';
import 'package:tickrail/domain/side.dart';
import 'package:tickrail/domain/tape.dart';
import 'package:tickrail/paint/desk_colors.dart';

class CellStake {
  const CellStake({this.backCents = 0, this.layCents = 0});

  final int backCents;
  final int layCents;
}

class LadderSnapshot {
  const LadderSnapshot({
    required this.seq,
    required this.quotes,
    this.stakes = const <int, CellStake>{},
    this.selectedIndex,
    this.selectedSide,
  });

  final int seq;
  final List<Quote> quotes;
  final Map<int, CellStake> stakes;
  final int? selectedIndex;
  final Side? selectedSide;
}

class RailHandle extends ChangeNotifier {
  LadderSnapshot? _snapshot;

  LadderSnapshot get snapshot {
    final value = _snapshot;
    if (value == null) {
      throw StateError('rail has no snapshot');
    }
    return value;
  }

  void show(LadderSnapshot next) {
    _snapshot = next;
    notifyListeners();
  }
}

class LadderRail extends LeafRenderObjectWidget {
  const LadderRail({required this.handle, required this.onSelect, super.key});

  final RailHandle handle;
  final void Function(int oddsIndex, Side side) onSelect;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return LadderRailBox(
      handle: handle,
      onSelect: onSelect,
      textDirection: Directionality.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, LadderRailBox renderObject) {
    renderObject
      ..handle = handle
      ..onSelect = onSelect
      ..textDirection = Directionality.of(context);
  }
}

class LadderRailBox extends RenderBox {
  LadderRailBox({
    required this._handle,
    required this.onSelect,
    required this._textDirection,
  });

  static const double headerHeight = 22;
  static const double rowHeight = 32;

  final TextPainter _text = TextPainter(textDirection: TextDirection.ltr);

  RailHandle _handle;
  void Function(int oddsIndex, Side side) onSelect;
  TextDirection _textDirection;
  var _listening = false;

  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsSemanticsUpdate();
  }

  set handle(RailHandle value) {
    if (identical(_handle, value)) return;
    _stop();
    _handle = value;
    _start();
    markNeedsLayout();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  @override
  bool get isRepaintBoundary => true;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _start();
  }

  @override
  void detach() {
    _stop();
    super.detach();
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _start() {
    if (_listening || !attached) return;
    _handle.addListener(_onRail);
    _listening = true;
  }

  void _stop() {
    if (!_listening) return;
    _handle.removeListener(_onRail);
    _listening = false;
  }

  void _onRail() {
    final nextHeight = _contentHeight;
    if (size.height != nextHeight) markNeedsLayout();
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  double get _contentHeight =>
      headerHeight + _handle.snapshot.quotes.length * rowHeight;

  @override
  void performLayout() {
    final width = constraints.hasBoundedWidth ? constraints.maxWidth : 360.0;
    size = constraints.constrain(Size(width, _contentHeight));
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void handleEvent(PointerEvent event, BoxHitTestEntry entry) {
    if (event is! PointerUpEvent) return;
    final local = event.localPosition;
    if (local.dy < headerHeight || size.width == 0) return;
    final quotes = _handle.snapshot.quotes;
    final row = (local.dy - headerHeight) ~/ rowHeight;
    if (row < 0 || row >= quotes.length) return;
    final column = local.dx ~/ (size.width / 5);
    if (column <= 1) {
      onSelect(quotes[row].oddsIndex, Side.back);
    } else if (column >= 3) {
      onSelect(quotes[row].oddsIndex, Side.lay);
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..textDirection = _textDirection
      ..label = _label();
  }

  String _label() {
    final snapshot = _handle.snapshot;
    final buffer = StringBuffer('frame ${snapshot.seq}');
    for (final quote in snapshot.quotes) {
      buffer.write(
        ' ${Odds.at(quote.oddsIndex).label}'
        ' ${formatCents(quote.backCents)}'
        ' ${formatCents(quote.layCents)}',
      );
    }
    return buffer.toString();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.clipRect(offset & size);
    final snapshot = _handle.snapshot;
    final width = size.width;
    final col = width / 5;
    canvas.drawRect(
      offset & Size(width, _contentHeight),
      Paint()..color = DeskColors.panel,
    );
    _paintHeader(canvas, offset, col);
    for (var row = 0; row < snapshot.quotes.length; row++) {
      _paintRow(canvas, offset, col, row, snapshot);
    }
    canvas.restore();
  }

  void _paintHeader(Canvas canvas, Offset offset, double col) {
    const labels = <String>['Size', 'Back', 'Odds', 'Lay', 'Size'];
    for (var i = 0; i < labels.length; i++) {
      _drawText(
        canvas,
        labels[i],
        Rect.fromLTWH(offset.dx + col * i, offset.dy, col, headerHeight),
        DeskColors.muted,
        size: 10,
        weight: FontWeight.w600,
      );
    }
  }

  void _paintRow(
    Canvas canvas,
    Offset offset,
    double col,
    int row,
    LadderSnapshot snapshot,
  ) {
    final quote = snapshot.quotes[row];
    final top = offset.dy + headerHeight + row * rowHeight;
    final odds = Odds.at(quote.oddsIndex);
    final selected = snapshot.selectedIndex == quote.oddsIndex;
    final stake = snapshot.stakes[quote.oddsIndex];
    final backColor = selected && snapshot.selectedSide == Side.back
        ? DeskColors.backHot
        : DeskColors.back;
    final layColor = selected && snapshot.selectedSide == Side.lay
        ? DeskColors.layHot
        : DeskColors.lay;

    _fill(
      canvas,
      Rect.fromLTWH(offset.dx + col, top, col, rowHeight),
      backColor,
    );
    _fill(
      canvas,
      Rect.fromLTWH(offset.dx + col * 2, top, col, rowHeight),
      DeskColors.odds,
    );
    _fill(
      canvas,
      Rect.fromLTWH(offset.dx + col * 3, top, col, rowHeight),
      layColor,
    );

    _drawText(
      canvas,
      formatCents(quote.backCents),
      Rect.fromLTWH(offset.dx, top, col, rowHeight),
      DeskColors.paper,
      size: 11,
    );
    _drawText(
      canvas,
      odds.label,
      Rect.fromLTWH(offset.dx + col, top, col, rowHeight),
      DeskColors.paper,
    );
    _drawText(
      canvas,
      odds.label,
      Rect.fromLTWH(offset.dx + col * 2, top, col, rowHeight),
      DeskColors.brass,
      weight: FontWeight.w700,
    );
    _drawText(
      canvas,
      odds.label,
      Rect.fromLTWH(offset.dx + col * 3, top, col, rowHeight),
      DeskColors.paper,
    );
    _drawText(
      canvas,
      formatCents(quote.layCents),
      Rect.fromLTWH(offset.dx + col * 4, top, col, rowHeight),
      DeskColors.paper,
      size: 11,
    );

    if (stake != null && stake.backCents > 0) {
      _mark(canvas, offset.dx + col, top, col);
    }
    if (stake != null && stake.layCents > 0) {
      _mark(canvas, offset.dx + col * 3, top, col);
    }
  }

  void _fill(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(rect, Paint()..color = color);
  }

  void _mark(Canvas canvas, double left, double top, double col) {
    canvas.drawRect(
      Rect.fromLTWH(left, top + rowHeight - 3, col, 3),
      Paint()..color = DeskColors.brass,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Rect rect,
    Color color, {
    double size = 12,
    FontWeight weight = FontWeight.w500,
  }) {
    _text
      ..text = TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      )
      ..layout(maxWidth: rect.width);
    _text.paint(
      canvas,
      Offset(
        rect.left + (rect.width - _text.width) / 2,
        rect.top + (rect.height - _text.height) / 2,
      ),
    );
  }
}
