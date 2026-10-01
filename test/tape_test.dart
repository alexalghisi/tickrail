import 'package:flutter_test/flutter_test.dart';
import 'package:tickrail/domain/odds.dart';
import 'package:tickrail/domain/tape.dart';

void main() {
  test('demo tape is a fixed replay', () {
    final first = buildDemoTape();
    final second = buildDemoTape();
    expect(first.length, 24);
    expect(second.length, first.length);
    for (var i = 0; i < first.length; i++) {
      expect(first[i].seq, i);
      expect(first[i].quotes, hasLength(17));
      expect(first[i].quotes.first.backCents, second[i].quotes.first.backCents);
      expect(first[i].quotes.last.layCents, second[i].quotes.last.layCents);
    }
  });

  test('window sits on 2.00', () {
    final frame = buildDemoTape()[0];
    final middle = frame.quotes[8];
    expect(Odds.at(middle.oddsIndex).hundredths, 200);
    expect(frame.quotes[1].oddsIndex, frame.quotes[0].oddsIndex + 1);
  });

  test('a tape without frames is refused', () {
    expect(() => Tape(const <TapeFrame>[]), throwsArgumentError);
  });

  test('a gap in sequence is refused', () {
    final quote = Quote(
      oddsIndex: Odds.byHundredths(200).index,
      backCents: 100,
      layCents: 100,
    );
    expect(
      () => Tape(<TapeFrame>[
        TapeFrame(seq: 0, quotes: <Quote>[quote]),
        TapeFrame(seq: 2, quotes: <Quote>[quote]),
      ]),
      throwsArgumentError,
    );
  });
}
