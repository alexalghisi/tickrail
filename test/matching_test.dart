import 'package:flutter_test/flutter_test.dart';
import 'package:tickrail/data/desk_store.dart';
import 'package:tickrail/domain/odds.dart';
import 'package:tickrail/domain/order.dart';
import 'package:tickrail/domain/side.dart';
import 'package:tickrail/domain/tape.dart';

final int _price = Odds.byHundredths(200).index;

TapeFrame _frame({int back = 0, int lay = 0, int? oddsIndex}) {
  return TapeFrame(
    seq: 0,
    quotes: [
      Quote(oddsIndex: oddsIndex ?? _price, backCents: back, layCents: lay),
    ],
  );
}

Order _place(DeskStore store, Side side, int stakeCents) {
  return store.place(
    marketId: 'm1',
    side: side,
    oddsIndex: _price,
    stakeCents: stakeCents,
  );
}

void main() {
  test('a new order rests unmatched', () {
    final store = DeskStore();
    final order = _place(store, Side.back, 1000);
    expect(order.matchedCents, 0);
    expect(order.remainingCents, 1000);
    expect(store.positionFor('m1').isFlat, isTrue);
  });

  test('a back fills against the back size at its price', () {
    final store = DeskStore();
    _place(store, Side.back, 1000);
    expect(store.match('m1', _frame(back: 5000)), isTrue);
    final order = store.ordersFor('m1').single;
    expect(order.matchedCents, 1000);
    expect(order.remainingCents, 0);
  });

  test('a lay fills against the lay size, not the back size', () {
    final store = DeskStore();
    _place(store, Side.lay, 1000);
    expect(store.match('m1', _frame(back: 5000)), isFalse);
    expect(store.match('m1', _frame(lay: 5000)), isTrue);
    expect(store.ordersFor('m1').single.matchedCents, 1000);
  });

  test('thin size fills an order across several frames', () {
    final store = DeskStore();
    _place(store, Side.back, 1000);
    store.match('m1', _frame(back: 400));
    expect(store.ordersFor('m1').single.matchedCents, 400);
    store.match('m1', _frame(back: 400));
    expect(store.ordersFor('m1').single.matchedCents, 800);
    store.match('m1', _frame(back: 400));
    expect(store.ordersFor('m1').single.matchedCents, 1000);
    expect(store.match('m1', _frame(back: 400)), isFalse);
  });

  test('a frame without the order price fills nothing', () {
    final store = DeskStore();
    _place(store, Side.back, 1000);
    expect(
      store.match('m1', _frame(back: 5000, oddsIndex: _price + 1)),
      isFalse,
    );
    expect(store.ordersFor('m1').single.matchedCents, 0);
  });

  test('orders in other markets are left alone', () {
    final store = DeskStore();
    _place(store, Side.back, 1000);
    expect(store.match('m2', _frame(back: 5000)), isFalse);
    expect(store.ordersFor('m1').single.matchedCents, 0);
  });

  test('the position counts matched stakes only', () {
    final store = DeskStore();
    _place(store, Side.back, 1000);
    store.match('m1', _frame(back: 400));
    final position = store.positionFor('m1');
    expect(position.winCents, 400);
    expect(position.loseCents, -400);
  });

  test('liability is resting risk plus the worst matched outcome', () {
    final store = DeskStore();
    _place(store, Side.back, 1000);
    expect(store.liabilityCents('m1'), 1000);
    store.match('m1', _frame(back: 400));
    expect(store.liabilityCents('m1'), 1000);
    store.match('m1', _frame(back: 600));
    expect(store.liabilityCents('m1'), 1000);
  });

  test('a hedged position carries no liability', () {
    final store = DeskStore();
    _place(store, Side.back, 1000);
    store.match('m1', _frame(back: 5000));
    _place(store, Side.lay, 1000);
    expect(store.liabilityCents('m1'), 2000);
    store.match('m1', _frame(lay: 5000));
    expect(store.liabilityCents('m1'), 0);
  });

  test('cancelling a part matched order keeps the matched bet', () {
    final store = DeskStore();
    final order = _place(store, Side.back, 1000);
    store.match('m1', _frame(back: 400));
    store.cancel(order.id);
    final kept = store.ordersFor('m1').single;
    expect(kept.stakeCents, 400);
    expect(kept.remainingCents, 0);
    expect(store.positionFor('m1').loseCents, -400);
  });

  test('a stake cannot be amended below what is matched', () {
    final store = DeskStore();
    final order = _place(store, Side.back, 1000);
    store.match('m1', _frame(back: 400));
    expect(() => store.amend(order.id, 399), throwsArgumentError);
    store.amend(order.id, 400);
    expect(store.ordersFor('m1').single.remainingCents, 0);
  });

  test('placing again at a price sets the unmatched part', () {
    final store = DeskStore();
    _place(store, Side.back, 1000);
    store.match('m1', _frame(back: 400));
    final next = _place(store, Side.back, 250);
    expect(next.id, 'o1');
    expect(next.stakeCents, 650);
    expect(next.remainingCents, 250);
  });

  test('a fully matched order is not reopened by a new one', () {
    final store = DeskStore();
    _place(store, Side.back, 1000);
    store.match('m1', _frame(back: 5000));
    final next = _place(store, Side.back, 500);
    expect(next.id, 'o2');
    expect(store.ordersFor('m1'), hasLength(2));
  });
}
