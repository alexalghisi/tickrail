import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tickrail/data/desk_store.dart';
import 'package:tickrail/domain/tape.dart';
import 'package:tickrail/tickrail_app.dart';

void main() {
  testWidgets('markets can be added, renamed and deleted', (tester) async {
    await _pump(tester, DeskStore.empty());

    await tester.tap(find.byKey(const Key('add-market')));
    await tester.pump();
    expect(find.text('Name and event are required.'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('market-name')),
      'Correct Score',
    );
    await tester.enterText(find.byKey(const Key('event-name')), 'Final');
    await tester.tap(find.byKey(const Key('add-market')));
    await tester.pump();
    expect(find.text('Correct Score'), findsOneWidget);
    expect(find.text('Final'), findsOneWidget);

    await tester.tap(find.byKey(const Key('edit-m1')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('edit-name')), '  ');
    await tester.tap(find.text('Save'));
    await tester.pump();
    expect(find.text('Name and event are required.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('edit-name')), 'Over Under');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Over Under'), findsOneWidget);
    expect(find.text('Correct Score'), findsNothing);

    await tester.tap(find.byKey(const Key('delete-m1')));
    await tester.pump();
    expect(find.text('No markets yet.'), findsOneWidget);
  });
}

Future<void> _pump(WidgetTester tester, DeskStore store) async {
  tester.view.physicalSize = const Size(420, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(TickrailApp(store: store, tape: buildDemoTape()));
}
