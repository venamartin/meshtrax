import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/services/repeater_command_service.dart';

/// Values produced by the connector's physics bound
/// `500 + (airtime*6 + 250) * (hops+1)` on the bench radios (SF7, 62.5 kHz,
/// max-size frame -> airtime 564 ms). The direct and flood figures were read
/// straight off the hardware; the rest follow from the same formula.
const int _direct = 4134; // 0 hops
const int _oneHop = 7768;
const int _threeHop = 15036;
const int _flood = 9524;

void main() {
  group('CLI attempt timeouts', () {
    test('the first attempt scales with the path, not a flat constant', () {
      // The bug this replaced: a flat 3 s first attempt expired on nearly
      // every 3-hop command and put a duplicate on the mesh before the real
      // reply could arrive.
      final direct = RepeaterCommandService.attemptTimeoutMs(_direct, 0, 3);
      final oneHop = RepeaterCommandService.attemptTimeoutMs(_oneHop, 0, 3);
      final threeHop =
          RepeaterCommandService.attemptTimeoutMs(_threeHop, 0, 3);

      expect(oneHop, greaterThan(direct));
      expect(threeHop, greaterThan(oneHop));
      expect(threeHop, greaterThanOrEqualTo(_threeHop),
          reason: 'a 3-hop first attempt must cover the full one-way bound');
    });

    test('never drops below the firmware reply delay floor', () {
      // The repeater waits 600 ms before it transmits at all, so a tiny
      // budget cannot succeed on any path.
      expect(RepeaterCommandService.attemptTimeoutMs(100, 0, 3),
          RepeaterCommandService.minAttemptTimeoutMs);
    });

    test('later attempts widen', () {
      final first = RepeaterCommandService.attemptTimeoutMs(_direct, 0, 4);
      final second = RepeaterCommandService.attemptTimeoutMs(_direct, 1, 4);
      final third = RepeaterCommandService.attemptTimeoutMs(_direct, 2, 4);
      expect(second, greaterThan(first));
      expect(third, greaterThanOrEqualTo(second));
    });

    test('the final attempt keeps the full conservative budget', () {
      for (final base in [_direct, _oneHop, _threeHop, _flood]) {
        expect(RepeaterCommandService.attemptTimeoutMs(base, 2, 3), base * 3,
            reason: 'base=$base');
      }
    });

    test('a single attempt gets the full budget, never a short one', () {
      // retries: 1 means there is no second chance, so it must not be cut
      // short — this is the CLI screen's one-shot path.
      expect(
          RepeaterCommandService.attemptTimeoutMs(_direct, 0, 1), _direct * 3);
    });

    test('the 8 s floor still applies to the last attempt on a fast path', () {
      expect(RepeaterCommandService.attemptTimeoutMs(100, 0, 1), 8000);
    });

    test('no attempt ever waits longer than the old policy did', () {
      // The change may only make the app give up EARLIER on early attempts.
      for (final base in [100, 1000, _direct, _oneHop, _threeHop, _flood]) {
        final old = base * 3 < 8000 ? 8000 : base * 3;
        for (var count = 1; count <= 5; count++) {
          for (var attempt = 0; attempt < count; attempt++) {
            expect(
              RepeaterCommandService.attemptTimeoutMs(base, attempt, count),
              lessThanOrEqualTo(old),
              reason: 'base=$base attempt=$attempt of $count',
            );
          }
        }
      }
    });

    test('the common case — one lost packet, then success — collapses', () {
      // What the user actually experiences: ~5% of commands get no reply and
      // the retry succeeds, so the cost is the FIRST attempt's timeout.
      for (final base in [_direct, _oneHop, _threeHop, _flood]) {
        final old = base * 3;
        final now = RepeaterCommandService.attemptTimeoutMs(base, 0, 3);
        expect(now, lessThan(old),
            reason: 'base=$base: one dropped packet used to cost ${old}ms');
      }
    });
  });
}
