import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/device_backup.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/backup_service.dart';
import 'package:meshtrax/utils/restore_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _contactJson(String pubKeyHex, String name) => {
  'publicKey': pubKeyHex,
  'name': name,
  'type': 1,
  'flags': 5,
  'pathLength': 2,
  'path': 'aabb',
  'pathHashSize': 1,
  'latitude': 51.5,
  'longitude': -0.1,
  'lastSeen': 1700000000000,
  'lastMessageAt': 1700000001000,
};

DeviceBackup _sampleBackup({String? privateKey}) => DeviceBackup(
  firmwareVersion: 'v1.17.1',
  firmwareVerCode: 13,
  publicKeyHex: 'aa' * 32,
  privateKeyHex: privateKey,
  name: 'Bench Radio',
  txPower: 17,
  latitude: 51.5,
  longitude: -0.1,
  freqHz: 910525000,
  bwHz: 250000,
  sf: 10,
  cr: 5,
  clientRepeat: true,
  pathHashMode: 1,
  multiAcks: 1,
  advertLocPolicy: 1,
  telemetryBase: 1,
  telemetryLoc: 2,
  telemetryEnv: 0,
  autoAddChat: true,
  autoAddRepeater: false,
  autoAddRoomServer: true,
  autoAddSensor: false,
  autoAddOverwriteOldest: true,
  autoAddMaxHops: 3,
  manualAddContacts: 1,
  hasFloodScope: true,
  floodScopeName: '#uk',
  floodScopeKeyHex: 'ef' * 16,
  tuning: BackupTuning(rxDelayBase: 2500, airtimeFactor: 1000),
  customVars: {'gps': '1', 'gps_interval': '900'},
  channels: [
    BackupChannel(index: 0, name: 'Public', pskHex: '8b' * 16),
    BackupChannel(index: 2, name: '#bench', pskHex: 'cd' * 16),
  ],
  contacts: [
    BackupContact(
      contact: Contact.fromJson(_contactJson('bb' * 32, 'Peer')),
      rawAdvert: Uint8List.fromList([1, 2, 3, 4]),
      lastAdvertTimestamp: 1700000123,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('full backup round-trip', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
    });

    test('device state survives serialize/parse', () async {
      final json = await BackupService.createBackupJson(
        _sampleBackup(privateKey: 'ab' * 64),
      );
      final parsed = BackupService.parseBackup(json);
      expect(parsed, isA<FullBackup>());
      final full = parsed as FullBackup;
      expect(full.version, 1);
      expect(full.createdAt, isNotNull);

      final d = full.device;
      expect(d.publicKeyHex, 'aa' * 32);
      expect(d.privateKeyHex, 'ab' * 64);
      expect(d.name, 'Bench Radio');
      expect(d.txPower, 17);
      expect(d.freqHz, 910525000);
      expect(d.bwHz, 250000);
      expect(d.sf, 10);
      expect(d.cr, 5);
      expect(d.clientRepeat, true);
      expect(d.pathHashMode, 1);
      expect(d.multiAcks, 1);
      expect(d.advertLocPolicy, 1);
      expect(d.telemetryBase, 1);
      expect(d.telemetryLoc, 2);
      expect(d.telemetryEnv, 0);
      expect(d.autoAddChat, true);
      expect(d.autoAddRepeater, false);
      expect(d.autoAddOverwriteOldest, true);
      expect(d.autoAddMaxHops, 3);
      expect(d.manualAddContacts, 1);
      expect(d.hasFloodScope, true);
      expect(d.floodScopeName, '#uk');
      expect(d.floodScopeKeyHex, 'ef' * 16);
      expect(d.notSaved, isEmpty);
      expect(d.tuning?.rxDelayBase, 2500);
      expect(d.tuning?.airtimeFactor, 1000);
      expect(d.customVars, {'gps': '1', 'gps_interval': '900'});

      expect(d.channels.length, 2);
      expect(d.channels[1].index, 2);
      expect(d.channels[1].name, '#bench');
      expect(d.channels[1].pskHex, 'cd' * 16);

      expect(d.contacts.length, 1);
      final bc = d.contacts.first;
      expect(bc.contact.publicKeyHex, 'bb' * 32);
      expect(bc.contact.name, 'Peer');
      expect(bc.contact.flags, 5);
      expect(bc.rawAdvert, Uint8List.fromList([1, 2, 3, 4]));
      expect(bc.lastAdvertTimestamp, 1700000123);
    });

    test('identity-less backup keeps privateKey null', () async {
      final json = await BackupService.createBackupJson(_sampleBackup());
      final parsed = BackupService.parseBackup(json) as FullBackup;
      expect(parsed.device.privateKeyHex, isNull);
    });

    test('a file from an older radio carries nulls, not defaults', () {
      final d = DeviceBackup.fromJson({
        'firmwareVersion': 'v1.11.0',
        'firmwareVerCode': 8,
        'publicKey': 'aa' * 32,
        'name': 'Old',
      });
      expect(d.pathHashMode, isNull);
      expect(d.autoAddChat, isNull);
      expect(d.telemetryBase, isNull);
      expect(d.multiAcks, isNull);
      expect(d.clientRepeat, isNull);
      expect(d.hasFloodScope, isFalse);
      expect(d.notSaved, contains('path hash size'));
    });

    test('v1 files drop values the recorded firmware could not have sent', () {
      final d = DeviceBackup.fromJson({
        'firmwareVersion': 'v1.11.0',
        'firmwareVerCode': 8,
        'publicKey': 'aa' * 32,
        'name': 'Old',
        'pathHashMode': 0,
        'multiAcks': 1,
        'radio': {'clientRepeat': false},
        'autoAdd': {'chat': false, 'repeater': false},
        'telemetry': {'base': 1, 'loc': 0, 'env': 0},
      });
      expect(d.pathHashMode, isNull);
      expect(d.clientRepeat, isNull);
      expect(d.autoAddChat, isNull);
      expect(d.multiAcks, 1);
      expect(d.telemetryBase, 1);
      // ver_code 8 covers 1.10–1.12; only 1.12 has auto-add config.
      final d112 = DeviceBackup.fromJson({
        'firmwareVersion': 'v1.12.0',
        'firmwareVerCode': 8,
        'publicKey': 'aa' * 32,
        'name': 'Old',
        'autoAdd': {'chat': false},
      });
      expect(d112.autoAddChat, false);
    });

    test('firmware matrix edge cases', () {
      expect(firmwareSupports(RadioSetting.multiAcks, 7, 'v1.7.3'), isFalse);
      expect(firmwareSupports(RadioSetting.multiAcks, 7, 'v1.7.4'), isTrue);
      expect(firmwareSupports(RadioSetting.autoAdd, 8, 'v1.10.0'), isFalse);
      expect(firmwareSupports(RadioSetting.autoAdd, 9, null), isTrue);
      expect(firmwareSupports(RadioSetting.floodScope, 10, 'v1.14.1'), isFalse);
      expect(firmwareSupports(RadioSetting.floodScope, 11, 'v1.15.0'), isTrue);
    });

    test('garbage input returns null', () {
      expect(BackupService.parseBackup('not json'), isNull);
      expect(BackupService.parseBackup('{"format":"something_else"}'), isNull);
    });
  });

  group('legacy contacts-only backup', () {
    test('bare JSON array is detected and parsed', () {
      final json = jsonEncode([
        _contactJson('bb' * 32, 'Peer'),
        _contactJson('cc' * 32, 'Other'),
      ]);
      final parsed = BackupService.parseBackup(json);
      expect(parsed, isA<LegacyContactsBackup>());
      final legacy = parsed as LegacyContactsBackup;
      expect(legacy.contacts.length, 2);
      expect(legacy.contacts[0].name, 'Peer');
      expect(legacy.contacts[1].publicKeyHex, 'cc' * 32);
    });
  });

  group('app settings allowlist', () {
    setUp(() {
      PrefsManager.reset();
    });

    test(
      'export includes allowed keys and excludes device-bound ones',
      () async {
        SharedPreferences.setMockInitialValues({
          'app_settings': '{"theme_mode":"dark"}',
          'chat_text_scale': 1.2,
          'ui_render_gifs': true,
          'map_removed_marker_ids': <String>['a', 'b'],
          'channel_order_radio1': '[1,0]',
          'contact_smaz_abc': true,
          'terms_accepted_v1': true,
          'last_ble_device_id': 'XX:YY',
          'contact_sync_cursor_abcdef0123': 42,
        });
        await PrefsManager.initialize();

        final exported = BackupService.exportAppSettings();
        expect(
          exported.keys,
          containsAll([
            'app_settings',
            'chat_text_scale',
            'ui_render_gifs',
            'map_removed_marker_ids',
            'channel_order_radio1',
            'contact_smaz_abc',
          ]),
        );
        expect(exported.containsKey('terms_accepted_v1'), isFalse);
        expect(exported.containsKey('last_ble_device_id'), isFalse);
        expect(exported.containsKey('contact_sync_cursor_abcdef0123'), isFalse);
        expect(exported['chat_text_scale'], {'t': 'd', 'v': 1.2});
        expect(exported['map_removed_marker_ids'], {
          't': 'sl',
          'v': ['a', 'b'],
        });
      },
    );

    test('restore writes values back with the right types', () async {
      SharedPreferences.setMockInitialValues({
        'app_settings': '{"theme_mode":"dark"}',
        'chat_text_scale': 1.2,
        'ui_render_gifs': true,
        'map_removed_marker_ids': <String>['a', 'b'],
      });
      await PrefsManager.initialize();
      final exported = BackupService.exportAppSettings();
      // Simulate the JSON round-trip a real backup file goes through.
      final decoded = jsonDecode(jsonEncode(exported)) as Map<String, dynamic>;

      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      await BackupService.restoreAppSettings(decoded);

      final prefs = PrefsManager.instance;
      expect(prefs.getString('app_settings'), '{"theme_mode":"dark"}');
      expect(prefs.getDouble('chat_text_scale'), 1.2);
      expect(prefs.getBool('ui_render_gifs'), true);
      expect(prefs.getStringList('map_removed_marker_ids'), ['a', 'b']);
    });

    test('restore never writes keys outside the allowlist', () async {
      SharedPreferences.setMockInitialValues({});
      await PrefsManager.initialize();
      await BackupService.restoreAppSettings({
        'terms_accepted_v1': {'t': 'b', 'v': true},
        'last_ble_device_id': {'t': 's', 'v': 'XX:YY'},
      });
      final prefs = PrefsManager.instance;
      expect(prefs.getBool('terms_accepted_v1'), isNull);
      expect(prefs.getString('last_ble_device_id'), isNull);
    });
  });

  group('telemetry byte layout (firmware: (env<<4)|(loc<<2)|base)', () {
    test('pack/unpack is symmetric for all values', () {
      for (var base = 0; base < 4; base++) {
        for (var loc = 0; loc < 4; loc++) {
          for (var env = 0; env < 4; env++) {
            final packed = (env << 4) | (loc << 2) | base;
            expect(packed & 0x03, base);
            expect(packed >> 2 & 0x03, loc);
            expect(packed >> 4 & 0x03, env);
          }
        }
      }
    });

    test('buildSetOtherParamsFrame carries the byte and manualAdd through', () {
      final frame = buildSetOtherParamsFrame(0x24, 1, 2, manualAdd: 0x00);
      expect(frame[0], cmdSetOtherParams);
      expect(frame[1], 0x00);
      expect(frame[2], 0x24);
      expect(frame[3], 1);
      expect(frame[4], 2);
      // Default stays MeshTrax policy: manual add disabled on the radio.
      expect(buildSetOtherParamsFrame(0, 0, 0)[1], 0x01);
    });
  });

  group('new protocol frames', () {
    test('export private key frame', () {
      expect(buildExportPrivateKeyFrame(), [cmdExportPrivateKey]);
    });

    test('import private key frame is cmd + 64 key bytes', () {
      final key = Uint8List.fromList(List.generate(64, (i) => i));
      final frame = buildImportPrivateKeyFrame(key);
      expect(frame.length, 65);
      expect(frame[0], cmdImportPrivateKey);
      expect(frame.sublist(1), key);
    });

    test('tuning params frames', () {
      expect(buildGetTuningParamsFrame(), [cmdGetTuningParams]);
      final frame = buildSetTuningParamsFrame(2500, 1000);
      expect(frame.length, 9);
      expect(frame[0], cmdSetTuningParams);
      final reader = BufferReader(frame)..skipBytes(1);
      expect(reader.readUInt32LE(), 2500);
      expect(reader.readUInt32LE(), 1000);
    });

    test('contact frame honors an explicit last-advert timestamp', () {
      final frame = buildUpdateContactPathFrame(
        Uint8List(32),
        Uint8List(0),
        0,
        1,
        lastAdvertEpochSeconds: 1700000122,
      );
      // cmd(1) + pubkey(32) + type(1) + flags(1) + pathLen(1) + path(64) +
      // name(32) puts the timestamp at offset 132.
      final reader = BufferReader(frame)..skipBytes(132);
      expect(reader.readUInt32LE(), 1700000122);
    });

    test('channel clear frame is empty name + zero psk', () {
      final frame = buildSetChannelFrame(3, '', Uint8List(16));
      expect(frame.length, 50);
      expect(frame[0], cmdSetChannel);
      expect(frame[1], 3);
      expect(frame.sublist(2).every((b) => b == 0), isTrue);
    });

    test('autoadd frame appends max hops only when given', () {
      Uint8List build({int? maxHops}) => buildSetAutoAddConfigFrame(
        autoAddChat: true,
        autoAddRepeater: true,
        autoAddRoomServer: true,
        autoAddSensor: true,
        overwriteOldest: false,
        maxHops: maxHops,
      );
      expect(build().length, 2);
      final withHops = build(maxHops: 4);
      expect(withHops.length, 3);
      expect(withHops[2], 4);
    });

    test('default flood scope frames', () {
      expect(buildGetDefaultFloodScopeFrame(), [cmdGetDefaultFloodScope]);
      expect(buildSetDefaultFloodScopeFrame(null, null), [
        cmdSetDefaultFloodScope,
      ]);
      final key = Uint8List.fromList(List.filled(16, 0xef));
      final frame = buildSetDefaultFloodScopeFrame('#uk', key);
      expect(frame.length, 1 + 31 + 16);
      expect(frame[0], cmdSetDefaultFloodScope);
      expect(String.fromCharCodes(frame.sublist(1, 4)), '#uk');
      expect(frame[4], 0);
      expect(frame.sublist(32), key);

      expect(
        parseDefaultFloodScopeFrame(
          Uint8List.fromList([respCodeDefaultFloodScope]),
        ),
        isNull,
      );
      final reply = Uint8List.fromList([
        respCodeDefaultFloodScope,
        ...frame.sublist(1),
      ]);
      final parsed = parseDefaultFloodScopeFrame(reply);
      expect(parsed?.name, '#uk');
      expect(parsed?.key, key);
    });
  });

  group('restore settings plan (firmware matrix)', () {
    ({List<RestoreWrite> writes, List<String> notes}) plan(
      DeviceBackup backup, {
      required int targetVerCode,
      String? targetVersion,
      bool? currentRepeat = true,
      int currentManualAdd = 1,
    }) => planRestoreSettings(
      backup,
      targetVerCode: targetVerCode,
      targetVersion: targetVersion,
      currentClientRepeat: currentRepeat,
      currentManualAddByte: currentManualAdd,
      currentTelemetryByte: 0x05,
      currentAdvertLocPolicy: 1,
      currentMultiAcks: 1,
    );
    Uint8List? frameFor(List<RestoreWrite> writes, String label) =>
        writes.where((w) => w.label == label).map((w) => w.frame).firstOrNull;

    test('1.17 backup onto 1.17 writes everything and notes nothing', () {
      final p = plan(
        _sampleBackup(),
        targetVerCode: 13,
        targetVersion: 'v1.17.1',
      );
      expect(p.notes, isEmpty);
      expect(
        p.writes.map((w) => w.label),
        containsAll([
          'Name',
          'Radio settings',
          'Transmit power',
          'Location',
          'Path hash size',
          'Telemetry and advert settings',
          'Contact auto-add settings',
          'Default flood scope',
          'Tuning settings',
          'Setting gps',
        ]),
      );
      final radio = frameFor(p.writes, 'Radio settings')!;
      expect(radio.length, 12);
      expect(radio[11], 1); // repeat on, from the backup
      final autoAdd = frameFor(p.writes, 'Contact auto-add settings')!;
      expect(autoAdd.length, 3);
      expect(autoAdd[2], 3);
      // Per-type firmware: the manual-add byte stays 1.
      expect(frameFor(p.writes, 'Telemetry and advert settings')![1], 1);
    });

    test('1.17 backup onto 1.11 skips what the radio lacks', () {
      final p = plan(
        _sampleBackup(),
        targetVerCode: 8,
        targetVersion: 'v1.11.0',
      );
      final labels = p.writes.map((w) => w.label).toList();
      expect(labels, isNot(contains('Path hash size')));
      expect(labels, isNot(contains('Contact auto-add settings')));
      expect(labels, isNot(contains('Default flood scope')));
      expect(p.notes, hasLength(3));
      expect(p.notes.where((n) => n.contains('not supported')), hasLength(2));
      // No repeat byte on pre-v9 firmware.
      expect(frameFor(p.writes, 'Radio settings')!.length, 11);
      // On/off-only firmware: a mixed per-type backup keeps the current byte
      // and says so.
      expect(frameFor(p.writes, 'Telemetry and advert settings')![1], 1);
      expect(
        p.notes.where((n) => n.startsWith('Contact auto-add')),
        hasLength(1),
      );
    });

    test('on/off-only firmware derives manual-add from the backup flags', () {
      DeviceBackup withFlags(bool v) => DeviceBackup(
        publicKeyHex: 'aa' * 32,
        name: 'x',
        autoAddChat: v,
        autoAddRepeater: v,
        autoAddRoomServer: v,
        autoAddSensor: v,
        autoAddOverwriteOldest: false,
      );
      Uint8List other(DeviceBackup b) => frameFor(
        plan(b, targetVerCode: 8, targetVersion: 'v1.11.0').writes,
        'Telemetry and advert settings',
      )!;
      expect(other(withFlags(true))[1], 0);
      expect(other(withFlags(false))[1], 1);
      // No flags at all: the backup's own raw byte wins.
      final raw = DeviceBackup(
        publicKeyHex: 'aa' * 32,
        name: 'x',
        manualAddContacts: 0,
      );
      expect(other(raw)[1], 0);
    });

    test('1.11 backup onto 1.17 leaves newer settings alone', () {
      final old = DeviceBackup.fromJson({
        'firmwareVersion': 'v1.11.0',
        'firmwareVerCode': 8,
        'publicKey': 'aa' * 32,
        'name': 'Old',
        'radio': {'freqHz': 910525000, 'bwHz': 250000, 'sf': 10, 'cr': 5},
        'telemetry': {'base': 1, 'loc': 0, 'env': 0},
        'multiAcks': 1,
        'advertLocPolicy': 1,
      });
      final p = plan(old, targetVerCode: 13, targetVersion: 'v1.17.1');
      final labels = p.writes.map((w) => w.label).toList();
      expect(labels, isNot(contains('Path hash size')));
      expect(labels, isNot(contains('Contact auto-add settings')));
      expect(labels, isNot(contains('Default flood scope')));
      expect(p.notes.every((n) => n.contains('not in the backup')), isTrue);
      // Repeat stays whatever the radio has now (on), never silently off.
      expect(frameFor(p.writes, 'Radio settings')![11], 1);
      // Never 0 on per-type firmware.
      expect(frameFor(p.writes, 'Telemetry and advert settings')![1], 1);
    });

    test('repeat gets a retry with repeat off', () {
      final p = plan(_sampleBackup(), targetVerCode: 13);
      final radio = p.writes.firstWhere((w) => w.label == 'Radio settings');
      expect(radio.retry, isNotNull);
      expect(radio.retry![11], 0);
      expect(radio.retryNote, isNotNull);
    });

    test('an explicit "no default scope" is restored as a clear', () {
      final b = DeviceBackup(
        publicKeyHex: 'aa' * 32,
        name: 'x',
        hasFloodScope: true,
      );
      final p = plan(b, targetVerCode: 13);
      expect(frameFor(p.writes, 'Default flood scope'), [
        cmdSetDefaultFloodScope,
      ]);
    });
  });
}
