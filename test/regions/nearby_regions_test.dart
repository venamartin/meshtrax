import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/nearby_regions_asker.dart';
import 'package:meshtrax/services/region_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// After a Discover the user started, each repeater that answered and is
// saved on the radio is asked for its regions, DIRECT, at most once a day.
Uint8List _key(int seed) => Uint8List.fromList(List.generate(32, (i) => seed));

Contact _repeater(int seed, {int pathLength = -1, int type = advTypeRepeater}) =>
    Contact(
      publicKey: _key(seed),
      name: 'R$seed',
      type: type,
      pathLength: pathLength,
      path: pathLength > 0 ? Uint8List.fromList([0xAB]) : Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime.now(),
    );

/// A radio that answers the regions question as a repeater would:
/// RESP_CODE_SENT with a tag, then the repeater's answer under that tag.
class _Radio extends MeshCoreConnector {
  _Radio(this.saved);

  final List<Contact> saved;
  final Map<int, String?> answers = {};
  final routes = <String, PathSelection>{};
  final asked = <int>[];
  bool flood = false;
  var _tag = 0x10;

  @override
  bool get isConnected => true;
  @override
  bool get supportsRegions => true;
  @override
  List<Contact> get contacts => saved;

  @override
  Future<void> sendOnRoute(
    Contact contact,
    PathSelection selection,
    Future<void> Function() send,
  ) async {
    routes[contact.publicKeyHex] = selection;
    await send();
  }

  @override
  Future<void> writeToTransport(Uint8List data) async {
    if (data[0] != cmdSendAnonReq) return;
    final seed = data[1];
    asked.add(seed);
    expect(data.sublist(33), [anonReqTypeRegions, 0]);
    final tag = [_tag++, 0, 0, 0];
    scheduleMicrotask(() {
      handleFrameForTest([respCodeSent, flood ? 1 : 0, ...tag, 0, 0, 0, 0]);
      final answer = answers[seed];
      if (answer != null && !flood) {
        handleFrameForTest([
          pushCodeBinaryResponse, 0, ...tag, 1, 2, 3, 4, // clock
          ...utf8.encode(answer),
        ]);
      }
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RegionService regions;
  final wait = NearbyRegionsAsker.answerWait;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    regions = RegionService();
    await regions.load();
    NearbyRegionsAsker.answerWait = const Duration(milliseconds: 200);
  });
  tearDown(() => NearbyRegionsAsker.answerWait = wait);

  String hex(int seed) => pubKeyToHex(_key(seed));

  test('asks the saved repeaters that answered, and keeps what they say',
      () async {
    final radio = _Radio([_repeater(1), _repeater(2, pathLength: 1)])
      ..answers[1] = '*,sf'
      ..answers[2] = 'bayarea';
    await NearbyRegionsAsker(radio, regions)
        .askAll([_key(1), _key(2), _key(3)]);
    expect(radio.asked, [1, 2], reason: '3 is not saved on the radio');
    expect(regions.reportOf(hex(1))!.names, ['*', 'sf']);
    expect(regions.reportOf(hex(2))!.names, ['bayarea']);

    final noRoute = radio.routes[hex(1)]!;
    expect(noRoute.useFlood, isFalse);
    expect(noRoute.hopCount, 0, reason: 'it just answered a zero-hop Discover');
    expect(radio.routes[hex(2)]!.source, RouteSource.firmware,
        reason: 'a route the radio has is used as it is');
  });

  test('a repeater is asked at most once a day', () async {
    final radio = _Radio([_repeater(1)])..answers[1] = 'sf';
    final asker = NearbyRegionsAsker(radio, regions);
    await asker.askAll([_key(1)]);
    await asker.askAll([_key(1)]);
    expect(radio.asked, [1]);
  });

  test('a contact that is not a repeater is not asked', () async {
    final radio = _Radio([_repeater(1, type: advTypeChat)]);
    await NearbyRegionsAsker(radio, regions).askAll([_key(1)]);
    expect(radio.asked, isEmpty);
  });

  test('no answer, or a flooded question: nothing kept, asked next time',
      () async {
    final radio = _Radio([_repeater(1), _repeater(2)])..answers[2] = 'sf';
    radio.flood = true;
    await NearbyRegionsAsker(radio, regions).askAll([_key(1), _key(2)]);
    expect(regions.reportOf(hex(1)), isNull);
    expect(regions.reportOf(hex(2)), isNull);
    expect(regions.askedLately(hex(2)), isFalse);
  });

  group('what the repeaters said', () {
    setUp(() async {
      await regions.saveReport(hex(1), ['*', 'sf']);
      await regions.saveReport(hex(2), ['sf', 'bayarea']);
    });

    test('counts carriers and lists names heard', () {
      expect(regions.hasRepeaterReports, isTrue);
      expect(regions.carriersOf('sf'), 2);
      expect(regions.carriersOf('bayarea'), 1);
      expect(regions.carriersOf('la'), 0);
      expect(regions.heardFromRepeaters, {'sf', 'bayarea'});
      expect(regions.nearbyRefuseNoRegion, isFalse);
    });

    test('all of them refusing messages with no region is noticed', () async {
      await regions.saveReport(hex(1), ['sf']);
      expect(regions.nearbyRefuseNoRegion, isTrue);
    });

    test('kept across a restart, and not in the app backup', () async {
      final again = RegionService();
      await again.load();
      expect(again.carriersOf('sf'), 2);
      expect(
        PrefsManager.instance.getKeys().where((k) => k.startsWith('regions_')),
        isEmpty,
      );
    });
  });

  group("Discover's hook", () {
    Uint8List answer(Uint8List key, int tag) => Uint8List.fromList([
          pushCodeControlData, 35, 0xA0, 0,
          ctlTypeNodeDiscoverResp | advTypeRepeater, 26,
          ...(ByteData(4)..setUint32(0, tag, Endian.little))
              .buffer
              .asUint8List(),
          ...key,
        ]);

    List<List<Uint8List>> run({required bool automatic}) {
      final heard = <List<Uint8List>>[];
      fakeAsync((async) {
        final radio = _Discoverer()..onManualDiscoverDone = heard.add;
        radio.sendRepeaterDiscovery(automatic: automatic);
        async.flushMicrotasks();
        radio.handleFrameForTest(answer(_key(7), radio.pendingDiscoverTag!));
        async.elapse(MeshCoreConnector.discoverWindow);
        async.flushMicrotasks();
        radio.dispose();
      });
      return heard;
    }

    test('a Discover the user started hands over who answered', () {
      final heard = run(automatic: false);
      expect(heard, hasLength(1));
      expect(heard.single.single, _key(7));
    });

    test('an automatic Discover asks nobody', () {
      expect(run(automatic: true), isEmpty);
    });
  });
}

class _Discoverer extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
}
