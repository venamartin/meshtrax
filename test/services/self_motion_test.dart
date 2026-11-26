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
}
