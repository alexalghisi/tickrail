import 'package:tickrail/domain/odds.dart';

class Quote {
  const Quote({
    required this.oddsIndex,
    required this.backCents,
    required this.layCents,
  });

  final int oddsIndex;
  final int backCents;
  final int layCents;
}

class TapeFrame {
  const TapeFrame({required this.seq, required this.quotes});

  final int seq;
  final List<Quote> quotes;
}

class Tape {
  Tape(this.frames) {
    if (frames.isEmpty) {
      throw ArgumentError('tape has no frames');
    }
    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];
      if (frame.seq != i) {
        throw ArgumentError('seq gap at $i');
      }
      if (frame.quotes.isEmpty) {
        throw ArgumentError('empty frame $i');
      }
      var previous = -1;
      for (final quote in frame.quotes) {
        if (quote.oddsIndex <= previous ||
            quote.oddsIndex >= Odds.ladder.length) {
          throw ArgumentError('odds index out of order');
        }
        previous = quote.oddsIndex;
      }
    }
  }

  final List<TapeFrame> frames;

  int get length => frames.length;

  TapeFrame operator [](int index) => frames[index];
}

Tape buildDemoTape() {
  final mid = Odds.byHundredths(200).index;
  final frames = <TapeFrame>[];
  for (var seq = 0; seq < 24; seq++) {
    final quotes = <Quote>[];
    for (var row = -8; row <= 8; row++) {
      final back = 8000 + ((seq * 37 + (row + 8) * 19) % 90) * 50;
      final lay = 7500 + ((seq * 29 + (row + 8) * 23) % 90) * 50;
      quotes.add(Quote(oddsIndex: mid + row, backCents: back, layCents: lay));
    }
    frames.add(TapeFrame(seq: seq, quotes: quotes));
  }
  return Tape(frames);
}
