import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickrail/data/desk_store.dart';
import 'package:tickrail/domain/tape.dart';
import 'package:tickrail/paint/ladder_rail.dart';
import 'package:tickrail/tickrail_app.dart';

void main() {
  testWidgets('write ladder frames', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      TickrailApp(store: DeskStore(), tape: buildDemoTape()),
    );
    await tester.tap(find.byKey(const Key('open-m1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byKey(const Key('stake')), '25');
    await tester.pump();
    await tester.ensureVisible(find.byType(LadderRail));
    await tester.pump();

    final rect = tester.getRect(find.byType(LadderRail));
    final col = rect.width / 5;
    await tester.tapAt(
      Offset(rect.left + col * 0.5, rect.top + LadderRailBox.headerHeight + 8),
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pump();

    final dir = Directory('/tmp/tickrail-frames');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);

    for (var i = 0; i < 12; i++) {
      final name = i.toString().padLeft(2, '0');
      await _write(tester, '${dir.path}/frame_$name.png');
      await tester.tap(find.byKey(const Key('tape-next')));
      await tester.pump();
    }
  });
}

Future<void> _write(WidgetTester tester, String path) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const Key('ladder-boundary')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(path).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
