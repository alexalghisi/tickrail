import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:tickrail/main.dart' as app;
import 'package:tickrail/paint/ladder_rail.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('open a market, place a back, cancel it', (tester) async {
    app.main();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Match Odds'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('stake')), '10');
    await tester.ensureVisible(find.byType(LadderRail));
    await tester.pumpAndSettle();
    final rect = tester.getRect(find.byType(LadderRail));
    final col = rect.width / 5;
    await tester.tapAt(
      Offset(rect.left + col * 0.5, rect.top + LadderRailBox.headerHeight + 8),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('place-order')));
    await tester.pumpAndSettle();

    expect(find.text('Back 1.92  10.00'), findsOneWidget);
    expect(find.text('Liability 10.00'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel-o1')));
    await tester.pumpAndSettle();
    expect(find.text('No open orders.'), findsOneWidget);
    expect(find.text('Liability 0.00'), findsOneWidget);
  });
}
