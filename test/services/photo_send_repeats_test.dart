import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/services/photo_mesh.dart';
import 'package:meshtrax/services/photo_store.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A photo sent through repeaters: the radio hears its packets again only as
// repeaters pass them on, in its raw log. A packet nobody passed on goes once
// more, and the chat row shows what was heard.

final _psk = Uint8List.fromList(List.generate(16, (i) => 0x40 + i));

/// The repeater that passes packets on: A277, in 2-byte codes.
const _repeater = [0xA2, 0x77];

/// A radio on 920 MHz whose photo packets come back from repeater A277 as
/// [echo] says, for the [n]th packet handed over (0 first), packet [index]
/// of the photo.
class _Radio extends MeshCoreConnector {
  _Radio(this.echo);

  final bool Function(int n, int index) echo;

  /// The photo packets handed to the radio, in order.
  final List<Uint8List> blobs = [];

  bool heardLately = true;

  /// The copies come back with their last byte changed, as another
  /// sender's packet with the same prefix and image id would.
  bool lookalike = false;

  @override
  bool get isConnected => true;

  @override
  bool get repeaterHeardRecently => heardLately;

  @override
  int estimatePacketAirtimeMs(int bytes) => 20;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}

  @override
  Future<Uint8List?> sendAndAwaitReply(
    Uint8List data, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (data[0] == cmdSendChannelData) {
      final blob = Uint8List.sublistView(data, 5);
      final n = blobs.length;
      blobs.add(blob);
      if (echo(n, (blob[3] >> 4) & 0x0F)) {
        final copy = Uint8List.fromList(blob);
        if (lookalike) copy[copy.length - 1] ^= 0xFF;
        Timer(
          const Duration(milliseconds: 30),
          () => handleFrameForTest(_repeated(copy)),
        );
      }
    }
    return Uint8List.fromList([respCodeOk]);
  }
}

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(Uint8List.fromList(List.filled(32, 0x77)));
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(
    (ByteData(8)
          ..setUint32(0, 920000, Endian.little)
          ..setUint32(4, 62500, Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([7, 5]);
  w.add(utf8.encode('Base'));
  return w.toBytes();
}

Uint8List _channelInfo() => Uint8List.fromList([
  respCodeChannelInfo,
  ...buildSetChannelFrame(1, 'Trip', _psk).sublist(1),
]);

/// [blob] as the radio logs a repeater's copy of it: a flooded channel
/// datagram on Trip, sealed as the firmware seals one, through [_repeater].
Uint8List _repeated(List<int> blob) {
  final plain = [0x70, 0x01, blob.length, ...blob];
  final padded = Uint8List((plain.length + 15) ~/ 16 * 16)
    ..setRange(0, plain.length, plain);
  final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(_psk));
  final sealed = Uint8List(padded.length);
  for (var i = 0; i < padded.length; i += 16) {
    cipher.processBlock(padded, i, sealed, i);
  }
  final mac = crypto.Hmac(
    crypto.sha256,
    Uint8List(32)..setRange(0, 16, _psk),
  ).convert(sealed).bytes;
  return Uint8List.fromList([
    pushCodeLogRxData, 0x14, 0xA0, // SNR, RSSI
    (0x06 << 2) | 0x01, // group datagram, flood
    (1 << 6) | 1, ..._repeater, // one hop, 2-byte codes
    crypto.sha256.convert(_psk).bytes[0],
    mac[0], mac[1],
    ...sealed,
  ]);
}

/// The chunk index of each packet handed over.
List<int> _indexes(List<Uint8List> blobs) =>
    [for (final b in blobs) (b[3] >> 4) & 0x0F];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  final repeatWait = MeshCoreConnector.channelRepeatWait;

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('photo-repeats');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tmp.path,
        );
  });

  tearDownAll(() => tmp.deleteSync(recursive: true));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    MeshCoreConnector.channelRepeatWait = const Duration(milliseconds: 300);
    PhotoMesh.resetForTest();
  });

  tearDown(() {
    PhotoMesh.resetForTest();
    MeshCoreConnector.channelRepeatWait = repeatWait;
  });

  Future<_Radio> radio(bool Function(int n, int index) echo) async {
    final r = _Radio(echo);
    r.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    r.handleFrameForTest(_channelInfo());
    await pumpEventQueue(times: 200);
    r.markChannelsVerifiedForTest();
    return r;
  }

  /// Sends a photo of [bytes] (450: 3 packets, 600: 4) on Trip, then waits
  /// out the check after the last packet (one flood gap, 660 ms here) and
  /// the wait for its copies.
  Future<(ChannelMessage, PhotoRecord)> send(
    _Radio r, {
    bool zeroHop = false,
    int bytes = 450,
  }) async {
    final bitstream = Uint8List.fromList(List.generate(bytes, (i) => i * 7));
    await PhotoMesh.of(r).sendPhoto(
      bitstream,
      1,
      zeroHop: zeroHop,
      repairPacket: false,
    );
    await Future<void>.delayed(const Duration(milliseconds: 2000));
    await pumpEventQueue(times: 200);
    final rows = await r.loadChannelMessagesFor(
      r.channels.firstWhere((c) => c.index == 1),
    );
    final row = rows.singleWhere(PhotoMesh.isPhotoMessage);
    return (row, PhotoStore.instance.recordFor(row.messageId)!);
  }

  test('a packet no repeater passed on goes once more, and the photo shows '
      'delivered once every packet was', () async {
    // Packet 1 is lost the first time; the copy sent again gets through.
    final r = await radio((n, index) => index != 1 || n == 2);
    final (row, record) = await send(r);
    expect(_indexes(r.blobs), [0, 1, 1, 2]);
    expect(r.blobs[2], r.blobs[1]);
    expect(row.status, ChannelMessageStatus.delivered);
    expect(row.repeatCount, 3);
    expect(row.pathVariants.single, _repeater);
    expect(row.pathHashSize, 2);
    expect(record.packetsPassedOn, 3);
    expect(r.isChannelMessageRetrying(row.messageId), isFalse);
  });

  test('after a packet sent again goes unheard, no more go while nothing is '
      'heard, and the photo stays sent', () async {
    final r = await radio((n, index) => index == 0);
    final (row, record) = await send(r);
    expect(_indexes(r.blobs), [0, 1, 1, 2]);
    expect(row.status, ChannelMessageStatus.sent);
    expect(row.repeatCount, 1);
    expect(record.packetsPassedOn, 1);
    // The wait is over: the chat shows the amber check.
    expect(r.isChannelMessageRetrying(row.messageId), isFalse);
  });

  test('a copy heard after that lets a later packet go again', () async {
    // Packets 1 and 3 never come back; packet 2's copy shows a repeater
    // still hears this radio.
    final r = await radio((n, index) => index == 0 || index == 2);
    final (row, record) = await send(r, bytes: 600);
    expect(_indexes(r.blobs), [0, 1, 1, 2, 3, 3]);
    expect(row.status, ChannelMessageStatus.sent);
    expect(record.packetsPassedOn, 2);
  });

  test('copies only a car repeater carried are shown, but count for nothing',
      () async {
    final r = await radio((n, index) => true)
      ..isCarRepeater = (hop, width) => true;
    final (row, record) = await send(r);
    expect(_indexes(r.blobs), [0, 0, 1, 2]);
    expect(row.status, ChannelMessageStatus.sent);
    expect(row.repeatCount, 4);
    expect(record.packetsPassedOn, 0);
  });

  test('Pathfinder hears of the first repeater once per photo', () async {
    final told = <(List<int>, int)>[];
    final r = await radio((n, index) => true)
      ..onOwnEchoHeard = (path, width) => told.add((List.of(path), width));
    final (row, _) = await send(r);
    expect(row.status, ChannelMessageStatus.delivered);
    expect(told, hasLength(1));
    expect(told.single.$1, _repeater);
    expect(told.single.$2, 2);
  });

  test('another sender\'s packet with the same prefix and image id counts '
      'for nothing, and Pathfinder never hears of it', () async {
    final told = <(List<int>, int)>[];
    final r = await radio((n, index) => true)
      ..lookalike = true
      ..onOwnEchoHeard = (path, width) => told.add((List.of(path), width));
    final (row, record) = await send(r);
    expect(_indexes(r.blobs), [0, 0, 1, 2]);
    expect(row.repeatCount, 0);
    expect(record.packetsPassedOn, 0);
    expect(told, isEmpty);
  });

  test('with no repeater heard lately nothing goes again, but what is heard '
      'still counts', () async {
    final r = await radio((n, index) => index != 1)..heardLately = false;
    final (row, record) = await send(r);
    expect(_indexes(r.blobs), [0, 1, 2]);
    expect(row.status, ChannelMessageStatus.sent);
    expect(record.packetsPassedOn, 2);
  });

  test('zero hop: no repeater carries it, so nothing waits or goes again',
      () async {
    final r = await radio((n, index) => false);
    final (row, record) = await send(r, zeroHop: true);
    expect(_indexes(r.blobs), [0, 1, 2]);
    expect(row.status, ChannelMessageStatus.sent);
    expect(record.packetsPassedOn, isNull);
    expect(r.isChannelMessageRetrying(row.messageId), isFalse);
  });

  test('the photo waits for its copies while they can still come', () async {
    final r = await radio((n, index) => true);
    final bitstream = Uint8List.fromList(List.generate(450, (i) => i * 7));
    await PhotoMesh.of(r).sendPhoto(bitstream, 1, repairPacket: false);
    final rows = await r.loadChannelMessagesFor(
      r.channels.firstWhere((c) => c.index == 1),
    );
    final row = rows.singleWhere(PhotoMesh.isPhotoMessage);
    expect(r.isChannelMessageRetrying(row.messageId), isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    expect(r.isChannelMessageRetrying(row.messageId), isFalse);
  });
}
