import 'dart:math' as math;

import 'package:tickrail/domain/money.dart';
import 'package:tickrail/domain/side.dart';

class Hedge {
  const Hedge({
    required this.side,
    required this.stakeCents,
    required this.lockedCents,
  });

  final Side side;
  final int stakeCents;
  final int lockedCents;
}

class Position {
  const Position({this.winCents = 0, this.loseCents = 0});

  final int winCents;
  final int loseCents;

  bool get isFlat => winCents == 0 && loseCents == 0;

  Position matched(Side side, int stakeCents, int oddsHundredths) {
    final multiple = priceMultipleCents(stakeCents, oddsHundredths);
    if (side == Side.back) {
      return Position(
        winCents: winCents + multiple,
        loseCents: loseCents - stakeCents,
      );
    }
    return Position(
      winCents: winCents - multiple,
      loseCents: loseCents + stakeCents,
    );
  }

  Hedge? hedgeAt(int oddsHundredths) {
    if (oddsHundredths <= 100) {
      throw ArgumentError.value(oddsHundredths, 'oddsHundredths');
    }
    final gap = winCents - loseCents;
    final stake = (gap.abs() * 100 + oddsHundredths ~/ 2) ~/ oddsHundredths;
    if (stake == 0) return null;
    final side = gap > 0 ? Side.lay : Side.back;
    final after = matched(side, stake, oddsHundredths);
    return Hedge(
      side: side,
      stakeCents: stake,
      lockedCents: math.min(after.winCents, after.loseCents),
    );
  }
}
