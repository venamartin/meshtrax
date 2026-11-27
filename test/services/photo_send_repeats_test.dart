import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/region_helper.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/channel_request.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/channel_requests.dart';
import 'package:meshtrax/services/heard_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/photo_mesh.dart';
import 'package:meshtrax/services/photo_rules.dart';
import 'package:meshtrax/services/photo_store.dart';
import 'package:meshtrax/services/region_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxheard/traxheard.dart' show Sighting, channelDataPacketHash;
import 'package:traxpix/traxpix.dart'
    show
        ImageChunkSet,
        ImageCodecRatePoint,
        ImageStreamMetadata,
        PhotoExtras,
        buildImageChunks,
        kImageRetryByteOffset,
        kPhotoItemSubjectOnly,
        photoPacketAgain,
        photoPacketsRequest,
        photoPayload,
        readPhotoPacketsRequest,
        samePhotoPacket;

// A photo goes into the chat at once; the chat then sends its packets one
// at a time, each on a channel text's terms before the next goes. The radio
// hears its own packets again only as repeaters pass them on, in its raw log;
// a packet sent again has its retry byte bumped, so repeaters pass it on
// again. The chat row shows what was heard. A received photo's row says how
// far it came.

final _psk = Uint8List.fromList(List.generate(16, (i) => 0x40 + i));

/// The repeater that passes packets on: A277, in 2-byte codes.
const _repeater = [0xA2, 0x77];

/// A radio, on 920 MHz unless a test says, that takes every photo packet the
/// chat hands it (OK), and whose repeaters pass on the [n]th packet handed
/// over (0 first), packet [index] of the photo, as [echo] says, through
/// [path].
class _Radio extends MeshCoreConnector {
  _Radio(this.echo);

  final bool Function(int n, int index) echo;

  List<int> path = _repeater;

  /// The photo packets the radio took, in order, with each one's path
  /// length (0xFF: a flood, 0: zero hop), data type and when it went.
  final List<Uint8List> blobs = [];
  final List<int> paths = [];
  final List<int> types = [];
  final List<DateTime> handedOver = [];

  /// Told of each packet as the radio takes it.
  void Function(int n, int index)? onPacket;

  /// The radio refuses the [refuseAt]th packet handed to it (0 first), with
  /// error 3.
  int? refuseAt;
  int _handed = 0;

  int airtimeMs = 20;

  /// The copies come back with their last byte changed, as another
  /// sender's packet with the same prefix and image id would.
  bool lookalike = false;

  bool heardThisMinute = true;

  @override
  bool get isConnected => true;

  @override
  bool repeaterHeardWithin(Duration window) => heardThisMinute;

  @override
  int estimatePacketAirtimeMs(int bytes) => airtimeMs;

  @override
  Future<void> writeToTransport(Uint8List data) async {
    void answer(List<int> reply) =>
        Timer.run(() => handleFrameForTest(Uint8List.fromList(reply)));
    if (data[0] != cmdSendChannelData) {
      answer([respCodeOk]);
      return;
    }
    if (_handed++ == refuseAt) {
      answer([respCodeErr, 3]);
      return;
    }
    final blob = Uint8List.fromList(data.sublist(5));
    final type = data[3] | data[4] << 8;
    final n = blobs.length;
    final index = (blob[3] >> 4) & 0x0F;
    blobs.add(blob);
    paths.add(data[2]);
    types.add(type);
    handedOver.add(DateTime.now());
    onPacket?.call(n, index);
    answer([respCodeOk]);
    if (data[2] == 0xFF && echo(n, index)) {
      final copy = Uint8List.fromList(blob);
      if (lookalike) copy[copy.length - 1] ^= 0xFF;
      Timer(
        const Duration(milliseconds: 30),
        () => handleFrameForTest(_repeated(copy, path: path, dataType: type)),
      );
    }
  }
}

Uint8List _selfInfo({int freqKhz = 920000}) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(Uint8List.fromList(List.filled(32, 0x77)));
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(
    (ByteData(8)
          ..setUint32(0, freqKhz, Endian.little)
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
/// datagram on Trip of [dataType], sealed as the firmware seals one, through
/// [path] (no repeater: heard from the sender's own radio).
Uint8List _repeated(
  List<int> blob, {
  List<int> path = _repeater,
  int dataType = 0x0172,
}) {
  final plain = [dataType & 0xFF, dataType >> 8, blob.length, ...blob];
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
    (1 << 6) | path.length ~/ 2, ...path, // 2-byte codes
    crypto.sha256.convert(_psk).bytes[0],
    mac[0], mac[1],
    ...sealed,
  ]);
}

/// [blob] as the radio hands over a channel datagram of [dataType] it
/// received on Trip: frame 27, with the path length the radio reports
/// (0xFF: it came direct).
Uint8List _received(List<int> blob, int pathLen, {int dataType = 0x0172}) =>
    Uint8List.fromList([
      respCodeChannelDataRecv, 0x14, 0, 0, 1, pathLen, //
      dataType & 0xFF, dataType >> 8, blob.length, ...blob,
    ]);

/// The packet index of each packet handed over.
List<int> _indexes(List<Uint8List> blobs) =>
    [for (final b in blobs) (b[3] >> 4) & 0x0F];

/// How many times each packet handed over went before.
List<int> _retries(List<Uint8List> blobs) =>
    [for (final b in blobs) b[kImageRetryByteOffset]];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tmp;
  final repeatWait = MeshCoreConnector.channelRepeatWait;
  final radioQuiet = MeshCoreConnector.radioQuietMs;
  late AppSettingsService settings;

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
    settings = AppSettingsService();
    await settings.loadSettings();
    MeshCoreConnector.channelRepeatWait = const Duration(milliseconds: 300);
    MeshCoreConnector.radioQuietMs = 50;
    PhotoMesh.resetForTest();
    ChannelRequests.resetForTest();
  });

  tearDown(() {
    PhotoMesh.resetForTest();
    ChannelRequests.resetForTest();
    MeshCoreConnector.channelRepeatWait = repeatWait;
    MeshCoreConnector.radioQuietMs = radioQuiet;
  });

  /// Waits until [r]'s photos are done with: every packet went, the chat no
  /// longer listens for copies, and what was heard is written.
  Future<void> settled(_Radio r) async {
    for (var i = 0; i < 600 && PhotoMesh.of(r).busy; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(PhotoMesh.of(r).busy, isFalse, reason: 'still going');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await pumpEventQueue(times: 200);
  }

  Future<_Radio> radio(
    bool Function(int n, int index) echo, {
    int freqKhz = 920000,
    int retries = 1,
  }) async {
    await settings.setMaxChannelMessageRetries(retries);
    final r = _Radio(echo)
      ..initialize(
        retryService: MessageRetryService(),
        appSettingsService: settings,
      );
    r.handleFrameForTest(_selfInfo(freqKhz: freqKhz));
    await pumpEventQueue(times: 200);
    r.handleFrameForTest(_channelInfo());
    await pumpEventQueue(times: 200);
    r.markChannelsVerifiedForTest();
    return r;
  }

  Future<ChannelMessage> photoRow(_Radio r) async {
    final rows = await r.loadChannelMessagesFor(
      r.channels.firstWhere((c) => c.index == 1),
    );
    return rows.singleWhere(PhotoMesh.isPhotoMessage);
  }

  /// Sends a photo of [bytes] (450: 3 packets, 600: 4, 100: 1) on Trip, and
  /// waits until it is done with ([settled]).
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
    await settled(r);
    final row = await photoRow(r);
    return (row, PhotoStore.instance.recordFor(row.messageId)!);
  }

  /// What the chat row of the photo going says it does, each change once.
  List<(PhotoSendStep, int)> watchSteps() {
    final steps = <(PhotoSendStep, int)>[];
    void listen() {
      for (final state in PhotoMesh.sending.value.values) {
        final step = (state.step, state.packet);
        if (steps.isEmpty || steps.last != step) steps.add(step);
      }
    }

    PhotoMesh.sending.addListener(listen);
    addTearDown(() => PhotoMesh.sending.removeListener(listen));
    return steps;
  }

  test('a packet no repeater passed on goes again before the next, its '
      'retry byte bumped, and the photo shows delivered once every packet '
      'was', () async {
    // Packet 1 is lost the first time; the copy sent again gets through.
    final r = await radio((n, index) => index != 1 || n == 2);
    final (row, record) = await send(r);
    expect(_indexes(r.blobs), [0, 1, 1, 2]);
    expect(_retries(r.blobs), [0, 0, 1, 0]);
    expect(samePhotoPacket(r.blobs[2], r.blobs[1]), isTrue);
    expect(r.types, everyElement(0x0172));
    expect(row.status, ChannelMessageStatus.delivered);
    expect(row.repeatCount, 3);
    expect(row.pathVariants.single, _repeater);
    expect(row.pathHashSize, 2);
    expect(record.packetsPassedOn, 3);
    expect(r.isChannelMessageRetrying(row.messageId), isFalse);
  });

  test('the next packet waits at least a flood gap', () async {
    final r = await radio((n, index) => true);
    await send(r);
    for (var i = 1; i < r.handedOver.length; i++) {
      expect(
        r.handedOver[i].difference(r.handedOver[i - 1]),
        greaterThanOrEqualTo(const Duration(milliseconds: 640)),
      );
    }
  });

  test('a photo of one packet no repeater passed on goes once more',
      () async {
    final r = await radio((n, index) => n == 1);
    final (row, record) = await send(r, bytes: 100);
    expect(_indexes(r.blobs), [0, 0]);
    expect(_retries(r.blobs), [0, 1]);
    expect(row.status, ChannelMessageStatus.delivered);
    expect(record.packetsPassedOn, 1);
  });

  test('a photo of one packet a repeater passed on goes once only', () async {
    final r = await radio((n, index) => true);
    final (row, _) = await send(r, bytes: 100);
    expect(_indexes(r.blobs), [0]);
    expect(row.status, ChannelMessageStatus.delivered);
  });

  test('each packet no repeater passed on goes again within the channel '
      'retries, and the photo stays sent', () async {
    final r = await radio((n, index) => index == 0);
    final (row, record) = await send(r);
    expect(_indexes(r.blobs), [0, 1, 1, 2, 2]);
    expect(_retries(r.blobs), [0, 0, 1, 0, 1]);
    expect(row.status, ChannelMessageStatus.sent);
    expect(row.repeatCount, 1);
    expect(record.packetsPassedOn, 1);
    // The wait is over: the chat shows the amber check.
    expect(r.isChannelMessageRetrying(row.messageId), isFalse);
  });

  test('with three channel retries, a packet no repeater passes on goes '
      'three times more, counting 1, 2 and 3', () async {
    final r = await radio((n, index) => false, retries: 3);
    await send(r, bytes: 100);
    expect(_indexes(r.blobs), [0, 0, 0, 0]);
    expect(_retries(r.blobs), [0, 1, 2, 3]);
  });

  test('with channel retries off, nothing goes again', () async {
    final r = await radio((n, index) => false, retries: 0);
    final (row, _) = await send(r);
    expect(_indexes(r.blobs), [0, 1, 2]);
    expect(row.status, ChannelMessageStatus.sent);
  });

  test('copies only a car repeater carried are shown, but count for nothing; '
      'without observers, one repeat is enough, as for a text', () async {
    final r = await radio((n, index) => true)
      ..isCarRepeater = (hop, width) => true;
    final (row, record) = await send(r);
    expect(_indexes(r.blobs), [0, 1, 2]);
    expect(row.status, ChannelMessageStatus.sent);
    expect(row.repeatCount, 3);
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
    expect(_indexes(r.blobs), [0, 0, 1, 1, 2, 2]);
    expect(row.repeatCount, 0);
    expect(record.packetsPassedOn, 0);
    expect(told, isEmpty);
  });

  test('zero hop: no repeater carries it, so nothing waits or goes again',
      () async {
    final r = await radio((n, index) => false);
    final (row, record) = await send(r, zeroHop: true);
    expect(_indexes(r.blobs), [0, 1, 2]);
    expect(r.paths, [0, 0, 0], reason: 'path length 0: zero hop');
    expect(row.status, ChannelMessageStatus.sent);
    expect(record.packetsPassedOn, isNull);
    expect(r.isChannelMessageRetrying(row.messageId), isFalse);
  });

  test('the photo is in the chat before its packets go, and shows as going '
      'until it is done with', () async {
    final r = await radio((n, index) => true);
    final bitstream = Uint8List.fromList(List.generate(450, (i) => i * 7));
    await PhotoMesh.of(r).sendPhoto(bitstream, 1, repairPacket: false);
    final row = await photoRow(r);
    expect(r.blobs.length, lessThan(3), reason: 'still going');
    expect(PhotoStore.instance.recordFor(row.messageId)!.outgoing, isTrue);
    expect(PhotoMesh.sending.value, contains(row.messageId));
    expect(r.isChannelMessageRetrying(row.messageId), isTrue);
    await settled(r);
    expect(PhotoMesh.sending.value, isEmpty);
    expect(r.isChannelMessageRetrying(row.messageId), isFalse);
  });

  test('the chat row says what the photo does as its packets go', () async {
    final steps = watchSteps();
    final r = await radio((n, index) => index != 1 || n == 2);
    await send(r);
    expect(steps, [
      (PhotoSendStep.waiting, 0),
      (PhotoSendStep.sending, 1),
      (PhotoSendStep.sending, 2),
      (PhotoSendStep.again, 2),
      (PhotoSendStep.sending, 3),
    ]);
  });

  test('a packet the radio refuses fails the photo, and its row says why',
      () async {
    final r = await radio((n, index) => true)..refuseAt = 1;
    final (row, _) = await send(r);
    expect(_indexes(r.blobs), [0], reason: 'nothing after the refused one');
    expect(row.status, ChannelMessageStatus.failed);
    final state = PhotoMesh.sending.value[row.messageId]!;
    expect(state.step, PhotoSendStep.failed);
    final error = state.error! as PhotoSendException;
    expect(error.failure, PhotoSendFailure.refused);
    expect(error.code, 3);
    expect(r.isChannelMessageRetrying(row.messageId), isFalse);
  });

  test('a second photo waits for the first to be done', () async {
    final r = await radio((n, index) => true);
    final first = Uint8List.fromList(List.generate(450, (i) => i * 7));
    final second = Uint8List.fromList(List.generate(300, (i) => i * 5));
    await PhotoMesh.of(r).sendPhoto(first, 1, repairPacket: false);
    await PhotoMesh.of(r).sendPhoto(second, 1, repairPacket: false);
    expect(
      PhotoMesh.sending.value.values.map((s) => s.step),
      contains(PhotoSendStep.waiting),
    );
    await settled(r);
    final ids = [for (final b in r.blobs) b[2]];
    expect(ids, hasLength(5));
    expect(ids.toSet(), hasLength(2));
    expect(ids.sublist(0, 3).toSet(), hasLength(1), reason: 'first all first');
  });

  test('a Nearby only channel sends its photo zero hop, with the zero-hop '
      'gap, and nothing waits or goes again', () async {
    final regions = RegionService();
    await regions.load();
    final r = await radio((n, index) => false)
      ..airtimeMs = 100
      ..regionService = regions;
    await regions.setChannelRegion(
      r.channels.firstWhere((c) => c.index == 1).idKey,
      RegionHelper.nearbyOnly,
    );
    final (row, record) = await send(r);
    expect(r.paths, [0, 0, 0], reason: 'path length 0: zero hop');
    // Zero hop: an airtime and 0.5 s apart, 600 ms; a flood's gap of 8
    // airtimes and 0.5 s would be 1300.
    expect(
      r.handedOver[1].difference(r.handedOver[0]),
      lessThan(const Duration(milliseconds: 1000)),
    );
    expect(row.status, ChannelMessageStatus.sent);
    expect(record.packetsPassedOn, isNull);
    expect(r.isChannelMessageRetrying(row.messageId), isFalse);
  });

  group('a received photo says how far it came', () {
    /// A 3-packet photo from radio BEEF.
    List<Uint8List> theirs(int imgId) => buildImageChunks(
      payload: Uint8List.fromList(List.generate(440, (i) => i * 3)),
      metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.ft8),
      senderPrefix: 0xBEEF,
      imgId: imgId,
      parity: false,
    ).blobs;

    Future<ChannelMessage> row(_Radio r) async {
      await pumpEventQueue(times: 200);
      return photoRow(r);
    }

    test('through repeaters: the fewest any packet came through, and not '
        'Direct', () async {
      final r = await radio((n, index) => false);
      PhotoMesh.of(r);
      final blobs = theirs(0x21);
      // Two repeaters, then three, then two, in 2-byte codes.
      r.handleFrameForTest(_received(blobs[0], 0x42));
      r.handleFrameForTest(_received(blobs[1], 0x43));
      r.handleFrameForTest(_received(blobs[2], 0x42));
      final photo = await row(r);
      expect(photo.isOutgoing, isFalse);
      expect(photo.heardDirect, isFalse);
      expect(photo.pathLength, 2);
    });

    test('Direct once a packet was heard from the sender\'s own radio',
        () async {
      final r = await radio((n, index) => false);
      PhotoMesh.of(r);
      final blobs = theirs(0x22);
      r.handleFrameForTest(_received(blobs[0], 0x42));
      // The raw log heard packet 1 before any repeater passed it on.
      r.handleFrameForTest(_repeated(blobs[1], path: const []));
      r.handleFrameForTest(_received(blobs[1], 0x42));
      r.handleFrameForTest(_received(blobs[2], 0x42));
      final photo = await row(r);
      expect(photo.heardDirect, isTrue);
      expect(photo.pathLength, 0);
    });

    test('zero hop: its frames say it came direct', () async {
      final r = await radio((n, index) => false);
      PhotoMesh.of(r);
      for (final blob in theirs(0x23)) {
        r.handleFrameForTest(_received(blob, 0xFF));
      }
      final photo = await row(r);
      expect(photo.heardDirect, isTrue);
      expect(photo.pathLength, 0);
    });

    test('a packet sent again fills the one that was lost, and one heard '
        'twice counts once', () async {
      final r = await radio((n, index) => false);
      PhotoMesh.of(r);
      final blobs = theirs(0x24);
      r.handleFrameForTest(_received(blobs[0], 0x42));
      r.handleFrameForTest(_received(blobs[2], 0x42));
      r.handleFrameForTest(_received(photoPacketAgain(blobs[0], 1), 0x42));
      r.handleFrameForTest(_repeated(photoPacketAgain(blobs[1], 2)));
      final photo = await row(r);
      expect(photo.text, contains('#24'));
      expect(photo.text, isNot(contains('incomplete')));
    });

    test('a packet of 0170, as MeshTrax 1.12.0 sent photos, is no photo',
        () async {
      final r = await radio((n, index) => false);
      PhotoMesh.of(r);
      final meta = const ImageStreamMetadata(
        rate: ImageCodecRatePoint.ft8,
      ).encode();
      r.handleFrameForTest(
        _received(
          [0xBE, 0xEF, 0x25, 0x01, meta, ...List.filled(120, 7)],
          0x41,
          dataType: 0x0170,
        ),
      );
      await pumpEventQueue(times: 200);
      final rows = await r.loadChannelMessagesFor(
        r.channels.firstWhere((c) => c.index == 1),
      );
      expect(rows.where(PhotoMesh.isPhotoMessage), isEmpty);
    });
  });

  group('on a MeshCore frequency, a photo through repeaters', () {
    final preset = meshCoreFrequenciesKhz.first;

    test('that no repeater carried gives back its time, when one was heard '
        'in the last minute', () async {
      final r = await radio((n, index) => false, freqKhz: preset);
      final bitstream = Uint8List.fromList(List.generate(450, (i) => i * 7));
      await PhotoMesh.of(r).sendPhoto(bitstream, 1, repairPacket: false);
      for (var i = 0; i < 40 && r.blobs.isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      await pumpEventQueue(times: 200);
      expect(
        photoLastSentViaRepeaters(r.selfPublicKeyHex),
        isNotNull,
        reason: 'counted once its first packet went',
      );
      await settled(r);
      expect(photoLastSentViaRepeaters(r.selfPublicKeyHex), isNull);
    });

    test('of one packet doesn\'t count', () async {
      final r = await radio((n, index) => true, freqKhz: preset);
      await send(r, bytes: 100);
      expect(photoLastSentViaRepeaters(r.selfPublicKeyHex), isNull);
    });

    test('keeps them when no repeater was heard in the last minute', () async {
      final r = await radio((n, index) => false, freqKhz: preset)
        ..heardThisMinute = false;
      await send(r);
      expect(photoLastSentViaRepeaters(r.selfPublicKeyHex), isNotNull);
    });

    test('keeps them when any repeater carried it, even a car repeater',
        () async {
      final r = await radio((n, index) => index == 0, freqKhz: preset)
        ..isCarRepeater = (hop, width) => true;
      await send(r);
      expect(photoLastSentViaRepeaters(r.selfPublicKeyHex), isNotNull);
    });

    test('zero hop doesn\'t count', () async {
      final r = await radio((n, index) => false, freqKhz: preset);
      await send(r, zeroHop: true);
      expect(photoLastSentViaRepeaters(r.selfPublicKeyHex), isNull);
    });
  });

  group('Subject only', () {
    test('a photo sent so carries its mark, and keeps where its subject is',
        () async {
      final r = await radio((n, index) => false);
      final bitstream = Uint8List.fromList(List.generate(300, (i) => i * 7));
      await PhotoMesh.of(r).sendPhoto(
        bitstream,
        1,
        subjectOnly: true,
        subjectBox: [0.2, 0.3, 0.7, 0.8],
        repairPacket: false,
      );
      await settled(r);
      final first = r.blobs.first;
      expect(first[5] & 0x80, isNot(0), reason: 'the photo byte has extras');
      expect(first.sublist(6, 8), [kPhotoItemSubjectOnly, 0]);
      final record = PhotoStore.instance.recordFor(
        (await photoRow(r)).messageId,
      )!;
      expect(record.subjectOnly, isTrue);
      expect(record.subjectBox, [0.2, 0.3, 0.7, 0.8]);
    });

    test('a photo received so is marked so', () async {
      final r = await radio((n, index) => false);
      PhotoMesh.of(r);
      final blobs = buildImageChunks(
        payload: photoPayload(
          Uint8List.fromList(List.generate(300, (i) => i * 3)),
          const PhotoExtras(subjectOnly: true),
        ),
        metadata: const ImageStreamMetadata(
          rate: ImageCodecRatePoint.ft8,
          hasExtras: true,
        ),
        senderPrefix: 0xBEEF,
        imgId: 0x31,
        parity: false,
      ).blobs;
      for (final blob in blobs) {
        r.handleFrameForTest(_received(blob, 0x41));
      }
      await pumpEventQueue(times: 200);
      final record = PhotoStore.instance.recordFor(
        (await photoRow(r)).messageId,
      )!;
      expect(record.subjectOnly, isTrue);
    });
  });

  group('with observers', () {
    final preset = meshCoreFrequenciesKhz.first;

    /// [r] with Check sends with observers on, as the user turns it on.
    Future<void> observe(_Radio r) async {
      await PrefsManager.instance.setBool('heard_check_enabled', true);
      await PrefsManager.instance.setString(
        'heard_check_server',
        'https://corescope.stonekitty.net',
      );
      HeardService.resetForTesting();
      HeardService.instance.attach(r);
      PhotoMesh.observerWaitOverride = const Duration(milliseconds: 300);
    }

    /// An observer heard this radio a moment ago, as it last sent.
    void earLately() => HeardService.instance.heardForTest(
      'earlier',
      const [Sighting(observer: 'Ridge')],
    );

    /// Observers hear packets [heard] (by index) of the photo going, a
    /// moment after each goes.
    void hearing(_Radio r, Set<int> heard) {
      r.onPacket = (n, index) {
        if (!heard.contains(index)) return;
        Timer(const Duration(milliseconds: 15), () {
          final id = PhotoMesh.sending.value.keys.single;
          HeardService.instance.heardForTest(
            HeardService.photoPacketId(id, index),
            [Sighting(observer: 'Ridge $index')],
          );
        });
      };
    }

    tearDown(() {
      HeardService.resetForTesting();
      PhotoMesh.observerWaitOverride = null;
    });

    test('a packet no repeater passed on that an observer heard doesn\'t go '
        'again, as a text doesn\'t; it puts the ear on the photo', () async {
      final r = await radio((n, index) => false);
      await observe(r);
      hearing(r, {1});
      final (row, _) = await send(r);
      expect(_indexes(r.blobs), [0, 0, 1, 2, 2]);
      expect(HeardService.instance.photoPacketsHeard(row.messageId), {1});
      expect(
        HeardService.instance.heardBy(row.messageId)!.map((s) => s.observer),
        ['Ridge 1'],
      );
    });

    test('a packet only one repeater carried goes no more where no observer '
        'heard this radio lately', () async {
      final r = await radio((n, index) => true);
      await observe(r);
      final steps = watchSteps();
      await send(r);
      expect(_indexes(r.blobs), [0, 1, 2]);
      expect(steps.map((s) => s.$1), isNot(contains(PhotoSendStep.observers)));
    });

    test('a packet only one repeater carried waits for the observers, then '
        'goes once more before the next, where none heard it and one heard '
        'this radio lately', () async {
      final r = await radio((n, index) => true);
      await observe(r);
      earLately();
      final steps = watchSteps();
      await send(r);
      expect(_indexes(r.blobs), [0, 0, 1, 1, 2, 2]);
      expect(_retries(r.blobs), [0, 1, 0, 1, 0, 1]);
      expect(steps.sublist(0, 4), [
        (PhotoSendStep.waiting, 0),
        (PhotoSendStep.sending, 1),
        (PhotoSendStep.observers, 1),
        (PhotoSendStep.again, 1),
      ]);
    });

    test('a packet an observer heard goes no more, though only one repeater '
        'carried it', () async {
      final r = await radio((n, index) => true);
      await observe(r);
      earLately();
      hearing(r, {0, 1, 2});
      await send(r);
      expect(_indexes(r.blobs), [0, 1, 2]);
    });

    test('two repeaters passed it on: the next goes without asking them',
        () async {
      final r = await radio((n, index) => true)
        ..path = const [0xA2, 0x77, 0xBE, 0xEF];
      await observe(r);
      earLately();
      final steps = watchSteps();
      final (row, _) = await send(r);
      expect(_indexes(r.blobs), [0, 1, 2]);
      expect(steps.map((s) => s.$1), isNot(contains(PhotoSendStep.observers)));
      expect(row.status, ChannelMessageStatus.delivered);
    });

    test('a photo is asked about by all its packets, as the server files them',
        () async {
      final r = await radio((n, index) => true);
      await observe(r);
      final (row, _) = await send(r);
      expect(HeardService.instance.hashesForTest(row.messageId), {
        for (final blob in r.blobs)
          channelDataPacketHash(channelKey: _psk, dataType: 0x0172, data: blob),
      });
    });

    test('a packet sent again is asked about under its own hash too',
        () async {
      final r = await radio((n, index) => false);
      await observe(r);
      final (row, _) = await send(r, bytes: 100);
      expect(_retries(r.blobs), [0, 1]);
      expect(HeardService.instance.hashesForTest(row.messageId), {
        for (final blob in r.blobs)
          channelDataPacketHash(channelKey: _psk, dataType: 0x0172, data: blob),
      });
      expect(HeardService.instance.hashesForTest(row.messageId), hasLength(2));
    });

    test('an observer that heard a photo no repeater carried keeps its 20 '
        'minutes', () async {
      final r = await radio((n, index) => false, freqKhz: preset);
      await observe(r);
      final bitstream = Uint8List.fromList(List.generate(450, (i) => i * 7));
      await PhotoMesh.of(r).sendPhoto(bitstream, 1, repairPacket: false);
      HeardService.instance.heardForTest(
        (await photoRow(r)).messageId,
        const [Sighting(observer: 'Ridge')],
      );
      await settled(r);
      expect(photoLastSentViaRepeaters(r.selfPublicKeyHex), isNotNull);
    });

    test('with no observer hearing it, it gives them back after their last '
        'answer', () async {
      final r = await radio((n, index) => false, freqKhz: preset);
      await observe(r);
      await send(r);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      expect(photoLastSentViaRepeaters(r.selfPublicKeyHex), isNull);
    });
  });

  group('lost packets asked for', () {
    final gather = PhotoMesh.askGather;
    final rest = PhotoMesh.askRest;
    final silence = PhotoMesh.askSilence;

    setUp(() {
      PhotoMesh.askGather = const Duration(milliseconds: 100);
      PackageInfo.setMockInitialValues(
        appName: 'MeshTrax',
        packageName: 'com.vena.meshtrax',
        version: '1.12.1',
        buildNumber: '252',
        buildSignature: '',
      );
    });

    tearDown(() {
      PhotoMesh.askGather = gather;
      PhotoMesh.askRest = rest;
      PhotoMesh.askSilence = silence;
    });

    /// A photo of 4 data packets and the repair packet, from BEEF.
    ImageChunkSet theirs(int imgId) => buildImageChunks(
      payload: Uint8List.fromList(List.generate(600, (i) => i * 3)),
      metadata: const ImageStreamMetadata(rate: ImageCodecRatePoint.ft8),
      senderPrefix: 0xBEEF,
      imgId: imgId,
      parity: true,
    );

    /// The photo packets [r] took, without its requests.
    List<Uint8List> photoPackets(_Radio r) => [
      for (var i = 0; i < r.blobs.length; i++)
        if (r.types[i] == 0x0172) r.blobs[i],
    ];

    /// Waits until [r] took [count] photo packets, or 5 seconds.
    Future<void> taken(_Radio r, int count) async {
      for (var i = 0; i < 100 && photoPackets(r).length < count; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(photoPackets(r), hasLength(count));
    }

    /// [asker] asks [asked] on Trip for packets [missing] of photo [imgId]
    /// of [total] data packets.
    void ask(
      _Radio r,
      int imgId,
      int missing, {
      int total = 4,
      int asker = 0xBEEF,
      int asked = 0x7777,
    }) {
      final request = ChannelRequest(
        kind: ChannelRequestKind.photoPackets,
        id: 9,
        asker: asker,
        asked: asked,
        build: 252,
        body: photoPacketsRequest(imgId: imgId, total: total, missing: missing),
      );
      r.handleFrameForTest(_received(request.encode(), 1, dataType: 0x0173));
    }

    test('a photo coming in shows how far it came; asking for the rest asks '
        'its sender for just the lost packets, with this build', () async {
      final r = await radio((n, index) => true);
      PhotoMesh.of(r);
      final photo = theirs(0x3a);
      r.handleFrameForTest(_received(photo.blobs[0], 1));
      await pumpEventQueue();
      var line = PhotoMesh.receiving.value.single;
      expect(line.senderName, 'Node beef');
      expect((line.received, line.total, line.lost, line.canAsk), (
        1,
        4,
        0,
        false,
      ));

      // Packet 4 came, so packets 2 and 3 were lost on the way.
      r.handleFrameForTest(_received(photo.blobs[3], 1));
      await pumpEventQueue();
      line = PhotoMesh.receiving.value.single;
      expect((line.received, line.lost, line.canAsk), (2, 2, true));

      expect(await PhotoMesh.of(r).askForRest(line.key), isTrue);
      final i = r.types.indexOf(0x0173);
      expect(r.paths[i], 0xFF);
      final request = ChannelRequest.decode(r.blobs[i])!;
      expect(request.kind, ChannelRequestKind.photoPackets);
      expect(request.build, 252);
      expect(request.asker, 0x7777);
      expect(request.asked, 0xBEEF);
      expect(readPhotoPacketsRequest(request.body), (
        imgId: 0x3a,
        total: 4,
        missing: 0x06,
      ));
      line = PhotoMesh.receiving.value.single;
      expect((line.canAsk, line.asked), (false, 2));
    });

    test('one packet missing is not lost while the repair packet may still '
        'rebuild it; after a silence it is', () async {
      PhotoMesh.askSilence = const Duration(milliseconds: 200);
      final r = await radio((n, index) => true);
      PhotoMesh.of(r);
      final photo = theirs(0x3a);
      r.handleFrameForTest(_received(photo.blobs[0], 1));
      r.handleFrameForTest(_received(photo.blobs[2], 1));
      await pumpEventQueue();
      expect(PhotoMesh.receiving.value.single.lost, 0);

      await Future<void>.delayed(const Duration(milliseconds: 300));
      // Any packet that comes shows the photos again: another photo's.
      r.handleFrameForTest(_received(theirs(0x3b).blobs[0], 1));
      await pumpEventQueue();
      final line = PhotoMesh.receiving.value.firstWhere(
        (l) => l.key.imgId == 0x3a,
      );
      expect((line.lost, line.canAsk), (2, true));
    });

    test('the sender sends just the packets asked for, each once, its retry '
        'byte counting the copies before; asked again within the rest, not '
        'again', () async {
      final r = await radio((n, index) => true);
      await send(r, bytes: 600);
      final sent = photoPackets(r);
      expect(_indexes(sent), [0, 1, 2, 3]);
      final imgId = sent[0][2];

      ask(r, imgId, 0x06);
      await taken(r, 6);
      final again = photoPackets(r).sublist(4);
      expect(_indexes(again), [1, 2]);
      expect(_retries(again), [1, 1]);
      expect(samePhotoPacket(again[0], sent[1]), isTrue);
      expect(r.paths.last, 0xFF);

      ask(r, imgId, 0x02);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(photoPackets(r), hasLength(6));
    });

    test('a photo goes again as asked at most 3 times, each copy one more '
        'in its retry byte', () async {
      PhotoMesh.askRest = Duration.zero;
      final r = await radio((n, index) => true);
      await send(r, bytes: 600);
      final imgId = photoPackets(r)[0][2];
      for (var round = 1; round <= 3; round++) {
        ask(r, imgId, 0x02);
        await taken(r, 4 + round);
      }
      ask(r, imgId, 0x02);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final again = photoPackets(r).sublist(4);
      expect(_indexes(again), [1, 1, 1]);
      expect(_retries(again), [1, 2, 3]);
    });

    test('a request the sender can\'t answer is left alone', () async {
      final r = await radio((n, index) => true);
      await send(r, bytes: 600);
      final imgId = photoPackets(r)[0][2];
      ask(r, imgId, 0x02, total: 5); // not this photo's count
      ask(r, (imgId + 1) & 0xFF, 0x02); // not a photo of mine
      ask(r, imgId, 0x02, asked: 0x1234); // asked of another node
      ask(r, imgId, 0x02, asker: 0x7777); // my own request heard back
      await Future<void>.delayed(const Duration(milliseconds: 600));
      expect(photoPackets(r), hasLength(4));
    });
  });
}
