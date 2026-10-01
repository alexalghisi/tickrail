import 'package:flutter_test/flutter_test.dart';
import 'package:tickrail/domain/money.dart';

void main() {
  test('stakes parse as integer cents', () {
    expect(Stake.parse('10')?.cents, 1000);
    expect(Stake.parse('10.5')?.cents, 1050);
    expect(Stake.parse(' 10.50 ')?.cents, 1050);
    expect(Stake.parse('0.01')?.cents, 1);
    expect(Stake.parse(''), isNull);
    expect(Stake.parse('0'), isNull);
    expect(Stake.parse('0.00'), isNull);
    expect(Stake.parse('10.555'), isNull);
    expect(Stake.parse('1.2.3'), isNull);
    expect(Stake.parse('ten'), isNull);
    expect(Stake.parse('-2'), isNull);
  });

  test('format keeps two minor digits', () {
    expect(formatCents(1000), '10.00');
    expect(formatCents(1050), '10.50');
    expect(formatCents(1), '0.01');
    expect(formatCents(0), '0.00');
  });

  test('price multiple rounds half up on the cent', () {
    expect(priceMultipleCents(1000, 250), 1500);
    expect(priceMultipleCents(100, 101), 1);
    expect(priceMultipleCents(1, 101), 0);
    expect(priceMultipleCents(50, 150), 25);
    expect(priceMultipleCents(33, 204), 34);
    expect(priceMultipleCents(33, 250), 50);
  });

  test('negative stake and sub-even odds are rejected', () {
    expect(() => priceMultipleCents(-1, 200), throwsArgumentError);
    expect(() => priceMultipleCents(100, 99), throwsArgumentError);
  });
}
