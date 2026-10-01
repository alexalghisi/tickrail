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

  testWidgets('an order matches on the next frame and opens a position', (
    tester,
  ) async {
    await _openLadder(tester);
    await tester.enterText(find.byKey(const Key('stake')), '10');
    await _tapColumn(tester, 0.5);
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pump();
    expect(find.byKey(const Key('position')), findsNothing);
    expect(find.byKey(const Key('hedge')), findsNothing);

    await tester.tap(find.byKey(const Key('tape-next')));
    await tester.pump();
    expect(find.text('Back 1.92  10.00  matched 10.00'), findsOneWidget);
    expect(find.text('If wins 9.20  if loses -10.00'), findsOneWidget);
    expect(find.byKey(const Key('amend-o1')), findsNothing);
    expect(find.byKey(const Key('cancel-o1')), findsNothing);
  });

  testWidgets('a position can be hedged at the selected price', (tester) async {
    await _openLadder(tester);
    await tester.enterText(find.byKey(const Key('stake')), '10');
    await _tapColumn(tester, 0.5);
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tape-next')));
    await tester.pump();
    expect(find.text('Hedge: Lay 10.00 @ 1.92  locks 0.00'), findsOneWidget);

    await _tapColumn(tester, 3.5, row: 4);
    expect(find.text('Hedge: Lay 9.80 @ 1.96  locks -0.21'), findsOneWidget);

    await tester.tap(find.byKey(const Key('hedge')));
    await tester.pump();
    expect(find.text('Lay 1.96  9.80'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tape-next')));
    await tester.pump();
    expect(find.text('Lay 1.96  9.80  matched 9.80'), findsOneWidget);
    expect(find.text('If wins -0.21  if loses -0.20'), findsOneWidget);
  });

  testWidgets('a part matched order keeps its matched stake', (tester) async {
    await _openLadder(tester);
    await tester.enterText(find.byKey(const Key('stake')), '200');
    await _tapColumn(tester, 0.5);
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('tape-next')));
    await tester.pump();
    expect(find.text('Back 1.92  200.00  matched 98.50'), findsOneWidget);

    await tester.tap(find.byKey(const Key('amend-o1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amend-stake')), '50');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('98.50 is already matched.'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('cancel-o1')));
    await tester.pump();
    expect(find.text('Back 1.92  98.50  matched 98.50'), findsOneWidget);
    expect(find.byKey(const Key('cancel-o1')), findsNothing);
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

Future<void> _tapColumn(
  WidgetTester tester,
  double column, {
  int row = 0,
}) async {
  await tester.ensureVisible(find.byType(LadderRail));
  await tester.pumpAndSettle();
  final rect = tester.getRect(find.byType(LadderRail));
  final col = rect.width / 5;
  await tester.tapAt(
    Offset(
      rect.left + col * column,
      rect.top + LadderRailBox.headerHeight + row * LadderRailBox.rowHeight + 8,
    ),
  );
  await tester.pump();
}

String _label(WidgetTester tester) {
  return tester.getSemantics(find.byType(LadderRail)).label;
}
