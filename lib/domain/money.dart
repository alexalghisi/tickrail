class Stake {
  const Stake(this.cents);

  final int cents;

  static Stake? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final parts = text.split('.');
    if (parts.length > 2) return null;
    if (!_digits(parts[0])) return null;
    var frac = 0;
    if (parts.length == 2) {
      final tail = parts[1];
      if (tail.isEmpty || tail.length > 2 || !_digits(tail)) return null;
      frac = int.parse(tail.padRight(2, '0'));
    }
    final cents = int.parse(parts[0]) * 100 + frac;
    if (cents <= 0) return null;
    return Stake(cents);
  }
}

bool _digits(String value) {
  if (value.isEmpty) return false;
  for (final code in value.codeUnits) {
    if (code < 48 || code > 57) return false;
  }
  return true;
}

String formatCents(int cents) {
  final sign = cents < 0 ? '-' : '';
  final abs = cents.abs();
  final whole = abs ~/ 100;
  final frac = (abs % 100).toString().padLeft(2, '0');
  return '$sign$whole.$frac';
}

int priceMultipleCents(int stakeCents, int oddsHundredths) {
  if (stakeCents < 0) {
    throw ArgumentError.value(stakeCents, 'stakeCents');
  }
  if (oddsHundredths < 100) {
    throw ArgumentError.value(oddsHundredths, 'oddsHundredths');
  }
  final numerator = stakeCents * (oddsHundredths - 100);
  final cents = numerator ~/ 100;
  final remainder = numerator.abs() % 100;
  if (remainder >= 50) return cents + 1;
  return cents;
}
