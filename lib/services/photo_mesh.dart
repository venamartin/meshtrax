import 'dart:async';
import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:traxpix/traxpix.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/path_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/channel_message.dart';
import '../utils/app_logger.dart';
import 'notification_service.dart';
import 'photo_repeats.dart';
import 'photo_rules.dart';
import 'photo_store.dart';

/// Why a photo couldn't be sent.
enum PhotoSendFailure { notConnected, noAnswer, refused }

class PhotoSendException implements Exception {
  final PhotoSendFailure failure;

  /// The radio's error code, for [PhotoSendFailure.refused].
  final int? code;

  const PhotoSendException(this.failure, [this.code]);

  String text(AppLocalizations l10n) => switch (failure) {
    PhotoSendFailure.notConnected => l10n.photo_errorNotConnected,
    PhotoSendFailure.noAnswer => l10n.photo_errorNoAnswer,
    PhotoSendFailure.refused => l10n.photo_errorRefused(code ?? -1),
  };

  @override
  String toString() => 'PhotoSendException(${failure.name}, $code)';
}

/// Photos run the model with LiteRT, which MeshTrax takes for iOS, macOS and
/// 64-bit Arm Android only (packages/traxpix_litert). iPhones with less than
/// 4 GB of memory can't rebuild a photo, so they get none
/// ([checkPhotoMemory]).
bool get photosSupported => _platformRunsPhotos && _enoughMemory;

final bool _platformRunsPhotos =
    !kIsWeb &&
    (Platform.isIOS ||
        Platform.isMacOS ||
        (Platform.isAndroid && Platform.version.contains('android_arm64')));

bool _enoughMemory = true;

/// A 4 GB iPhone reports a little under 4 GB, a 3 GB one about 2.9.
const int _minPhoneMemoryBytes = 3500 * 1000 * 1000;

/// The phone's memory as it reports it, from [checkPhotoMemory]; null on a
/// Mac, or when it didn't say.
int? photoPhoneMemoryBytes;

/// A phone sold with 8 GB reports about 7.5 GB or more, a 6 GB one about 5.9.
const int _autoEnlargeMemoryBytes = 7000 * 1000 * 1000;

/// Whether this phone may enlarge a photo 4x by itself as it opens full
/// screen: only with 8 GB of memory or more. Others enlarge on a tap.
bool get photoAutoEnlargeAllowed =>
    (photoPhoneMemoryBytes ?? 0) >= _autoEnlargeMemoryBytes;

/// Asks the phone how much memory it has. Call once at launch, before
/// anything asks [photosSupported].
Future<void> checkPhotoMemory() async {
  if (!_platformRunsPhotos) return;
  try {
    if (Platform.isIOS) {
      photoPhoneMemoryBytes = await const MethodChannel('meshtrax/storage')
          .invokeMethod<int>('physicalMemory');
    } else if (Platform.isAndroid) {
      for (final line in File('/proc/meminfo').readAsLinesSync()) {
        if (line.startsWith('MemTotal:')) {
          photoPhoneMemoryBytes =
              int.parse(line.split(RegExp(r'\s+'))[1]) * 1024;
          break;
        }
      }
    }
  } on Object catch (_) {}
  final total = photoPhoneMemoryBytes;
  if (Platform.isIOS && total != null && total < _minPhoneMemoryBytes) {
    _enoughMemory = false;
  }
}

String _hex4(int prefix) => prefix.toRadixString(16).padLeft(4, '0');

/// Listens to the radio for photo packets, files photos in their channel's
/// chat, and sends photos. One per app run, made at launch.
class PhotoMesh {
  static PhotoMesh? _instance;

  static PhotoMesh of(MeshCoreConnector connector) =>
      _instance ??= PhotoMesh._(connector);

  /// A fresh one for the next [of], for tests with a connector of their own.
  @visibleForTesting
  static void resetForTest() {
    _instance?.dispose();
    _instance = null;
  }

  final MeshCoreConnector connector;
  ImageChunkTransport? _transport;
  ImageReassembler? _reassembler;
  int? _transportPrefix;
  late final StreamSubscription<Uint8List> _frames;

  /// The reassembler only gives up on a photo when the next chunk arrives,
  /// so this asks it every few seconds: an incomplete photo then shows about
  /// 60 s after its first chunk, even when nothing else comes in.
  late final Timer _sweep;

  /// Photos of mine sent through repeaters, by channel slot and image id,
  /// while this radio listens for repeaters passing their packets on.
  final Map<(int, int), PhotoRepeats> _sent = {};

  /// Writes of what was heard to chat rows and records, one at a time.
  Future<void> _writes = Future<void>.value();
  final Set<PhotoRepeats> _toWrite = {};

  PhotoMesh._(this.connector) {
    _frames = connector.receivedFrames.listen((frame) {
      final parsed = parseChannelDataFrame(frame);
      if (parsed == null || parsed.dataType != dataTypeMeshTraxPhoto) return;
      _ensureTransport();
      // Path length 0xFF: it came direct, which a photo does only zero hop.
      final hops = PathHelper.pathLenHops(parsed.pathLenByte);
      _reassembler?.addChunk(
        parsed.payload,
        channelIndex: parsed.channelIndex,
        hops: hops < 0 ? 0 : hops,
      );
    });
    // The radio's raw log too: there a photo sent through repeaters reaches
    // every radio along the way, not only the last. Chunks heard both ways
    // arrive twice, which the reassembler ignores. A copy of a packet of my
    // own is a repeater passing it on.
    // A deleted photo message takes its picture and bytes with it.
    connector.onChannelMessageDeleted = (id) =>
        unawaited(PhotoStore.instance.forget(id));
    connector.onRawChannelData = (channelIndex, dataType, blob, path, width) {
      if (dataType != dataTypeMeshTraxPhoto) return;
      _ensureTransport();
      final outcome = _reassembler?.addChunk(
        blob,
        channelIndex: channelIndex,
        hops: PathHelper.getHopCount(path, stride: width),
      );
      final header = outcome?.header;
      if (outcome?.status == ImageChunkStatus.fromSelf && header != null) {
        _heardOwnPacket(channelIndex, header, blob, path, width);
      }
    };
    _sweep = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _reassembler?.evictExpired(),
    );
  }

  /// A repeater passed on packet [header] of a photo of mine, heard as
  /// [blob]; [path] is the repeaters the copy came through. Its first
  /// repeater heard this radio directly, which Pathfinder hears of as of a
  /// channel text's echo, once per photo, and only for an exact copy: never
  /// that a packet was not passed on.
  void _heardOwnPacket(
    int channelIndex,
    ImageChunkHeader header,
    Uint8List blob,
    Uint8List path,
    int width,
  ) {
    final sent = _sent[(channelIndex, header.imgId)];
    if (sent == null || path.isEmpty) return;
    final carOnly = PathHelper.getHops(path, stride: width)
        .every((hop) => connector.isCarRepeater?.call(hop, width) == true);
    if (!sent.note(header.index, blob, path, width, carOnly: carOnly)) return;
    if (sent.firstThrough(path, width)) {
      connector.onOwnEchoHeard?.call(path, width);
    }
    _showRepeats(sent);
  }

  /// Puts what was heard of [sent] on its chat row and record, once it is
  /// filed. Writes go one at a time, each with the latest.
  void _showRepeats(PhotoRepeats sent) {
    if (sent.messageId == null || !_toWrite.add(sent)) return;
    _writes = _writes.then((_) async {
      _toWrite.remove(sent);
      final id = sent.messageId!;
      await PhotoStore.instance.notePassedOn(id, sent.passedOnCount);
      await connector.recordOwnRepeats(
        id,
        copies: sent.copies,
        paths: sent.paths,
        pathHashSize: sent.pathHashSize,
        delivered: sent.complete,
      );
    }).catchError((Object e) => _log('could not note the repeats: $e'));
  }

  /// Whether packet [index] of photo [imgId] goes out once more: no
  /// repeater was heard passing it on, though one was heard lately, and
  /// channel retries aren't off (see [PhotoRepeats.sendAgain]).
  bool _sendAgain(PhotoRepeats sent, int imgId, int index) {
    if (connector.channelRetries == 0 ||
        !connector.repeaterHeardRecently ||
        !sent.sendAgain(index)) {
      return false;
    }
    _log(
      'no repeater was heard passing on packet ${index + 1} of '
      '${sent.packets} of ${_id(imgId)}: sending it again',
    );
    return true;
  }

  /// The wait after the last packet of photo [key] is over: what was heard
  /// stays as it is, and its row stops waiting.
  void _stopListening((int, int) key) {
    final sent = _sent.remove(key);
    if (sent == null) return;
    _log(
      'repeaters passed on ${sent.passedOnCount} of ${sent.packets} packets '
      'of ${_id(key.$2)}; copies heard: ${sent.copies}',
    );
    _giveBackIfNotCarried(sent, key.$2);
    final id = sent.messageId;
    if (id == null) return;
    _showRepeats(sent);
    _writes = _writes.then(
      (_) => connector.waitForRepeats(id, waiting: false),
    );
  }

  /// Where the photo rules apply, a photo no repeater was heard carrying at
  /// all, not even a car repeater or a packet sent again, gives back its 30
  /// minutes when a repeater was heard in the last minute: this radio hears
  /// repeaters, so none carried it. The 10 minutes stay.
  void _giveBackIfNotCarried(PhotoRepeats sent, int imgId) {
    final counted = sent.counted;
    if (counted == null ||
        sent.copies > 0 ||
        !connector.repeaterHeardWithin(photoUncarriedRepeaterWindow)) {
      return;
    }
    _log(
      'no repeater carried ${_id(imgId)}, and one was heard in the last '
      'minute: its 30 minutes are given back',
    );
    unawaited(notePhotoNotCarried(counted.radio, counted.at));
  }

  /// The app's language, for the chat lines photos are filed as.
  static AppLocalizations get _l10n =>
      lookupAppLocalizations(NotificationService().locale);

  static String _id(int imgId) => '#${imgId.toRadixString(16).padLeft(2, '0')}';

  /// What the chat shows for a photo that didn't arrive whole: quietly, with
  /// no retry and nothing partial. Counts the repair packet, which MeshTrax
  /// always sends, as the senders' screen does. The photo's id keeps two such
  /// lines from one sender apart (see [_text]).
  static String incompleteText(
    AppLocalizations l10n,
    ImageReassemblyFailure f,
  ) {
    if (f.isCorrupt) return l10n.photo_needsNewer(_id(f.key.imgId));
    // The repair packet is the sender's choice, so it counts once it came.
    final repair = f.hadParity ? 1 : 0;
    return l10n.photo_incomplete(
      _id(f.key.imgId),
      f.receivedDataChunks + repair,
      f.total + repair,
    );
  }

  /// Companion firmware 1.15 (version code 11) added channel datagrams.
  bool get radioSupportsPhotos => (connector.firmwareVerCode ?? 0) >= 11;

  ImageChunkTransport? _ensureTransport() {
    final prefix = senderPrefixFromKey(connector.selfPublicKey);
    if (prefix == null) return null;
    if (_transport == null || _transportPrefix != prefix) {
      _transportPrefix = prefix;
      _transport = ImageChunkTransport(
        send: _sendFrame,
        senderPrefix: prefix,
        reassembler: _reassembler = ImageReassembler(
          selfPrefix: prefix,
          onImage: (r) {
            unawaited(_fileReceived(r));
            _log(
              'received from ${_hex4(r.key.senderPrefix)} on channel '
              '${r.key.channelIndex}: ${r.data.length} bytes, '
              '${r.chunkCount} chunks'
              '${r.recoveredWithParity ? ', one lost chunk rebuilt from the repair chunk' : ''}',
            );
          },
          onFailed: (f) {
            unawaited(_fileIncomplete(f));
            _log(
              'incomplete photo from ${_hex4(f.key.senderPrefix)}: '
              '${f.receivedDataChunks} of ${f.total} data chunks'
              '${f.hadParity ? ' plus the repair chunk' : ''} (${f.reason.name})',
            );
          },
        ),
      );
    }
    return _transport;
  }

  Future<void> _sendFrame(Uint8List frame) async {
    final reply = await connector.sendAndAwaitReply(frame);
    if (reply == null) {
      throw const PhotoSendException(PhotoSendFailure.noAnswer);
    }
    if (reply[0] != respCodeOk) {
      throw PhotoSendException(
        PhotoSendFailure.refused,
        reply.length > 1 ? reply[1] : null,
      );
    }
  }

  /// The contact whose public key starts with [prefix], else "Node xxxx".
  String _senderName(int prefix) {
    for (final c in connector.contacts) {
      if (senderPrefixFromKey(c.publicKey) == prefix) return c.name;
    }
    return _l10n.photo_unknownSender(_hex4(prefix));
  }

  /// Whether a chat message is a photo's entry: its packet hash says so, in
  /// any language (see [_fileReceived] and [sendPhoto]).
  static bool isPhotoMessage(ChannelMessage message) =>
      message.packetHash?.startsWith('photo:') ?? false;

  /// "📷 Photo #3a": the photo's own id keeps two photos from one sender
  /// within five minutes from being merged as one message heard twice.
  static String _text(int imgId, String? tag) => tag == null
      ? _l10n.photo_message(_id(imgId))
      : _l10n.photo_messageWithTag(_id(imgId), tag);

  /// Files a received photo in its channel's chat.
  Future<void> _fileReceived(ImageReassemblyResult r) async {
    final prefix = r.key.senderPrefix;
    final sender = _senderName(prefix);
    // A blocked sender's photos are not kept at all, not just hidden.
    if (connector.isSenderBlocked(sender)) {
      _log('dropped a photo from blocked $sender');
      return;
    }
    final parts = photoPayloadParts(
      r.data,
      hasExtras: r.metadata?.hasExtras ?? false,
    );
    if (parts == null || parts.needsNewerApp) {
      await connector.ingestPhotoMessage(
        channelIndex: r.key.channelIndex,
        senderName: sender,
        text: parts == null
            ? _l10n.photo_unreadable(_id(r.key.imgId))
            : _l10n.photo_needsNewer(_id(r.key.imgId)),
        isOutgoing: false,
        hops: r.fewestHops,
        packetHash:
            'photo-unreadable:${prefix.toRadixString(16)}:${r.key.imgId}:'
            '${DateTime.now().millisecondsSinceEpoch}',
        notify: false,
      );
      return;
    }
    final messageId = await connector.ingestPhotoMessage(
      channelIndex: r.key.channelIndex,
      senderName: sender,
      text: _text(r.key.imgId, parts.extras.tag),
      isOutgoing: false,
      hops: r.fewestHops,
      packetHash:
          'photo:${prefix.toRadixString(16)}:${r.key.imgId}:'
          '${DateTime.now().millisecondsSinceEpoch}',
    );
    if (messageId == null) return;
    await PhotoStore.instance.save(
      PhotoRecord(
        messageId: messageId,
        bytes: parts.bitstream.length,
        packets: r.chunkCount + (r.recoveredWithParity ? 1 : 0),
        outgoing: false,
        recoveredWithParity: r.recoveredWithParity,
        tag: parts.extras.tag,
        position: parts.extras.position,
      ),
      parts.bitstream,
    );
    if (PhotoStore.instance.rebuildAutomatically) {
      PhotoStore.instance.rebuildAutomaticallyWhenInFront(messageId);
    }
  }

  /// Files a photo that didn't arrive whole in its channel's chat, quietly.
  Future<void> _fileIncomplete(ImageReassemblyFailure f) async {
    final prefix = f.key.senderPrefix;
    final sender = _senderName(prefix);
    if (connector.isSenderBlocked(sender)) return;
    await connector.ingestPhotoMessage(
      channelIndex: f.key.channelIndex,
      senderName: sender,
      text: incompleteText(_l10n, f),
      isOutgoing: false,
      hops: f.fewestHops,
      packetHash:
          'photo-incomplete:${prefix.toRadixString(16)}:${f.key.imgId}:'
          '${f.expiredAt.millisecondsSinceEpoch}',
      notify: false,
    );
  }

  /// Sends a coded photo as the channel sends its messages, or zero hop, with
  /// the sender's [tag] and [position] if any and a repair packet if
  /// [repairPacket], and files it in the chat as ours, with the sender's
  /// preview as its picture (what the receivers will see). Sent through
  /// repeaters, its row shows Delivered once a repeater was heard passing on
  /// every packet the receivers need.
  Future<void> sendPhoto(
    Uint8List bitstream,
    int channelIndex, {
    String? tag,
    PhotoPosition? position,
    bool zeroHop = false,
    bool repairPacket = true,
    Uint8List? previewPng,
    void Function(ImageSendProgress)? onProgress,
  }) async {
    final extras = PhotoExtras(tag: tag, position: position);
    final tagged = extras.sentTag;
    final set = await send(
      bitstream,
      channelIndex,
      extras: extras,
      zeroHop: zeroHop,
      repairPacket: repairPacket,
      onProgress: onProgress,
    );
    final messageId = await connector.ingestPhotoMessage(
      channelIndex: channelIndex,
      senderName: connector.selfName ?? 'Me',
      text: _text(set.imgId, tagged),
      isOutgoing: true,
      packetHash:
          'photo:own:${set.imgId}:${DateTime.now().millisecondsSinceEpoch}',
    );
    if (messageId == null) return;
    final key = (channelIndex, set.imgId);
    final sent = _sent[key];
    // Before the record, so the row never shows unheard while it waits.
    if (sent != null) connector.waitForRepeats(messageId, waiting: true);
    await PhotoStore.instance.save(
      PhotoRecord(
        messageId: messageId,
        bytes: bitstream.length,
        packets: set.blobs.length,
        outgoing: true,
        tag: tagged,
        position: position,
        packetsPassedOn: sent?.passedOnCount,
      ),
      bitstream,
      png: previewPng,
    );
    if (sent != null) {
      sent.messageId = messageId;
      _showRepeats(sent);
      // The wait may have run out while the record was written.
      if (!_sent.containsKey(key)) {
        _writes = _writes.then(
          (_) => connector.waitForRepeats(messageId, waiting: false),
        );
      }
    }
  }

  /// Sends a coded photo on [channelIndex], one chunk at a time, with its
  /// [extras] ahead of it and the repair chunk last if [repairPacket]: as a
  /// flood, the way the radio sends the channel's messages, or zero hop: always
  /// on a Nearby only channel.
  ///
  /// Through repeaters, this radio then listens for them passing each
  /// packet on, until [MeshCoreConnector.channelRepeatWait] after the last.
  /// A packet no repeater was heard passing on goes once more, the same
  /// bytes, when the gap leaves time to hear one ([photoRepeatHeardWithin]).
  ///
  /// Where the photo rules apply ([photoRulesApply]), the photo counts
  /// against them once its packets are handed over ([notePhotoSent]).
  Future<ImageChunkSet> send(
    Uint8List bitstream,
    int channelIndex, {
    PhotoExtras extras = const PhotoExtras(),
    bool zeroHop = false,
    bool repairPacket = true,
    void Function(ImageSendProgress)? onProgress,
  }) async {
    final transport = _ensureTransport();
    if (transport == null) {
      throw const PhotoSendException(PhotoSendFailure.notConnected);
    }
    // A Nearby only channel sends every photo zero hop, whatever was asked.
    final goesZeroHop = zeroHop || connector.isNearbyOnlyChannel(channelIndex);
    final payload = photoPayload(bitstream, extras);
    final airtimeMs = connector.estimatePacketAirtimeMs;
    final gap = photoGapFor(
      payload.length,
      zeroHop: goesZeroHop,
      repairPacket: repairPacket,
      airtimeMs: airtimeMs,
      shared: photoRulesApply(connector.currentFreqHz),
    );
    final chunks = transport.chunk(
      payload: payload,
      metadata: ImageStreamMetadata(
        rate: ImageCodecRatePoint.ft8,
        hasExtras: !extras.isEmpty,
      ),
      parity: repairPacket,
    );
    final imgId = chunks.imgId;
    final key = (channelIndex, imgId);
    final sent = goesZeroHop
        ? null
        : PhotoRepeats(blobs: chunks.blobs, hasRepair: chunks.hasParity);
    if (sent != null) _sent[key] = sent;
    final airtime = Duration(milliseconds: airtimeMs(kPhotoPacketAirBytes));
    final hearsInTime = gap >= photoRepeatHeardWithin(airtime);
    final sw = Stopwatch()..start();
    final set = await transport.sendChunks(
      chunks,
      channelIndex: channelIndex,
      gap: gap,
      zeroHop: goesZeroHop,
      resend: sent != null && hearsInTime
          ? (i) => _sendAgain(sent, imgId, i)
          : null,
      onProgress: onProgress,
      onDone: sent == null
          ? null
          : () => Timer(
              MeshCoreConnector.channelRepeatWait,
              () => _stopListening(key),
            ),
    );
    if (photoRulesApply(connector.currentFreqHz)) {
      final counted = (radio: connector.selfPublicKeyHex, at: DateTime.now());
      await notePhotoSent(
        counted.radio,
        counted.at,
        viaRepeaters: !goesZeroHop,
      );
      sent?.counted = counted;
    }
    _log(
      'sent ${bitstream.length} bytes on channel $channelIndex as '
      '${set.blobs.length} packets '
      '${goesZeroHop ? 'zero hop' : 'as a flood'}, '
      '${gap.inMilliseconds} ms apart, in ${sw.elapsedMilliseconds} ms',
    );
    return set;
  }

  void _log(String line) => appLogger.info(line, tag: 'Photos');

  void dispose() {
    _frames.cancel();
    _sweep.cancel();
  }
}
