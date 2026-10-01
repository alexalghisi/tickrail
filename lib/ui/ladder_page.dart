import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:tickrail/data/desk_store.dart';
import 'package:tickrail/domain/money.dart';
import 'package:tickrail/domain/odds.dart';
import 'package:tickrail/domain/order.dart';
import 'package:tickrail/domain/side.dart';
import 'package:tickrail/domain/tape.dart';
import 'package:tickrail/paint/ladder_rail.dart';

class LadderPage extends StatefulWidget {
  const LadderPage({
    required this.store,
    required this.tape,
    required this.marketId,
    super.key,
  });

  final DeskStore store;
  final Tape tape;
  final String marketId;

  @override
  State<LadderPage> createState() => _LadderPageState();
}

class _LadderPageState extends State<LadderPage>
    with SingleTickerProviderStateMixin {
  final _stake = TextEditingController(text: '10.00');
  final _handle = RailHandle();
  late final Ticker _ticker = createTicker(_onTick);
  var _cursor = 0;
  var _seenFrame = 0;
  int? _selectedIndex;
  Side? _selectedSide;
  String? _error;

  @override
  void initState() {
    super.initState();
    _publish();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _stake.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final frame = elapsed.inMilliseconds ~/ 50;
    if (frame == _seenFrame) return;
    _seenFrame = frame;
    _move(1);
  }

  void _togglePlay() {
    if (_ticker.isActive) {
      _ticker.stop();
    } else {
      _seenFrame = 0;
      _ticker.start();
    }
    setState(() {});
  }

  void _move(int delta) {
    final length = widget.tape.length;
    _cursor = (_cursor + delta) % length;
    if (_cursor < 0) _cursor += length;
    _publish();
  }

  void _select(int oddsIndex, Side side) {
    setState(() {
      _selectedIndex = oddsIndex;
      _selectedSide = side;
      _error = null;
    });
    _publish();
  }

  void _place() {
    if (_selectedIndex == null || _selectedSide == null) {
      setState(() => _error = 'Pick a back or lay price.');
      return;
    }
    final stake = Stake.parse(_stake.text);
    if (stake == null) {
      setState(() => _error = 'Enter a stake in pounds.');
      return;
    }
    widget.store.place(
      marketId: widget.marketId,
      side: _selectedSide!,
      oddsIndex: _selectedIndex!,
      stakeCents: stake.cents,
    );
    _publish();
    setState(() => _error = null);
  }

  Future<void> _amend(Order order) async {
    final cents = await showDialog<int>(
      context: context,
      builder: (context) => _AmendStakeDialog(stakeCents: order.stakeCents),
    );
    if (cents != null && mounted) {
      widget.store.amend(order.id, cents);
      _publish();
      setState(() {});
    }
  }

  void _publish() {
    final frame = widget.tape[_cursor];
    final stakes = <int, CellStake>{};
    for (final order in widget.store.ordersFor(widget.marketId)) {
      final current = stakes[order.oddsIndex] ?? const CellStake();
      stakes[order.oddsIndex] = order.side == Side.back
          ? CellStake(backCents: order.stakeCents, layCents: current.layCents)
          : CellStake(backCents: current.backCents, layCents: order.stakeCents);
    }
    _handle.show(
      LadderSnapshot(
        seq: frame.seq,
        quotes: frame.quotes,
        stakes: stakes,
        selectedIndex: _selectedIndex,
        selectedSide: _selectedSide,
      ),
    );
  }

  String _exposure() {
    final stake = Stake.parse(_stake.text);
    if (stake == null || _selectedIndex == null || _selectedSide == null) {
      return 'Pick a price and a stake.';
    }
    final hundredths = Odds.at(_selectedIndex!).hundredths;
    final back = _selectedSide == Side.back;
    final risk = back
        ? stake.cents
        : priceMultipleCents(stake.cents, hundredths);
    final win = back
        ? priceMultipleCents(stake.cents, hundredths)
        : stake.cents;
    final side = back ? 'Back' : 'Lay';
    final label = Odds.at(_selectedIndex!).label;
    return '$side $label  risk ${formatCents(risk)}  win ${formatCents(win)}';
  }

  @override
  Widget build(BuildContext context) {
    final market = widget.store.findMarket(widget.marketId);
    if (market == null) {
      return const Scaffold(body: Center(child: Text('Market is gone.')));
    }
    final orders = widget.store.ordersFor(widget.marketId);
    return RepaintBoundary(
      key: const Key('ladder-boundary'),
      child: Scaffold(
        appBar: AppBar(title: Text(market.name)),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Liability ${formatCents(widget.store.liabilityCents(widget.marketId))}',
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('stake'),
                    controller: _stake,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Stake'),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  Text(_exposure()),
                  if (_error != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFE07A7A)),
                    ),
                  ],
                  Row(
                    children: [
                      IconButton(
                        key: const Key('tape-prev'),
                        tooltip: 'Previous frame',
                        onPressed: () => _move(-1),
                        icon: const Icon(Icons.skip_previous),
                      ),
                      IconButton(
                        key: const Key('tape-play'),
                        tooltip: _ticker.isActive ? 'Pause tape' : 'Play tape',
                        onPressed: _togglePlay,
                        icon: Icon(
                          _ticker.isActive ? Icons.pause : Icons.play_arrow,
                        ),
                      ),
                      IconButton(
                        key: const Key('tape-next'),
                        tooltip: 'Next frame',
                        onPressed: () => _move(1),
                        icon: const Icon(Icons.skip_next),
                      ),
                      const Spacer(),
                      FilledButton(
                        key: const Key('place-order'),
                        onPressed: _place,
                        child: const Text('Place'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: LadderRail(handle: _handle, onSelect: _select),
              ),
            ),
            SizedBox(height: 148, child: _orders(orders)),
          ],
        ),
      ),
    );
  }

  Widget _orders(List<Order> orders) {
    if (orders.isEmpty) {
      return const Center(child: Text('No open orders.'));
    }
    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final side = order.side == Side.back ? 'Back' : 'Lay';
        final label = Odds.at(order.oddsIndex).label;
        return ListTile(
          key: ValueKey(order.id),
          dense: true,
          title: Text('$side $label  ${formatCents(order.stakeCents)}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                key: Key('amend-${order.id}'),
                tooltip: 'Amend stake',
                onPressed: () => _amend(order),
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                key: Key('cancel-${order.id}'),
                tooltip: 'Cancel order',
                onPressed: () {
                  widget.store.cancel(order.id);
                  _publish();
                  setState(() {});
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AmendStakeDialog extends StatefulWidget {
  const _AmendStakeDialog({required this.stakeCents});

  final int stakeCents;

  @override
  State<_AmendStakeDialog> createState() => _AmendStakeDialogState();
}

class _AmendStakeDialogState extends State<_AmendStakeDialog> {
  late final TextEditingController _field = TextEditingController(
    text: formatCents(widget.stakeCents),
  );
  var _error = '';

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  void _save() {
    final stake = Stake.parse(_field.text);
    if (stake == null) {
      setState(() => _error = 'Enter a stake in pounds.');
      return;
    }
    Navigator.pop(context, stake.cents);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Amend stake'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            key: const Key('amend-stake'),
            controller: _field,
            decoration: const InputDecoration(labelText: 'Stake'),
          ),
          if (_error.isNotEmpty) ...[const SizedBox(height: 8), Text(_error)],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
