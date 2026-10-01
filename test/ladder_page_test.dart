import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickrail/data/desk_store.dart';
import 'package:tickrail/domain/tape.dart';
import 'package:tickrail/paint/ladder_rail.dart';
import 'package:tickrail/tickrail_app.dart';

void main() {
  testWidgets('a back order can be placed, amended and cancelled', (
    tester,
  ) async {
    await _openLadder(tester);

    expect(find.text('No open orders.'), findsOneWidget);
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pump();
    expect(find.text('Pick a back or lay price.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('stake')), '10');
    await _tapColumn(tester, 0.5);
    expect(
      find.textContaining('Back 1.92  risk 10.00  win 9.20'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pump();
    expect(find.text('Back 1.92  10.00'), findsOneWidget);
    expect(find.text('Liability 10.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('amend-o1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amend-stake')), '4');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Back 1.92  4.00'), findsOneWidget);
    expect(find.text('Liability 4.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel-o1')));
    await tester.pump();
    expect(find.text('No open orders.'), findsOneWidget);
    expect(find.text('Liability 0.00'), findsOneWidget);
  });

  testWidgets('a lay shows the price multiple as risk', (tester) async {
    await _openLadder(tester);
    await tester.enterText(find.byKey(const Key('stake')), '10');
    await _tapColumn(tester, 3.5);
    expect(
      find.textContaining('Lay 1.92  risk 9.20  win 10.00'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pump();
    expect(find.text('Liability 9.20'), findsOneWidget);
  });

  testWidgets('the tape steps and plays without a wall clock', (tester) async {
    await _openLadder(tester);
    expect(_label(tester), contains('frame 0'));

    await tester.tap(find.byKey(const Key('tape-next')));
    await tester.pump();
    expect(_label(tester), contains('frame 1'));

    await tester.tap(find.byKey(const Key('tape-prev')));
    await tester.pump();
    expect(_label(tester), contains('frame 0'));

    await tester.tap(find.byKey(const Key('tape-play')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(_label(tester), isNot(contains('frame 0')));

    await tester.tap(find.byKey(const Key('tape-play')));
    await tester.pump();
  });

  testWidgets('a bad stake is refused', (tester) async {
    await _openLadder(tester);
    await tester.enterText(find.byKey(const Key('stake')), '0');
    await _tapColumn(tester, 0.5);
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pump();
    expect(find.text('Enter a stake in pounds.'), findsOneWidget);
    expect(find.text('No open orders.'), findsOneWidget);
  });
}

Future<void> _openLadder(WidgetTester tester) async {
  tester.view.physicalSize = const Size(420, 1100);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    TickrailApp(store: DeskStore(), tape: buildDemoTape()),
  );
  await tester.tap(find.byKey(const Key('open-m1')));
  await tester.pumpAndSettle();
}

Future<void> _tapColumn(WidgetTester tester, double column) async {
  await tester.ensureVisible(find.byType(LadderRail));
  await tester.pumpAndSettle();
  final rect = tester.getRect(find.byType(LadderRail));
  final col = rect.width / 5;
  await tester.tapAt(
    Offset(rect.left + col * column, rect.top + LadderRailBox.headerHeight + 8),
  );
  await tester.pump();
}

String _label(WidgetTester tester) {
  return tester.getSemantics(find.byType(LadderRail)).label;
}
