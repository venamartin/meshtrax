import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/health/health_rules.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/region_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Health findings from what nearby repeaters said they carry.
final _channel = Channel(
  index: 1,
  name: '#hiking',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x30 + i)),
);

class _Radio extends MeshCoreConnector {
  @override
  List<Channel> get channels => [_channel];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegionService regions;
  late HealthContext ctx;

  HealthRule rule(String id) => healthRules.singleWhere((r) => r.id == id);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    regions = RegionService();
    await regions.load();
    final radio = _Radio()..regionService = regions;
    ctx = HealthContext(radio, AppSettingsService(), canShowNotifications: true);
  });

  test('nothing until a repeater has answered', () async {
    await regions.setChannelRegion(_channel.idKey, 'sf');
    expect(await rule('regions_no_plain_nearby').check(ctx), isFalse);
    expect(await rule('regions_channel_not_carried').check(ctx), isFalse);
  });

  test('nearby repeaters that refuse messages with no region', () async {
    await regions.saveReport('01' * 32, ['sf']);
    await regions.saveReport('02' * 32, ['la']);
    expect(await rule('regions_no_plain_nearby').check(ctx), isTrue);
    await regions.saveReport('02' * 32, ['*']);
    expect(await rule('regions_no_plain_nearby').check(ctx), isFalse);
  });

  test("a channel's region no nearby repeater carries", () async {
    await regions.saveReport('01' * 32, ['*', 'la']);
    await regions.setChannelRegion(_channel.idKey, 'sf');
    final notCarried = rule('regions_channel_not_carried');
    expect(await notCarried.check(ctx), isTrue);
    expect(notCarried.details!(ctx), ['#hiking: sf']);

    await regions.setChannelRegion(_channel.idKey, 'la');
    expect(await notCarried.check(ctx), isFalse);
  });
}
