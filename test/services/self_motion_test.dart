import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/services/self_motion.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Martin, 2026-11-26: My location can also send which way and how fast
// the radio is going, from the GPS readings the app already takes (every
// 60 s), kept in memory only.
class _Radio extends MeshCoreConnector {
  bool fresh = true;
  @override
  bool get selfGpsIsFresh => fresh;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Radio radio;
  late DateTime now;
  final motion = SelfMotion.instance;
  const minute = Duration(minutes: 1);
  const lat0 = 36.6, lon0 = -121.8;

  /// 50 km/h north: 833 m between readings a minute apart.
  const north = 833 / 111320;

  /// 40 m west, a walk between readings a minute apart.
  final west = 40 / (111320 * cos(lat0 * pi / 180));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    radio = _Radio();
    now = DateTime(2026, 11, 26, 9);
    motion.attach(radio, clock: () => now);
  });

  Future<void> reading(
    double lat,
    double lon, {
    Duration after = Duration.zero,
  }) async {
    now = now.add(after);
    radio.selfGps.value = (latitude: lat, longitude: lon, altitude: 35, at: now);
    await pumpEventQueue();
  }

  double offNorth(double heading) => min(heading, 360 - heading);

  test('right after connecting: not known', () async {
    await reading(lat0, lon0);
    expect(motion.motion(), isNull);
  });

  test('driving: which way and how fast from readings a minute apart',
      () async {
    await reading(lat0, lon0);
    await reading(lat0 + north, lon0, after: minute);
    final m = motion.motion()!;
    expect(offNorth(m.heading!), lessThan(1));
    expect(m.speed! * 3.6, closeTo(50, 1));
    expect(m.stillFor, isNull);
  });

  test('walking west: once it has gone 50 m', () async {
    await reading(lat0, lon0);
    await reading(lat0, lon0 - west, after: minute);
    expect(motion.motion(), isNull, reason: '40 m is too short to tell');
    await reading(lat0, lon0 - 2 * west, after: minute);
    final m = motion.motion()!;
    expect(m.heading, closeTo(270, 1));
    expect(m.speed, closeTo(80 / 120, 0.02));
  });

  test('standing still for 2 minutes: not moving, jitter and all', () async {
    await reading(lat0, lon0);
    await reading(lat0 + 15 / 111320, lon0, after: minute);
    await reading(lat0 - 10 / 111320, lon0, after: minute);
    expect(motion.motion()?.stillFor, isNull, reason: 'not 2 minutes yet');
    await reading(lat0, lon0, after: const Duration(seconds: 30));
    final m = motion.motion()!;
    expect(m.stillFor, greaterThan(const Duration(minutes: 2)));
    expect(m.heading, isNull);
    expect(m.speed, isNull);
  });

  test('readings that stopped: not known', () async {
    await reading(lat0, lon0);
    await reading(lat0 + north, lon0, after: minute);
    now = now.add(const Duration(minutes: 4));
    expect(motion.motion(), isNull);
  });

  test('a jump is not a drive', () async {
    await reading(lat0, lon0);
    await reading(lat0 + 0.1, lon0, after: minute);
    expect(motion.motion(), isNull, reason: '11 km in a minute');
  });

  test('a reading that may be old is left out', () async {
    radio.fresh = false;
    await reading(lat0, lon0);
    await reading(lat0 + north, lon0, after: minute);
    expect(motion.motion(), isNull);
  });

  // Martin, 2026-11-26: the map shows your speed, heading and altitude in
  // its lower left while it keeps you in the middle; the radio is read
  // every 3 s meanwhile.
  group('as it goes, for the speed card', () {
    const every = Duration(seconds: 3);

    /// 72 km/h north: 60 m between readings 3 s apart.
    const step = 60 / 111320;

    Future<void> drive() async {
      for (var i = 0; i < 6; i++) {
        await reading(lat0 + i * step, lon0, after: every);
      }
    }

    test('driving: steady, from readings in 11 m steps', () async {
      // The radio's 0.0001°.
      double cell(double v) => (v * 1e4).round() / 1e4;
      for (var i = 0; i < 20; i++) {
        await reading(cell(lat0 + i * step), lon0, after: every);
        if (i < 4) continue;
        final m = motion.motionNow()!;
        expect(m.speed, closeTo(20, 1), reason: 'reading $i');
        expect(offNorth(m.heading!), lessThan(1));
      }
    });

    test('stopping: not moving after 10 s', () async {
      await drive();
      final stop = lat0 + 5 * step;
      for (var i = 0; i < 3; i++) {
        await reading(stop, lon0, after: every);
        expect(motion.motionNow()!.speed, closeTo(20, 0.1));
      }
      await reading(stop, lon0, after: every);
      final m = motion.motionNow()!;
      expect(m.stillFor, const Duration(seconds: 12));
      expect((m.heading, m.speed), (null, null));
      expect(
        motion.motion()!.speed,
        closeTo(20, 0.1),
        reason: "a shared location keeps TRAX's 2 minutes",
      );
    });

    test('setting off again: measured from where it set off', () async {
      await drive();
      final stop = lat0 + 5 * step;
      await reading(stop, lon0, after: minute);
      expect(motion.motionNow()!.stillFor, isNotNull);
      // 36 km/h: 30 m between readings.
      const slow = 30 / 111320;
      await reading(stop + slow, lon0, after: every);
      expect(motion.motionNow(), isNull, reason: '30 m is too short to tell');
      await reading(stop + 2 * slow, lon0, after: every);
      expect(motion.motionNow(), isNull);
      await reading(stop + 3 * slow, lon0, after: every);
      expect(motion.motionNow()!.speed, closeTo(10, 0.1));
    });

    test('walking at 1.4 m/s: not moving only after 54 s', () async {
      // West; three times as long as 25 m takes.
      final pace = 4.2 / (111320 * cos(lat0 * pi / 180));
      for (var i = 0; i <= 36; i++) {
        await reading(lat0, lon0 - i * pace, after: every);
      }
      final stop = lon0 - 36 * pace;
      for (var i = 0; i < 16; i++) {
        await reading(lat0, stop, after: every);
      }
      final m = motion.motionNow()!;
      expect(m.speed, closeTo(1.4, 0.02), reason: '48 s');
      expect(m.heading, closeTo(270, 1));
      await reading(lat0, stop, after: every);
      await reading(lat0, stop, after: every);
      await reading(lat0, stop, after: every);
      expect(motion.motionNow()!.stillFor, const Duration(seconds: 57));
    });
  });
}
