import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/services/heard_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxheard/traxheard.dart';

// The owner, 2026-11-21: a region needs to know whether observers hear
// it. Learned from my own sends: after 3 in a row in a region that no
// observer heard, its channels get no observer check and no resend after
// one repeater, for a day; then one send is checked again.
final _self = Uint8List.fromList(List.filled(32, 0x77));
final _key = Uint8List.fromList(List.generate(16, (i) => 0x30 + i));

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(_self);
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(
    (ByteData(8)
          ..setUint32(0, 910525, Endian.little)
          ..setUint32(4, 62500, Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MeshCoreConnector radio;

  Future<void> attach({Map<String, Object> prefs = const {}}) async {
    SharedPreferences.setMockInitialValues({
      'heard_check_enabled': true,
      'heard_check_server': 'https://corescope.stonekitty.net',
      ...prefs,
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    radio = MeshCoreConnector();
    addTearDown(radio.dispose);
    radio.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    HeardService.resetForTesting();
    HeardService.instance.attach(radio);
  }

  var n = 0;
  String send({String? region}) {
    final id = 'm${n++}';
    radio.onChannelSendStamped!((
      messageId: id,
      channelKey: _key,
      senderName: 'GWQ',
      text: 'hello $id',
      secs: 1795306877 + n,
      region: region,
    ));
    return id;
  }

  void ear(String messageId) =>
      HeardService.instance.heardForTest(messageId, const [Sighting(observer: 'Ridge')]);

  const unheard = Duration(seconds: 91);

  test('a send in a region is checked while the region is unknown',
      () async {
    await attach();
    fakeAsync((async) {
      final id = send(region: 'sf');
      expect(HeardService.instance.checkingForTest(id), isTrue);
      async.elapse(unheard);
      expect(HeardService.instance.regionQuietForTest('sf'), isFalse, reason: '1 of 3');
    });
  });

  test('3 unheard in a row: no checks and no resend there for a day',
      () async {
    await attach();
    fakeAsync((async) {
      for (var i = 0; i < 3; i++) {
        send(region: 'sf');
        async.elapse(unheard);
      }
      expect(HeardService.instance.regionQuietForTest('sf'), isTrue);
      final id = send(region: 'sf');
      expect(HeardService.instance.checkingForTest(id), isFalse);
      expect(radio.mayResendAfterOneRepeater!(id), isFalse);

      final plain = send();
      expect(HeardService.instance.checkingForTest(plain), isTrue,
          reason: 'sends with no region are not affected');
    });
  });

  test('an ear in the region starts it over', () async {
    await attach();
    fakeAsync((async) {
      send(region: 'sf');
      async.elapse(unheard);
      send(region: 'sf');
      async.elapse(unheard);
      final id = send(region: 'sf');
      ear(id);
      async.elapse(unheard);
      for (var i = 0; i < 2; i++) {
        send(region: 'sf');
        async.elapse(unheard);
      }
      expect(HeardService.instance.regionQuietForTest('sf'), isFalse);
    });
  });

  test('after a day one send is checked; unheard, another quiet day',
      () async {
    await attach();
    final start = DateTime.now();
    addTearDown(() => HeardService.now = DateTime.now);
    fakeAsync((async) {
      HeardService.now = () => start.add(async.elapsed);
      for (var i = 0; i < 3; i++) {
        send(region: 'sf');
        async.elapse(unheard);
      }
      async.elapse(HeardService.regionQuietFor);
      expect(HeardService.instance.regionQuietForTest('sf'), isFalse);
      final probe = send(region: 'sf');
      expect(HeardService.instance.checkingForTest(probe), isTrue);
      async.elapse(unheard);
      expect(HeardService.instance.regionQuietForTest('sf'), isTrue);
    });
  });

  test('an ear proves only its own region for a resend', () async {
    await attach();
    final inSf = send(region: 'sf');
    final plain = send();
    final inLa = send(region: 'la');
    ear(inSf);
    expect(radio.mayResendAfterOneRepeater!(inSf), isTrue);
    expect(radio.mayResendAfterOneRepeater!(plain), isFalse,
        reason: 'observers hearing sf say nothing about no region');
    expect(radio.mayResendAfterOneRepeater!(inLa), isFalse);
  });

  test('a quiet region stays quiet after a restart', () async {
    await attach();
    fakeAsync((async) {
      for (var i = 0; i < 3; i++) {
        send(region: 'sf');
        async.elapse(unheard);
      }
    });
    await pumpEventQueue();
    HeardService.resetForTesting();
    HeardService.instance.attach(radio);
    expect(HeardService.instance.regionQuietForTest('sf'), isTrue);
  });

  test('a new server learns its regions again', () async {
    await attach();
    fakeAsync((async) {
      for (var i = 0; i < 3; i++) {
        send(region: 'sf');
        async.elapse(unheard);
      }
    });
    await HeardService.instance.setServer('https://live.chattamesh.com');
    expect(HeardService.instance.regionQuietForTest('sf'), isFalse);
  });
}
