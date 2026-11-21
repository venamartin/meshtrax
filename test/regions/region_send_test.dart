import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';


import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/region_helper.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/region_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The radio has no region per channel: the region it holds goes on every
// flood it sends, its own ACKs too. So a channel send in a region is
// set, send, clear, with nothing else written in between.
class _Connector extends MeshCoreConnector {
  bool connected = true;
  Completer<void>? gate;
  final written = <Uint8List>[];

  @override
  bool get isConnected => connected;

  @override
  Future<void> writeToTransport(Uint8List data) async {
    final hold = gate;
    if (hold != null) await hold.future;
    written.add(data);
  }

  /// The region frames and channel sends, in the order written.
  List<Uint8List> get regionAndChannel => written
      .where((f) => f[0] == cmdSetFloodScopeKey || f[0] == cmdSendChannelTxtMsg)
      .toList();
}

final _psk = Uint8List.fromList(List.generate(16, (i) => 0x30 + i));

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(Uint8List.fromList(List.filled(32, 0x77)));
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

Uint8List _deviceInfo(int verCode) {
  final f = Uint8List(82);
  f[0] = respCodeDeviceInfo;
  f[1] = verCode;
  // 0 slots reported: keeps the counts, so no resync.
  f.setRange(60, 67, utf8.encode('v1.18.0'));
  return f;
}

Uint8List _channelInfo() => Uint8List.fromList([
      respCodeChannelInfo,
      ...buildSetChannelFrame(1, '#test', _psk).sublist(1),
    ]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late RegionService regions;
  late Channel channel;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    final settings = AppSettingsService();
    await settings.loadSettings();
    regions = RegionService();
    await regions.load();
    c = _Connector()
      ..initialize(
        retryService: MessageRetryService(),
        appSettingsService: settings,
      )
      ..regionService = regions;
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest(_channelInfo());
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
    channel = c.channels.single;
    c.handleFrameForTest(_deviceInfo(14));
    await pumpEventQueue(times: 200);
    c.written.clear();
  });


  tearDown(() => c.connected = false);

  Future<void> send() async {
    await c.sendChannelMessage(channel, 'Pine cones are free');
    await pumpEventQueue(times: 200);
  }

  List<int> codes() => [for (final f in c.regionAndChannel) f[0]];

  test('a channel with a region: set, send, clear', () async {
    await regions.setChannelRegion(channel.idKey, 'sf');
    await send();
    final frames = c.regionAndChannel;
    expect(frames, hasLength(3));
    expect(frames[0], [cmdSetFloodScopeKey, 0, ...RegionHelper.keyFor('sf')]);
    expect(frames[1][0], cmdSendChannelTxtMsg);
    expect(frames[2], [cmdSetFloodScopeKey, 0]);
  });

  test("the region frames' OKs don't settle the message", () async {
    await regions.setChannelRegion(channel.idKey, 'sf');
    await send();
    expect(c.pendingGenericAckIdsForTest, hasLength(3));
    final messageId = c.pendingGenericAckIdsForTest[1];
    expect(messageId, isNotNull);
    c.handleFrameForTest([respCodeOk]);
    expect(c.pendingGenericAckIdsForTest, [messageId, null]);
    c.handleFrameForTest([respCodeOk]);
    c.handleFrameForTest([respCodeOk]);
    expect(c.pendingGenericAckIdsForTest, isEmpty);
  });

  test('no region: the channel send alone, as before', () async {
    await send();
    expect(codes(), [cmdSendChannelTxtMsg]);
  });

  test('everywhere: sends with no region on firmware 12+', () async {
    await regions.setChannelRegion(channel.idKey, RegionHelper.everywhere);
    await send();
    final frames = c.regionAndChannel;
    expect(frames.first, [cmdSetFloodScopeKey, 1]);
    expect(frames.last, [cmdSetFloodScopeKey, 0]);
  });

  test('everywhere does nothing on firmware 11', () async {
    c.handleFrameForTest(_deviceInfo(11));
    await regions.setChannelRegion(channel.idKey, RegionHelper.everywhere);
    await send();
    expect(codes(), [cmdSendChannelTxtMsg]);
  });

  test('firmware older than 8 gets no region frames', () async {
    c.handleFrameForTest(_deviceInfo(7));
    await regions.setChannelRegion(channel.idKey, 'sf');
    await send();
    expect(codes(), [cmdSendChannelTxtMsg]);
  });

  test('another frame waits until the region is cleared', () async {
    await regions.setChannelRegion(channel.idKey, 'sf');
    c.gate = Completer<void>();
    final inRegion = c.sendFrame(
      buildSendChannelTextMsgFrame(channel.index, 'hi'),
      expectsGenericAck: true,
    );
    await pumpEventQueue();
    final dm = c.sendFrame(Uint8List.fromList([cmdSendTxtMsg, 1, 2, 3]));
    await pumpEventQueue();
    c.gate!.complete();
    c.gate = null;
    await Future.wait([inRegion, dm]);
    final order = [
      for (final f in c.written)
        if (f[0] == cmdSetFloodScopeKey ||
            f[0] == cmdSendChannelTxtMsg ||
            f[0] == cmdSendTxtMsg)
          f.length == 2 ? 'clear' : '${f[0]}',
    ];
    expect(order, [
      '$cmdSetFloodScopeKey',
      '$cmdSendChannelTxtMsg',
      'clear',
      '$cmdSendTxtMsg',
    ]);
  });

  test('a frame sent outside a region send is written at once', () async {
    final before = c.written.length;
    unawaited(c.sendFrame(Uint8List.fromList([cmdSendTxtMsg, 1])));
    expect(c.pendingGenericAckIdsForTest, isEmpty);
    await pumpEventQueue();
    expect(c.written.length, before + 1);
  });

  test('the radio default region is read once and can be set', () async {
    unawaited(c.loadRadioDefaultRegion());
    await pumpEventQueue();
    expect(
      c.written.where((f) => f[0] == cmdGetDefaultFloodScope),
      hasLength(1),
    );
    final key = RegionHelper.keyFor('bayarea');
    c.handleFrameForTest([
      respCodeDefaultFloodScope,
      ...utf8.encode('bayarea'),
      ...List.filled(31 - 7, 0),
      ...key,
    ]);
    await pumpEventQueue();
    expect(c.radioDefaultRegion, 'bayarea');
    expect(c.radioDefaultRegionKnown, isTrue);

    final saving = c.setRadioDefaultRegion(null);
    await pumpEventQueue();
    expect(c.written.last, [cmdSetDefaultFloodScope]);
    c.handleFrameForTest([respCodeOk]);
    expect(await saving, isTrue);
    expect(c.radioDefaultRegion, isNull);
    expect(c.radioDefaultRegionKnown, isTrue);
  });

}
