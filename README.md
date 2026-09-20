# tickrail

Live exchange prices painted on a Flutter render rail.

A market that ticks twenty times a second should not walk the element tree.
tickrail reserves layout, holds slot geometry, and writes the tape onto a
RenderBox. Page chrome stays regular widgets. The hot path only marks paint.

Betfair-accurate tick steps, integer-cent liability, and a replayable tape
so the ladder can be tested without a clock.

## Status

Scaffold is on `main`. Work lands on feature branches and is merged when
green.

## License

MIT
