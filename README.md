# tickrail

Live exchange prices painted on a Flutter render rail.

A market that ticks twenty times a second should not walk the element tree.
tickrail reserves layout, holds slot geometry, and writes the tape onto a
RenderBox. Page chrome stays regular widgets. The hot path only marks paint.

Betfair-accurate tick steps, integer-cent liability, and a replayable tape
so the ladder can be tested without a clock.

## Desk

![Ladder while the tape steps](docs/desk.gif)

After `flutter run` you get a market list. Add, rename or delete a market,
then open it. The ladder is one paint: back in blue, lay in pink, odds in
brass. Tap a price, set a stake in pounds, and place, amend or cancel the
order. Liability is integer cents. Step or play walks a fixed tape, which is
the same sequence this capture and the tests drive.

## Run

```
flutter pub get
flutter run
flutter test
```

Web: `flutter run -d chrome` or `flutter build web`.

The device walk-through lives in `integration_test/desk_flow_test.dart`.

## License

MIT
