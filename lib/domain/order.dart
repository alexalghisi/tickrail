import 'package:tickrail/domain/money.dart';
import 'package:tickrail/domain/side.dart';

class Order {
  const Order({
    required this.id,
    required this.marketId,
    required this.side,
    required this.oddsIndex,
    required this.stakeCents,
  });

  final String id;
  final String marketId;
  final Side side;
  final int oddsIndex;
  final int stakeCents;

  Order withStake(int stakeCents) {
    return Order(
      id: id,
      marketId: marketId,
      side: side,
      oddsIndex: oddsIndex,
      stakeCents: stakeCents,
    );
  }

  int riskCents(int oddsHundredths) {
    if (side == Side.back) return stakeCents;
    return priceMultipleCents(stakeCents, oddsHundredths);
  }
}
