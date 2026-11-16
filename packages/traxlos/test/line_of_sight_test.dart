import 'package:test/test.dart';
import 'package:traxlos/traxlos.dart';

/// Rules on known heights: no contours, so only the maths and the verdict.
void main() {
  group('earth and Fresnel zone', () {
    test('first Fresnel radius at mid-path of 10 km at 910.5 MHz', () {
      // The exact wavelength gives 28.69 m; the 550·√(d1·d2/(D·f)) rule of
      // thumb 28.82 m.
      expect(fresnelRadiusM(5000, 5000, 910.5), closeTo(28.8, 0.15));
      expect(fresnelRadiusM(0, 10000, 910.5), 0);
    });

    test('k is 4/3 whatever the frequency', () {
      expect(kFactor, 4 / 3);
      expect(earthBulgeM(5000, 5000), closeTo(1.4714, 0.001));
      final a = lineOfSightOver([0, 10000], [0, 0], frequencyMHz: 433);
      final b = lineOfSightOver([0, 10000], [0, 0], frequencyMHz: 2400);
      expect(a.bulgeAt(5000), b.bulgeAt(5000));
    });
  });

  group('smooth earth, two 1.5 m antennas', () {
    test('geometrically clear at 10.0 km, blocked at 10.2 km', () {
      final near = lineOfSightOver([0, 10000], [100, 100]);
      // Over the curve, but inside the Fresnel zone.
      expect(near.verdict, Verdict.marginal);
      expect(near.deciding!.aboveLineM, lessThan(0));
      final far = lineOfSightOver([0, 10200], [100, 100]);
      expect(far.verdict, Verdict.blocked);
      expect(far.deciding!.aboveLineM, greaterThan(0));
      expect(far.deciding!.distanceM, closeTo(5100, 100));
    });

    test('the contour interval allows for data error, not the earth curve', () {
      // Flat ground read from 20 ft contours: the curve still blocks.
      const interval = 20 * 0.3048;
      expect(
        lineOfSightOver([0, 10200], [100, 100], intervalM: interval).verdict,
        Verdict.blocked,
      );
      expect(
        lineOfSightOver([0, 10000], [100, 100], intervalM: interval).verdict,
        Verdict.marginal,
      );
    });
  });

  group('verdict levels', () {
    // 10 km over flat ground at 100 m, 30 m masts, one ridge at 5 km.
    LineOfSight ridge(double top, {double interval = 6.096}) => lineOfSightOver(
      [0, 4990, 5000, 5010, 10000],
      [100, 100, top, 100, 100],
      fromAntennaM: 30,
      toAntennaM: 30,
      frequencyMHz: 910.5,
      intervalM: interval,
    );

    test('clear with 60% of the first Fresnel zone free', () {
      final r = ridge(100);
      expect(r.verdict, Verdict.clear);
      // The tightest point is reported even when clear.
      expect(r.deciding!.aboveLineM, closeTo(-(30 - 1.471), 0.01));
      expect(r.deciding!.neededM, closeTo(0.6 * 28.69, 0.05));
    });

    test('marginal inside the Fresnel zone', () {
      final r = ridge(115);
      expect(r.verdict, Verdict.marginal);
      expect(r.deciding!.distanceM, 5000);
      expect(r.deciding!.groundM, 115);
    });

    test('marginal when the ground is above the line by less than one '
        'interval', () {
      final r = ridge(131);
      expect(r.verdict, Verdict.marginal);
      expect(r.deciding!.aboveLineM, closeTo(131 + 1.471 - 130, 0.01));
    });

    test('blocked when the ground is more than one interval above the '
        'line', () {
      final r = ridge(140);
      expect(r.verdict, Verdict.blocked);
      expect(r.deciding!.aboveLineM, closeTo(11.47, 0.01));
      expect(r.nearRadio, NearRadio.none);
      // With exact heights any ground above the line blocks.
      expect(ridge(131, interval: 0).verdict, Verdict.blocked);
    });

    test('irregular spacing is fine', () {
      final r = lineOfSightOver(
        [0, 13, 700, 2250, 2300, 6100],
        [100, 101, 120, 160, 130, 100],
        fromAntennaM: 2,
        toAntennaM: 2,
      );
      expect(r.verdict, Verdict.blocked);
      expect(r.deciding!.distanceM, 2250);
    });
  });

  group('near the radios', () {
    test('a bank more than one interval and 5 m above the line within 50 m '
        'of a radio blocks it', () {
      // A 20 m bank 30 m in front of a hand-held, a mast at the far end.
      for (final interval in [0.0, 6.096, 10.0]) {
        final r = lineOfSightOver(
          [0, 29, 30, 31, 5000],
          [100, 100, 120, 100, 100],
          fromAntennaM: 1.5,
          toAntennaM: 60,
          intervalM: interval,
        );
        expect(r.verdict, Verdict.blocked, reason: '$interval');
        expect(r.deciding!.distanceM, 30);
        expect(r.deciding!.aboveLineM, greaterThan(15));
        expect(r.nearRadio, NearRadio.from);
        // Farther out it is the hand-held's own low line that limits.
        expect(r.beyondNearGround!.distanceM, greaterThanOrEqualTo(100));
      }
      // The same at the far end.
      final far = lineOfSightOver(
        [0, 4969, 4970, 4971, 5000],
        [100, 100, 120, 100, 100],
        fromAntennaM: 60,
        toAntennaM: 1.5,
      );
      expect(far.verdict, Verdict.blocked);
      expect(far.nearRadio, NearRadio.to);
    });

    test('ground less than one interval and 5 m above the line within 50 m '
        'of a radio is marginal, never ignored', () {
      for (final (rise, interval) in [(4.0, 0.0), (9.0, 6.096), (14.0, 10.0)]) {
        final r = lineOfSightOver(
          [0, 29, 30, 31, 5000],
          [100, 100, 100 + rise, 100, 100],
          fromAntennaM: 1.5,
          toAntennaM: 60,
          intervalM: interval,
        );
        expect(r.verdict, Verdict.marginal, reason: '$rise/$interval');
        expect(r.deciding!.distanceM, 30);
        expect(r.deciding!.aboveLineM, greaterThan(0));
        expect(r.nearRadio, NearRadio.from);
      }
    });

    test('a deep valley reports its own clearance, not the antenna '
        'height', () {
      final r = lineOfSightOver([0, 60, 4940, 5000], [1000, 817, 817, 1000]);
      expect(r.verdict, Verdict.clear);
      expect(r.deciding!.aboveLineM, lessThan(-100));
      expect(r.beyondNearGround!.aboveLineM, lessThan(-180));
    });
  });

  test('the chart helpers', () {
    final r = lineOfSightOver(
      [0, 1000],
      [100, 200],
      fromAntennaM: 2,
      toAntennaM: 3,
    );
    expect(r.lineAt(0), 102);
    expect(r.lineAt(1000), 203);
    expect(r.bulgeAt(0), 0);
    expect(r.neededAt(500), closeTo(0.6 * fresnelRadiusM(500, 500, 915), 1e-9));
    expect(r.profile.groundAt(500), closeTo(150, 1e-9));
  });
}
