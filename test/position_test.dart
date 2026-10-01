import 'package:flutter_test/flutter_test.dart';
import 'package:tickrail/domain/position.dart';
import 'package:tickrail/domain/side.dart';

void main() {
  test('no matched bets is a flat position', () {
    const position = Position();
    expect(position.isFlat, isTrue);
    expect(position.hedgeAt(200), isNull);
  });

  test('a matched back wins the price multiple and loses the stake', () {
    final position = const Position().matched(Side.back, 1000, 192);
    expect(position.winCents, 920);
    expect(position.loseCents, -1000);
    expect(position.isFlat, isFalse);
  });

  test('a matched lay loses the price multiple and wins the stake', () {
    final position = const Position().matched(Side.lay, 1000, 192);
    expect(position.winCents, -920);
    expect(position.loseCents, 1000);
  });

  test('bets on both sides net out', () {
    final position = const Position()
        .matched(Side.back, 1000, 200)
        .matched(Side.lay, 1000, 200);
    expect(position.isFlat, isTrue);
  });

  test('hedging at the entry price locks nothing', () {
    final hedge = const Position().matched(Side.back, 1000, 192).hedgeAt(192)!;
    expect(hedge.side, Side.lay);
    expect(hedge.stakeCents, 1000);
    expect(hedge.lockedCents, 0);
  });

  test('a back hedged at a shorter price locks a profit', () {
    final hedge = const Position().matched(Side.back, 1000, 192).hedgeAt(180)!;
    expect(hedge.side, Side.lay);
    expect(hedge.stakeCents, 1067);
    expect(hedge.lockedCents, 66);
  });

  test('a back hedged at a longer price locks a loss', () {
    final hedge = const Position().matched(Side.back, 1000, 192).hedgeAt(210)!;
    expect(hedge.side, Side.lay);
    expect(hedge.stakeCents, 914);
    expect(hedge.lockedCents, -86);
  });

  test('a lay is hedged with a back', () {
    final hedge = const Position().matched(Side.lay, 1000, 192).hedgeAt(210)!;
    expect(hedge.side, Side.back);
    expect(hedge.stakeCents, 914);
    expect(hedge.lockedCents, 85);
  });

  test('no other whole-cent stake leaves the outcomes closer', () {
    for (final price in <int>[101, 150, 192, 305, 1050, 100000]) {
      final position = const Position().matched(Side.back, 2537, 344);
      final hedge = position.hedgeAt(price)!;
      final after = position.matched(hedge.side, hedge.stakeCents, price);
      expect(
        (after.winCents - after.loseCents).abs(),
        lessThanOrEqualTo(price ~/ 200 + 1),
      );
    }
  });

  test('a price at or below evens money is refused', () {
    final position = const Position().matched(Side.back, 1000, 192);
    expect(() => position.hedgeAt(100), throwsArgumentError);
  });
}
