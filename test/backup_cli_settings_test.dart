import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/device_backup.dart';
import 'package:meshtrax/utils/restore_settings.dart';

// Firmware 1.18 has settings with CLI keys only (txdelay, cad, WiFi, ...).
// A backup keeps them as `get` printed them; a restore replays them with
// `set`, but only keys on the allowlist, and never the WiFi password.
DeviceBackup _backup({
  int verCode = 14,
  Map<String, String> cli = const {},
}) =>
    DeviceBackup(
      firmwareVersion: verCode >= 14 ? 'v1.18.0' : 'v1.17.1',
      firmwareVerCode: verCode,
      publicKeyHex: 'aa' * 32,
      name: 'Bench Radio',
      cliSettings: cli,
    );

const _saved = {
  'txdelay': '0.5',
  'direct.txdelay': '0.2',
  'cad': 'off',
  'int.thresh': '0',
  'agc.reset.interval': '0',
  'radio.rxgain': 'on',
  'tz.offset': '-4',
  'wifi.ssid': 'Home Net',
  'wifi.enabled': '1',
};

void main() {
  group('backup file', () {
    test('round-trips the CLI settings', () {
      final json = _backup(cli: _saved).toJson();
      final back = DeviceBackup.fromJson(json);

      expect(json['cli'], _saved);
      expect(back.cliSettings, _saved);
    });

    test('only allowlisted keys survive loading, so never the password', () {
      final json = _backup(cli: _saved).toJson();
      json['cli'] = {
        ...(json['cli'] as Map<String, String>),
        'wifi.pwd': 'hunter22',
        'name': 'Pwned',
        'radio': '869.5,250,11,5',
      };

      final back = DeviceBackup.fromJson(json);

      expect(back.cliSettings.keys, unorderedEquals(_saved.keys));
    });

    test('a pre-1.18 radio never had them', () {
      final json = _backup(verCode: 13, cli: _saved).toJson();

      expect(DeviceBackup.fromJson(json).cliSettings, isEmpty);
    });

    test('a 1.18 backup without them says so; an older one does not', () {
      expect(_backup().notSaved, contains('command-line settings'));
      expect(_backup(verCode: 13).notSaved,
          isNot(contains('command-line settings')));
    });
  });

  group('restore plan', () {
    ({List<String> commands, List<String> notes}) plan(
      DeviceBackup backup, {
      int targetVerCode = 14,
      bool targetHasWifi = true,
    }) =>
        planRestoreCliSettings(
          backup,
          targetVerCode: targetVerCode,
          targetVersion: targetVerCode >= 14 ? 'v1.18.0' : 'v1.17.1',
          targetHasWifi: targetHasWifi,
        );

    test('replays every setting, network name before WiFi on', () {
      final p = plan(_backup(cli: _saved));

      expect(p.commands, [
        'set txdelay 0.5',
        'set direct.txdelay 0.2',
        'set cad off',
        'set int.thresh 0',
        'set agc.reset.interval 0',
        'set radio.rxgain on',
        'set tz.offset -4',
        'set wifi.ssid Home Net',
        'set wifi.enabled 1',
      ]);
      expect(p.notes.single, startsWith('WiFi password'));
    });

    test('a radio without WiFi gets the rest and a note', () {
      final p = plan(_backup(cli: _saved), targetHasWifi: false);

      expect(p.commands.where((c) => c.contains('wifi')), isEmpty);
      expect(p.commands, hasLength(7));
      expect(p.notes, ['WiFi (this radio has no WiFi)']);
    });

    test('an older radio gets nothing and a note', () {
      final p = plan(_backup(cli: _saved), targetVerCode: 13);

      expect(p.commands, isEmpty);
      expect(p.notes.single, startsWith('Command-line settings'));
    });

    test('a backup without them plans nothing', () {
      final p = plan(_backup());

      expect(p.commands, isEmpty);
      expect(p.notes, isEmpty);
    });
  });
}
