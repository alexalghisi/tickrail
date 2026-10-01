import 'package:tickrail/domain/market.dart';
import 'package:tickrail/domain/odds.dart';
import 'package:tickrail/domain/order.dart';
import 'package:tickrail/domain/side.dart';

class DeskStore {
  DeskStore({List<Market>? markets, List<Order>? orders}) {
    _markets.addAll(markets ?? _samples);
    _orders.addAll(orders ?? const <Order>[]);
    _marketSeq = _maxSeq(_markets.map((market) => market.id), 'm');
    _orderSeq = _maxSeq(_orders.map((order) => order.id), 'o');
  }

  factory DeskStore.empty() => DeskStore(markets: const <Market>[]);

  static const List<Market> _samples = <Market>[
    Market(id: 'm1', name: 'Match Odds', eventName: 'Arsenal v Chelsea'),
    Market(id: 'm2', name: 'Set 1 Winner', eventName: 'Swiatek v Gauff'),
  ];

  final List<Market> _markets = <Market>[];
  final List<Order> _orders = <Order>[];
  int _marketSeq = 0;
  int _orderSeq = 0;

  List<Market> markets() => List<Market>.unmodifiable(_markets);

  Market? findMarket(String id) {
    for (final market in _markets) {
      if (market.id == id) return market;
    }
    return null;
  }

  List<Order> ordersFor(String marketId) {
    return List<Order>.unmodifiable(
      _orders.where((order) => order.marketId == marketId),
    );
  }

  Market addMarket({required String name, required String eventName}) {
    final cleanName = name.trim();
    final cleanEvent = eventName.trim();
    if (cleanName.isEmpty || cleanEvent.isEmpty) {
      throw ArgumentError('name and event are required');
    }
    _marketSeq += 1;
    final market = Market(
      id: 'm$_marketSeq',
      name: cleanName,
      eventName: cleanEvent,
    );
    _markets.add(market);
    return market;
  }

  void renameMarket(
    String id, {
    required String name,
    required String eventName,
  }) {
    final cleanName = name.trim();
    final cleanEvent = eventName.trim();
    if (cleanName.isEmpty || cleanEvent.isEmpty) {
      throw ArgumentError('name and event are required');
    }
    final index = _markets.indexWhere((market) => market.id == id);
    if (index < 0) throw ArgumentError.value(id, 'id');
    _markets[index] = _markets[index].renamed(
      name: cleanName,
      eventName: cleanEvent,
    );
  }

  void removeMarket(String id) {
    final before = _markets.length;
    _markets.removeWhere((market) => market.id == id);
    if (_markets.length == before) throw ArgumentError.value(id, 'id');
    _orders.removeWhere((order) => order.marketId == id);
  }

  Order place({
    required String marketId,
    required Side side,
    required int oddsIndex,
    required int stakeCents,
  }) {
    if (stakeCents <= 0) {
      throw ArgumentError.value(stakeCents, 'stakeCents');
    }
    if (oddsIndex < 0 || oddsIndex >= Odds.ladder.length) {
      throw ArgumentError.value(oddsIndex, 'oddsIndex');
    }
    if (findMarket(marketId) == null) {
      throw ArgumentError.value(marketId, 'marketId');
    }
    final existing = _orders.indexWhere(
      (order) =>
          order.marketId == marketId &&
          order.oddsIndex == oddsIndex &&
          order.side == side,
    );
    if (existing >= 0) {
      final next = _orders[existing].withStake(stakeCents);
      _orders[existing] = next;
      return next;
    }
    _orderSeq += 1;
    final order = Order(
      id: 'o$_orderSeq',
      marketId: marketId,
      side: side,
      oddsIndex: oddsIndex,
      stakeCents: stakeCents,
    );
    _orders.add(order);
    return order;
  }

  void amend(String id, int stakeCents) {
    if (stakeCents <= 0) {
      throw ArgumentError.value(stakeCents, 'stakeCents');
    }
    final index = _orders.indexWhere((order) => order.id == id);
    if (index < 0) throw ArgumentError.value(id, 'id');
    _orders[index] = _orders[index].withStake(stakeCents);
  }

  void cancel(String id) {
    final before = _orders.length;
    _orders.removeWhere((order) => order.id == id);
    if (_orders.length == before) throw ArgumentError.value(id, 'id');
  }

  int liabilityCents(String marketId) {
    var total = 0;
    for (final order in _orders) {
      if (order.marketId != marketId) continue;
      total += order.riskCents(Odds.at(order.oddsIndex).hundredths);
    }
    return total;
  }
}

int _maxSeq(Iterable<String> ids, String prefix) {
  var max = 0;
  for (final id in ids) {
    if (!id.startsWith(prefix)) continue;
    final parsed = int.tryParse(id.substring(prefix.length));
    if (parsed != null && parsed > max) max = parsed;
  }
  return max;
}
