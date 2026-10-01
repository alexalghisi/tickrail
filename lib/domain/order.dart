import 'package:tickrail/domain/money.dart';
import 'package:tickrail/domain/side.dart';

class Order {
  const Order({
    required this.id,
    required this.marketId,
    required this.side,
    required this.oddsIndex,
    required this.stakeCents,
    this.matchedCents = 0,
  });

  final String id;
  final String marketId;
  final Side side;
  final int oddsIndex;
  final int stakeCents;
  final int matchedCents;

  int get remainingCents => stakeCents - matchedCents;

  Order withStake(int stakeCents) {
    if (stakeCents < matchedCents) {
      throw ArgumentError.value(stakeCents, 'stakeCents');
    }
    return Order(
      id: id,
      marketId: marketId,
      side: side,
      oddsIndex: oddsIndex,
      stakeCents: stakeCents,
      matchedCents: matchedCents,
    );
  }

  Order filled(int cents) {
    if (cents <= 0 || cents > remainingCents) {
      throw ArgumentError.value(cents, 'cents');
    }
    return Order(
      id: id,
      marketId: marketId,
      side: side,
      oddsIndex: oddsIndex,
      stakeCents: stakeCents,
      matchedCents: matchedCents + cents,
    );
  }

  int riskCents(int oddsHundredths) {
    if (side == Side.back) return remainingCents;
    return priceMultipleCents(remainingCents, oddsHundredths);
  }
}
