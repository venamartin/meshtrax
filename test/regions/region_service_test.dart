import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/meshcore_qr.dart';
import 'package:meshtrax/helpers/region_helper.dart';
import 'package:meshtrax/services/region_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/utils/backup_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _psk = '00112233445566778899aabbccddeeff';

void main() {
  late RegionService regions;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    regions = RegionService();
    await regions.load();
  });

  group('the region list', () {
    test('keeps names as typed, sorted, without a leading #', () async {
      expect(await regions.add('sf'), isTrue);
      expect(await regions.add('#BayArea'), isTrue);
      expect(await regions.add('SF'), isTrue);
      expect(regions.regions, ['BayArea', 'SF', 'sf']);
    });

    test('refuses a name already listed or one the firmware refuses', () async {
      await regions.add('sf');
      expect(await regions.add('#sf'), isFalse);
      expect(await regions.add('bay area'), isFalse);
      expect(await regions.add('a' * 31), isFalse);
      expect(regions.regions, ['sf']);
    });

    test('survives a restart', () async {
      await regions.add('sf');
      await regions.setChannelRegion(_psk, 'sf');
      await regions.setRegionsInQr(true);
      final again = RegionService();
      await again.load();
      expect(again.regions, ['sf']);
      expect(again.regionOf(_psk), 'sf');
      expect(again.regionsInQr, isTrue);
    });
  });

  group('a channel region', () {
    test('is keyed by the channel key, whatever its case', () async {
      await regions.setChannelRegion(_psk.toUpperCase(), 'sf');
      expect(regions.regionOf(_psk), 'sf');
      expect(regions.channelsUsing('sf'), 1);
    });

    test('adds a region not yet listed', () async {
      await regions.setChannelRegion(_psk, 'bayarea');
      expect(regions.regions, ['bayarea']);
    });

    test('everywhere is kept without adding a region', () async {
      await regions.setChannelRegion(_psk, RegionHelper.everywhere);
      expect(regions.regionOf(_psk), RegionHelper.everywhere);
      expect(regions.regions, isEmpty);
    });

    test('null takes it off', () async {
      await regions.setChannelRegion(_psk, 'sf');
      await regions.setChannelRegion(_psk, null);
      expect(regions.regionOf(_psk), isNull);
      expect(regions.anyChannelHasRegion, isFalse);
    });

    test('deleting a region takes it off its channels', () async {
      await regions.setChannelRegion(_psk, 'sf');
      await regions.remove('sf');
      expect(regions.regions, isEmpty);
      expect(regions.regionOf(_psk), isNull);
      final again = RegionService();
      await again.load();
      expect(again.regionOf(_psk), isNull);
    });
  });

  test('the app backup carries regions and channel regions', () async {
    await regions.setChannelRegion(_psk, 'sf');
    await regions.setRegionsInQr(true);
    final exported = BackupService.exportAppSettings();
    expect(exported.keys, containsAll([
      'regions_list',
      'regions_channel_$_psk',
      'regions_in_qr',
    ]));
  });

  group('channel QR codes', () {
    test('leave the region out unless given one', () {
      expect(MeshCoreQr.encodeChannel('#a', _psk), isNot(contains('region')));
      final link = MeshCoreQr.encodeChannel('#a', _psk, region: 'sf');
      expect(link, endsWith('&region_scope=sf'));
      expect(MeshCoreQr.parseChannelQr(link)!.region, 'sf');
    });

    test('read a region, dropping a leading # and an unusable one', () {
      const base = 'meshcore://channel/add?name=a&secret=$_psk';
      expect(MeshCoreQr.parseChannelQr('$base&region_scope=%23sf')!.region,
          'sf');
      expect(MeshCoreQr.parseChannelQr('$base&region_scope=a%20b')!.region,
          isNull);
      expect(MeshCoreQr.parseChannelQr(base)!.region, isNull);
    });
  });
}
