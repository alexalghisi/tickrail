class Odds {
  const Odds._(this.index, this.hundredths);

  final int index;
  final int hundredths;

  static final List<Odds> ladder = List<Odds>.unmodifiable(_build());

  static Odds at(int index) => ladder[index];

  static Odds byHundredths(int hundredths) {
    for (final odds in ladder) {
      if (odds.hundredths == hundredths) return odds;
    }
    throw ArgumentError.value(hundredths, 'hundredths');
  }

  static int? shift(int index, int delta) {
    final next = index + delta;
    if (next < 0 || next >= ladder.length) return null;
    return next;
  }

  String get label => labelFor(hundredths);

  static String labelFor(int hundredths) {
    if (hundredths < 1000) {
      final whole = hundredths ~/ 100;
      final frac = (hundredths % 100).toString().padLeft(2, '0');
      return '$whole.$frac';
    }
    if (hundredths < 10000 && hundredths % 100 != 0) {
      final whole = hundredths ~/ 100;
      final tenth = (hundredths % 100) ~/ 10;
      return '$whole.$tenth';
    }
    return '${hundredths ~/ 100}';
  }

  static List<Odds> _build() {
    const bands = <_Band>[
      _Band(101, 200, 1),
      _Band(202, 300, 2),
      _Band(305, 400, 5),
      _Band(410, 600, 10),
      _Band(620, 1000, 20),
      _Band(1050, 2000, 50),
      _Band(2100, 3000, 100),
      _Band(3200, 5000, 200),
      _Band(5500, 10000, 500),
      _Band(11000, 100000, 1000),
    ];
    final prices = <Odds>[];
    for (final band in bands) {
      for (var price = band.from; price <= band.to; price += band.step) {
        prices.add(Odds._(prices.length, price));
      }
    }
    return prices;
  }
}

class _Band {
  const _Band(this.from, this.to, this.step);

  final int from;
  final int to;
  final int step;
}
