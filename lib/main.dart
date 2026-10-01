import 'package:flutter/material.dart';
import 'package:tickrail/data/desk_store.dart';

void main() {
  runApp(const TickrailApp());
}

class TickrailApp extends StatelessWidget {
  const TickrailApp({super.key});

  @override
  Widget build(BuildContext context) {
    final market = DeskStore().markets().first;
    return MaterialApp(
      title: 'tickrail',
      debugShowCheckedModeBanner: false,
      home: Scaffold(body: Center(child: Text(market.name))),
    );
  }
}
