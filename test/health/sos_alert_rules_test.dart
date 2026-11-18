import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/health/health_check.dart';
import 'package:meshtrax/health/health_rules.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// Martin's field review, 2026-11-18, before desert trips: the health check
// says when an SOS at night would not wake this phone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final radio = MeshCoreConnector();
  late AppSettingsService settings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    settings = AppSettingsService();
  });

  HealthRule rule(String id) => healthRules.firstWhere((r) => r.id == id);

  group('SOS alerts through Do Not Disturb', () {
    final dnd = rule('app_sos_dnd');
    HealthContext phone(SosAlertState state) =>
        HealthContext(radio, settings, sosAlertState: () async => state);

    test(
      'flags an SOS that Do Not Disturb silences, or one turned off',
      () async {
        expect(await dnd.check(phone(SosAlertState.silencedByDnd)), isTrue);
        expect(await dnd.check(phone(SosAlertState.blocked)), isTrue);
        expect(await dnd.check(phone(SosAlertState.throughDnd)), isFalse);
      },
    );

    test('passes where it cannot be known: iPhones and computers', () async {
      expect(await dnd.check(phone(SosAlertState.unknown)), isFalse);
    });

    test('leaves notifications off in the app to their own rule', () async {
      await settings.setNotificationsEnabled(false);
      expect(await dnd.check(phone(SosAlertState.silencedByDnd)), isFalse);
    });

    test('is a problem, and Fix opens the SOS alerts settings', () {
      expect(dnd.severity, HealthSeverity.problem);
      expect(dnd.fix, HealthFix.ask);
      expect(dnd.dialog, HealthDialog.sosSettings);
    });
  });

  group('alarm volume', () {
    final alarm = rule('app_sos_alarm_volume');
    HealthContext phone(({int volume, int max})? volume) =>
        HealthContext(radio, settings, alarmVolume: () async => volume);

    test('flags it off, or under a third of its most', () async {
      for (final (volume, max, flagged) in [
        (0, 7, true),
        (2, 7, true),
        (3, 7, false),
        (7, 7, false),
        (4, 15, true),
        (5, 15, false),
      ]) {
        expect(
          await alarm.check(phone((volume: volume, max: max))),
          flagged,
          reason: '$volume of $max',
        );
      }
    });

    test('passes where it cannot be known: iPhones and computers', () async {
      expect(await alarm.check(phone(null)), isFalse);
    });

    test('leaves notifications off in the app to their own rule', () async {
      await settings.setNotificationsEnabled(false);
      expect(await alarm.check(phone((volume: 0, max: 7))), isFalse);
    });

    test('Fix opens the sound settings', () {
      expect(alarm.fix, HealthFix.ask);
      expect(alarm.dialog, HealthDialog.soundSettings);
    });
  });

  test('both look at the phone alone, with no radio connected', () async {
    final report = await runHealthCheck(
      HealthContext(
        radio,
        settings,
        sosAlertState: () async => SosAlertState.silencedByDnd,
        alarmVolume: () async => (volume: 0, max: 7),
      ),
      rules: [rule('app_sos_alarm_volume'), rule('app_sos_dnd')],
    );
    expect(report.radioSkipped, isTrue);
    expect(report.findings.map((r) => r.id), [
      'app_sos_dnd',
      'app_sos_alarm_volume',
    ], reason: 'the problem first');
  });
}
