import 'package:flutter/material.dart';
import 'package:tickrail/data/desk_store.dart';
import 'package:tickrail/domain/tape.dart';
import 'package:tickrail/paint/desk_colors.dart';
import 'package:tickrail/ui/market_page.dart';

class TickrailApp extends StatefulWidget {
  const TickrailApp({super.key, this.store, this.tape});

  final DeskStore? store;
  final Tape? tape;

  @override
  State<TickrailApp> createState() => _TickrailAppState();
}

class _TickrailAppState extends State<TickrailApp> {
  late final DeskStore _store = widget.store ?? DeskStore();
  late final Tape _tape = widget.tape ?? buildDemoTape();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'tickrail',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: DeskColors.ink,
        colorScheme: const ColorScheme.dark(
          primary: DeskColors.brass,
          onPrimary: Color(0xFF1A1408),
          surface: DeskColors.panel,
          onSurface: DeskColors.paper,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: DeskColors.panel,
          foregroundColor: DeskColors.paper,
          elevation: 0,
        ),
      ),
      home: MarketPage(store: _store, tape: _tape),
    );
  }
}
