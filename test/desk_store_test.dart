import 'package:flutter_test/flutter_test.dart';
import 'package:tickrail/data/desk_store.dart';
import 'package:tickrail/domain/odds.dart';
import 'package:tickrail/domain/side.dart';

void main() {
  test('samples are the two desk markets', () {
    final store = DeskStore();
    expect(store.markets().map((market) => market.id), ['m1', 'm2']);
  });

  test('markets can be added, renamed and removed', () {
    final store = DeskStore.empty();
    final added = store.addMarket(name: ' Match Odds ', eventName: ' Cup ');
    expect(added.id, 'm1');
    expect(added.name, 'Match Odds');
    expect(added.eventName, 'Cup');
    store.renameMarket(added.id, name: 'Correct Score', eventName: 'Final');
    expect(store.findMarket(added.id)?.name, 'Correct Score');
    store.removeMarket(added.id);
    expect(store.markets(), isEmpty);
  });

  test('blank market names are refused', () {
    final store = DeskStore.empty();
    expect(
      () => store.addMarket(name: '  ', eventName: 'Cup'),
      throwsArgumentError,
    );
    expect(store.markets(), isEmpty);
  });

  test('orders round-trip per price and side', () {
    final store = DeskStore.empty();
    final market = store.addMarket(name: 'Match Odds', eventName: 'Cup');
    final odds = Odds.byHundredths(200);
    final placed = store.place(
      marketId: market.id,
      side: Side.back,
      oddsIndex: odds.index,
      stakeCents: 1000,
    );
    final again = store.place(
      marketId: market.id,
      side: Side.back,
      oddsIndex: odds.index,
      stakeCents: 2500,
    );
    expect(again.id, placed.id);
    expect(store.ordersFor(market.id), hasLength(1));
    expect(store.ordersFor(market.id).single.stakeCents, 2500);
    store.amend(placed.id, 500);
    expect(store.ordersFor(market.id).single.stakeCents, 500);
    store.cancel(placed.id);
    expect(store.ordersFor(market.id), isEmpty);
  });

  test('liability is the sum of back stake and lay risk', () {
    final store = DeskStore.empty();
    final market = store.addMarket(name: 'Match Odds', eventName: 'Cup');
    final odds = Odds.byHundredths(250);
    store.place(
      marketId: market.id,
      side: Side.back,
      oddsIndex: odds.index,
      stakeCents: 1000,
    );
    store.place(
      marketId: market.id,
      side: Side.lay,
      oddsIndex: odds.index,
      stakeCents: 1000,
    );
    expect(store.liabilityCents(market.id), 1000 + 1500);
  });

  test('removing a market drops its orders', () {
    final store = DeskStore.empty();
    final market = store.addMarket(name: 'Match Odds', eventName: 'Cup');
    store.place(
      marketId: market.id,
      side: Side.lay,
      oddsIndex: Odds.byHundredths(200).index,
      stakeCents: 200,
    );
    store.removeMarket(market.id);
    expect(store.ordersFor(market.id), isEmpty);
  });

  test('missing ids and bad stakes are refused', () {
    final store = DeskStore.empty();
    expect(() => store.removeMarket('missing'), throwsArgumentError);
    expect(() => store.cancel('missing'), throwsArgumentError);
    expect(() => store.amend('missing', 100), throwsArgumentError);
    final market = store.addMarket(name: 'Match Odds', eventName: 'Cup');
    expect(
      () => store.place(
        marketId: market.id,
        side: Side.back,
        oddsIndex: 0,
        stakeCents: 0,
      ),
      throwsArgumentError,
    );
  });
}
