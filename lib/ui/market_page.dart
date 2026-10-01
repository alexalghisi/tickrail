import 'package:flutter/material.dart';
import 'package:tickrail/data/desk_store.dart';
import 'package:tickrail/domain/market.dart';
import 'package:tickrail/domain/tape.dart';
import 'package:tickrail/ui/ladder_page.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({required this.store, required this.tape, super.key});

  final DeskStore store;
  final Tape tape;

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> {
  final _name = TextEditingController();
  final _event = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _event.dispose();
    super.dispose();
  }

  void _add() {
    try {
      widget.store.addMarket(name: _name.text, eventName: _event.text);
      _name.clear();
      _event.clear();
      setState(() => _error = null);
    } on ArgumentError {
      setState(() => _error = 'Name and event are required.');
    }
  }

  Future<void> _edit(Market market) async {
    final draft = await showDialog<_MarketDraft>(
      context: context,
      builder: (context) => _EditMarketDialog(market: market),
    );
    if (draft != null && mounted) {
      widget.store.renameMarket(
        market.id,
        name: draft.name,
        eventName: draft.eventName,
      );
      setState(() => _error = null);
    }
  }

  Future<void> _open(Market market) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => LadderPage(
          store: widget.store,
          tape: widget.tape,
          marketId: market.id,
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final markets = widget.store.markets();
    return RepaintBoundary(
      key: const Key('market-boundary'),
      child: Scaffold(
        appBar: AppBar(title: const Text('tickrail')),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    key: const Key('market-name'),
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Market'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    key: const Key('event-name'),
                    controller: _event,
                    decoration: const InputDecoration(labelText: 'Event'),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      key: const Key('add-market'),
                      onPressed: _add,
                      child: const Text('Add market'),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!),
                  ],
                ],
              ),
            ),
            Expanded(
              child: markets.isEmpty
                  ? const Center(child: Text('No markets yet.'))
                  : ListView.builder(
                      itemCount: markets.length,
                      itemBuilder: (context, index) {
                        final market = markets[index];
                        final orders = widget.store.ordersFor(market.id).length;
                        return ListTile(
                          key: Key('open-${market.id}'),
                          title: Text(
                            market.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            orders == 0
                                ? market.eventName
                                : '${market.eventName} · $orders open',
                          ),
                          onTap: () => _open(market),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                key: Key('edit-${market.id}'),
                                tooltip: 'Edit market',
                                onPressed: () => _edit(market),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                key: Key('delete-${market.id}'),
                                tooltip: 'Delete market',
                                onPressed: () {
                                  widget.store.removeMarket(market.id);
                                  setState(() {});
                                },
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketDraft {
  const _MarketDraft(this.name, this.eventName);

  final String name;
  final String eventName;
}

class _EditMarketDialog extends StatefulWidget {
  const _EditMarketDialog({required this.market});

  final Market market;

  @override
  State<_EditMarketDialog> createState() => _EditMarketDialogState();
}

class _EditMarketDialogState extends State<_EditMarketDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.market.name,
  );
  late final TextEditingController _event = TextEditingController(
    text: widget.market.eventName,
  );
  var _error = '';

  @override
  void dispose() {
    _name.dispose();
    _event.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty || _event.text.trim().isEmpty) {
      setState(() => _error = 'Name and event are required.');
      return;
    }
    Navigator.pop(context, _MarketDraft(_name.text, _event.text));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit market'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              key: const Key('edit-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Market'),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const Key('edit-event'),
              controller: _event,
              decoration: const InputDecoration(labelText: 'Event'),
            ),
            if (_error.isNotEmpty) ...[const SizedBox(height: 8), Text(_error)],
          ],
        ),
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
