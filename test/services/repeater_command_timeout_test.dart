import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/services/repeater_command_service.dart';

/// Measured on the bench against repeater F857 over a direct link: the
/// connector's physics bound came out at 4134 ms (direct) and 9524 ms
/// (flood), while the actual round trip was 954-1009 ms across 100+ samples.
const int _directBase = 4134;
const int _floodBase = 9524;

void main() {
  group('CLI attempt timeouts escalate', () {
    test('the first attempt is sized for a link that is working', () {
      expect(
        RepeaterCommandService.attemptTimeoutMs(_directBase, 0, 3),
        RepeaterCommandService.firstAttemptTimeoutMs,
      );
      // The old policy — max(8000, base*3) on every attempt — is what made a
      // single lost packet cost 12.4 s on a link that answers in 1 s.
      expect(RepeaterCommandService.attemptTimeoutMs(_directBase, 0, 3),
          lessThan(_directBase * 3));
    });

    test('later attempts widen', () {
      final first = RepeaterCommandService.attemptTimeoutMs(_directBase, 0, 4);
      final second = RepeaterCommandService.attemptTimeoutMs(_directBase, 1, 4);
      final third = RepeaterCommandService.attemptTimeoutMs(_directBase, 2, 4);
      expect(second, greaterThan(first));
      expect(third, greaterThan(second));
    });

    test('the final attempt keeps the full conservative budget', () {
      // A genuinely slow multi-hop path must still complete; it just is not
      // the first thing the user waits for.
      expect(RepeaterCommandService.attemptTimeoutMs(_floodBase, 2, 3),
          _floodBase * 3);
      expect(RepeaterCommandService.attemptTimeoutMs(_directBase, 2, 3),
          _directBase * 3);
    });

    test('a single attempt gets the full budget, never the short one', () {
      // retries: 1 means there is no second chance, so it must not be cut
      // short — this is the CLI screen's one-shot path.
      expect(RepeaterCommandService.attemptTimeoutMs(_directBase, 0, 1),
          _directBase * 3);
    });

    test('the 8 s floor still applies to the last attempt on a fast path', () {
      expect(RepeaterCommandService.attemptTimeoutMs(100, 0, 1), 8000);
    });

    test('no attempt ever exceeds the old give-up point', () {
      // The change may only make the app give up EARLIER on early attempts,
      // never later than it used to on any of them.
      for (final base in [100, 1000, _directBase, _floodBase]) {
        final ceiling = base * 3 < 8000 ? 8000 : base * 3;
        for (var count = 1; count <= 5; count++) {
          for (var attempt = 0; attempt < count; attempt++) {
            expect(
              RepeaterCommandService.attemptTimeoutMs(base, attempt, count),
              lessThanOrEqualTo(ceiling),
              reason: 'base=$base attempt=$attempt of $count',
            );
          }
        }
      }
    });

    test('the common case — one lost packet, then success — collapses', () {
      // This is what the user actually experiences. About 5% of commands get
      // no reply, and the retry then succeeds in ~1 s. The cost of that is
      // the FIRST attempt's timeout, not the whole retry budget.
      final was = _directBase * 3;
      final now = RepeaterCommandService.attemptTimeoutMs(_directBase, 0, 3);
      expect(now, lessThan(was ~/ 4),
          reason: 'one dropped packet used to cost ${was}ms before the first '
              'retry, on a link measured at ~955ms');

      final wasFlood = _floodBase * 3;
      final nowFlood = RepeaterCommandService.attemptTimeoutMs(_floodBase, 0, 3);
      expect(nowFlood, lessThan(wasFlood ~/ 8));
    });

    test('worst case still improves, without capping the slow path', () {
      var total = 0;
      for (var attempt = 0; attempt < 3; attempt++) {
        total +=
            RepeaterCommandService.attemptTimeoutMs(_directBase, attempt, 3);
      }
      // Three attempts used to mean three full budgets back to back;
      // measured on hardware, one "get radio" burned 85.8 s that way.
      expect(total, lessThan((_directBase * 3) * 3));
      // But the last attempt is untouched, so a genuinely slow path still
      // gets its full conservative budget before anything is declared dead.
      expect(RepeaterCommandService.attemptTimeoutMs(_directBase, 2, 3),
          _directBase * 3);
    });
  });
}
