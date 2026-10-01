import 'package:flutter_test/flutter_test.dart';
import 'package:tickrail/domain/odds.dart';

void main() {
  test('ladder covers every published band edge', () {
    expect(Odds.ladder, hasLength(350));
    expect(Odds.ladder.first.hundredths, 101);
    expect(Odds.ladder.last.hundredths, 100000);
    expect(_next(200), 202);
    expect(_next(300), 305);
    expect(_next(400), 410);
    expect(_next(600), 620);
    expect(_next(1000), 1050);
    expect(_next(2000), 2100);
    expect(_next(3000), 3200);
    expect(_next(5000), 5500);
    expect(_next(10000), 11000);
  });

  test('prices increase once each', () {
    final prices = Odds.ladder.map((odds) => odds.hundredths).toList();
    final sorted = <int>[...prices]..sort();
    expect(prices, orderedEquals(sorted));
    expect(prices.toSet(), hasLength(prices.length));
    for (var i = 0; i < Odds.ladder.length; i++) {
      expect(Odds.ladder[i].index, i);
    }
  });

  test('labels stay on the tick the ladder publishes', () {
    expect(Odds.byHundredths(101).label, '1.01');
    expect(Odds.byHundredths(200).label, '2.00');
    expect(Odds.byHundredths(1050).label, '10.5');
    expect(Odds.byHundredths(1100).label, '11');
    expect(Odds.byHundredths(10000).label, '100');
    expect(Odds.byHundredths(100000).label, '1000');
  });

  test('shift stops at the ends of the ladder', () {
    expect(Odds.shift(0, -1), isNull);
    expect(Odds.shift(Odds.ladder.length - 1, 1), isNull);
    expect(Odds.shift(0, 1), 1);
  });

  test('unknown prices are rejected', () {
    expect(() => Odds.byHundredths(201), throwsArgumentError);
  });
}

int _next(int hundredths) {
  final odds = Odds.byHundredths(hundredths);
  return Odds.at(odds.index + 1).hundredths;
}
