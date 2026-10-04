import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/timeout_helper.dart';

/// Bench radio reference point: SF7 / 62.5 kHz / max-size frame
/// -> airtime 564 ms. All expectations below follow from the formulas at
/// that airtime so a constant change shows up as a value change here.
const int _airtime = 564;

void main() {
  group('sendLegMs (firmware send bound)', () {
    test('matches the firmware formula the connector used inline', () {
      // 500 + (airtime*6 + 250) * (hops+1)
      expect(TimeoutHelper.sendLegMs(_airtime, 0), 4134);
      expect(TimeoutHelper.sendLegMs(_airtime, 1), 7768);
      expect(TimeoutHelper.sendLegMs(_airtime, 3), 15036);
    });
  });

  group('roundTripMs (realistic one-shot budget)', () {
    test('two transit legs + reply delay + one CAD stall', () {
      // 2*(hops+1)*(airtime+250) + 600 + 4000
      expect(TimeoutHelper.roundTripMs(_airtime, 0), 6228);
      expect(TimeoutHelper.roundTripMs(_airtime, 1), 7856);
      expect(TimeoutHelper.roundTripMs(_airtime, 2), 9484);
      expect(TimeoutHelper.roundTripMs(_airtime, 4), 12740);
    });

    test('sits well under the tripled send bound it replaced', () {
      // The ~24 s CLI wait at one hop was sendLegMs * 3.
      for (var hops = 0; hops <= 8; hops++) {
        expect(
          TimeoutHelper.roundTripMs(_airtime, hops),
          lessThan(TimeoutHelper.sendLegMs(_airtime, hops) * 3),
          reason: 'hops=$hops',
        );
      }
    });
  });

  group('attemptMs', () {
    test('single attempt: base untripled, floored, capped', () {
      expect(TimeoutHelper.attemptMs(9484, 0, 1), 9484);
      expect(TimeoutHelper.attemptMs(100, 0, 1), TimeoutHelper.minAttemptMs);
      expect(TimeoutHelper.attemptMs(90000, 0, 1), TimeoutHelper.maxMs);
    });

    test('ladder: scales, final rung generous but capped at 60 s', () {
      expect(TimeoutHelper.attemptMs(9484, 0, 3), 9484);
      expect(TimeoutHelper.attemptMs(9484, 1, 3), 18968);
      expect(TimeoutHelper.attemptMs(9484, 2, 3), 28452);
      expect(TimeoutHelper.attemptMs(60000, 2, 3), TimeoutHelper.maxMs);
    });
  });
}
