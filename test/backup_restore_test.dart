import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/device_backup.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/backup_service.dart';
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
      firmwareVersion: 'v1.9.0',
      firmwareVerCode: 10,
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

    test('export includes allowed keys and excludes device-bound ones',
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
      expect(exported.keys, containsAll([
        'app_settings',
        'chat_text_scale',
        'ui_render_gifs',
        'map_removed_marker_ids',
        'channel_order_radio1',
        'contact_smaz_abc',
      ]));
      expect(exported.containsKey('terms_accepted_v1'), isFalse);
      expect(exported.containsKey('last_ble_device_id'), isFalse);
      expect(exported.containsKey('contact_sync_cursor_abcdef0123'), isFalse);
      expect(exported['chat_text_scale'], {'t': 'd', 'v': 1.2});
      expect(exported['map_removed_marker_ids'], {
        't': 'sl',
        'v': ['a', 'b'],
      });
    });

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
      final decoded =
          jsonDecode(jsonEncode(exported)) as Map<String, dynamic>;

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

    test('buildSetOtherParamsFrame carries the byte and manualAdd through',
        () {
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
  });
}
