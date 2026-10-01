import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickrail/domain/side.dart';
import 'package:tickrail/domain/tape.dart';
import 'package:tickrail/paint/ladder_rail.dart';

void main() {
  testWidgets('rail keeps a fixed slot height', (tester) async {
    final handle = _handle(buildDemoTape()[0]);
    await tester.pumpWidget(_host(handle, (_, _) {}));
    final box = tester.renderObject<LadderRailBox>(find.byType(LadderRail));
    expect(box.size.width, 300);
    expect(
      box.size.height,
      LadderRailBox.headerHeight + 17 * LadderRailBox.rowHeight,
    );
  });

  testWidgets('a new frame paints without rebuilding the rail widget', (
    tester,
  ) async {
    final tape = buildDemoTape();
    final handle = _handle(tape[0]);
    var builds = 0;
    await tester.pumpWidget(
      _Count(onBuild: () => builds += 1, child: _host(handle, (_, _) {})),
    );
    expect(builds, 1);
    expect(_label(tester), contains('frame 0'));

    handle.show(_snapshot(tape[3]));
    await tester.pump();

    expect(builds, 1);
    expect(_label(tester), contains('frame 3'));
    expect(_label(tester), isNot(contains('frame 0')));
  });

  testWidgets('back and lay columns pick a side, the odds column does not', (
    tester,
  ) async {
    final frame = buildDemoTape()[0];
    final handle = _handle(frame);
    int? oddsIndex;
    Side? side;
    await tester.pumpWidget(
      _host(handle, (index, picked) {
        oddsIndex = index;
        side = picked;
      }),
    );

    final rect = tester.getRect(find.byType(LadderRail));
    final col = rect.width / 5;
    final rowTop =
        rect.top + LadderRailBox.headerHeight + 8 * LadderRailBox.rowHeight;

    await tester.tapAt(Offset(rect.left + col * 0.5, rowTop + 8));
    expect(oddsIndex, frame.quotes[8].oddsIndex);
    expect(side, Side.back);

    await tester.tapAt(Offset(rect.left + col * 2.5, rowTop + 8));
    expect(side, Side.back);

    await tester.tapAt(Offset(rect.left + col * 3.5, rowTop + 8));
    expect(side, Side.lay);
    expect(oddsIndex, frame.quotes[8].oddsIndex);
  });
}

RailHandle _handle(TapeFrame frame) {
  final handle = RailHandle()..show(_snapshot(frame));
  return handle;
}

LadderSnapshot _snapshot(TapeFrame frame) {
  return LadderSnapshot(seq: frame.seq, quotes: frame.quotes);
}

String _label(WidgetTester tester) {
  return tester.getSemantics(find.byType(LadderRail)).label;
}

Widget _host(
  RailHandle handle,
  void Function(int oddsIndex, Side side) onSelect,
) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 300,
        child: LadderRail(handle: handle, onSelect: onSelect),
      ),
    ),
  );
}

class _Count extends StatelessWidget {
  const _Count({required this.onBuild, required this.child});

  final VoidCallback onBuild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return child;
  }
}
