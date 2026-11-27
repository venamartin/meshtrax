import 'dart:async';
import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show ValueNotifier, kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:traxpix/traxpix.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/path_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/channel.dart';
import '../models/channel_datagram.dart';
import '../models/channel_message.dart';
import '../utils/app_logger.dart';
import 'heard_service.dart';
import 'notification_service.dart';
import 'photo_reassembler.dart';
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

  /// Why the chat couldn't send a packet of the photo.
  factory PhotoSendException.from(ChannelPacketsFailed why) =>
      why.errorCode != null
      ? PhotoSendException(PhotoSendFailure.refused, why.errorCode)
      : PhotoSendException(
          why.connected
              ? PhotoSendFailure.noAnswer
              : PhotoSendFailure.notConnected,
        );

  String text(AppLocalizations l10n) => switch (failure) {
    PhotoSendFailure.notConnected => l10n.photo_errorNotConnected,
    PhotoSendFailure.noAnswer => l10n.photo_errorNoAnswer,
    PhotoSendFailure.refused => l10n.photo_errorRefused(code ?? -1),
  };

  @override
  String toString() => 'PhotoSendException(${failure.name}, $code)';
}

/// What a photo of mine is doing while its packets go, for its chat row.
enum PhotoSendStep {
  /// It waits for the photo of mine before it to be done.
  waiting,

  /// Its packet goes, and is listened for.
  sending,

  /// Its packet goes again.
  again,

  /// One repeater passed its packet on: the observers are asked whether they
  /// heard it.
  observers,

  /// It couldn't be sent.
  failed,
}

/// [step] on [packet] of [packets] (from 1; the repair packet if [repair]),
/// and for a photo that failed, why.
typedef PhotoSendState = ({
  PhotoSendStep step,
  int packet,
  int packets,
  bool repair,
  Object? error,
});

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

/// Files received photos in their channel's chat, and hands the chat the
/// photos of mine to send: traxpix makes the packets and rebuilds photos
/// from them, the chat sends them ([MeshCoreConnector.sendChannelPackets]).
/// One per app run, made at launch.
class PhotoMesh {
  static PhotoMesh? _instance;

  static PhotoMesh of(MeshCoreConnector connector) =>
      _instance ??= PhotoMesh._(connector);

  /// A fresh one for the next [of], for tests with a connector of their own.
  @visibleForTesting
  static void resetForTest() {
    _instance?.dispose();
    _instance = null;
    sending.value = const {};
  }

  /// The photos of mine whose packets are still going, by chat row, with
  /// what each is doing. One that failed stays, to say why.
  static final ValueNotifier<Map<String, PhotoSendState>> sending =
      ValueNotifier(const {});

  final MeshCoreConnector connector;
  ImageReassembler? _reassembler;
  int? _reassemblerPrefix;
  late final StreamSubscription<ChannelDatagram> _datagrams;
  final ImageIdAllocator _ids = ImageIdAllocator();

  /// The reassembler only gives up on a photo when the next packet arrives,
  /// so this asks it every few seconds: an incomplete photo then shows
  /// [photoReceiveWindow] after its first packet, even when nothing else
  /// comes in.
  late final Timer _sweep;

  /// How long after its last packet went a photo through repeaters that no
  /// repeater carried waits for the observers' last answer before its time
  /// is given back; tests shorten it.
  @visibleForTesting
  static Duration? observerWaitOverride;

  /// Photos of mine handed to the chat and not done with yet.
  int _going = 0;

  bool _disposed = false;

  /// Whether a photo of mine still goes or is listened for; tests wait it
  /// out.
  @visibleForTesting
  bool get busy => _going > 0;

  /// Writes of what was heard to chat rows and records, one at a time.
  Future<void> _writes = Future<void>.value();
  final Set<PhotoRepeats> _toWrite = {};

  PhotoMesh._(this.connector) {
    _datagrams = connector.channelDatagrams.listen((d) {
      if (!isMeshTraxPhotoDataType(d.dataType)) return;
      // Path length 0xFF: it came direct, which a photo does only zero hop.
      final hops = PathHelper.pathLenHops(d.pathLen);
      _ensureReassembler()?.addChunk(
        d.payload,
        dataType: d.dataType,
        channelIndex: d.channel.index,
        hops: hops < 0 ? 0 : hops,
      );
    });
    // The radio's raw log too: there a photo sent through repeaters reaches
    // every radio along the way, not only the last. Packets heard both ways
    // arrive twice, which the reassembler ignores. The chat takes copies of
    // packets of mine it's still listening for before they get here.
    connector.onRawChannelData = (channelIndex, dataType, blob, path, width) {
      if (!isMeshTraxPhotoDataType(dataType)) return;
      _ensureReassembler()?.addChunk(
        blob,
        dataType: dataType,
        channelIndex: channelIndex,
        hops: PathHelper.getHopCount(path, stride: width),
      );
    };
    // A deleted photo message takes its picture and bytes with it.
    connector.onChannelMessageDeleted = (id) =>
        unawaited(PhotoStore.instance.forget(id));
    _sweep = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _reassembler?.evictExpired(),
    );
  }

  /// A repeater passed on packet [index] of photo [sent] of mine, heard
  /// through [path]. Its first repeater heard this radio directly, which
  /// Pathfinder hears of as of a channel text's echo, once per photo per
  /// first repeater: never that a packet was not passed on.
  void _heardOwnPacket(
    PhotoRepeats sent,
    int index,
    Uint8List path,
    int width,
  ) {
    // Repeaters count by their codes, over every repeater in the path, as
    // for a channel text's copies; one that moves with the user doesn't.
    final repeaters = {
      for (final hop in PathHelper.getHops(path, stride: width))
        if (connector.isCarRepeater?.call(hop, width) != true)
          PathHelper.hopHex(hop),
    };
    sent.note(index, path, width, repeaters: repeaters);
    if (sent.firstThrough(path, width)) {
      connector.onOwnEchoHeard?.call(path, width);
    }
    _showRepeats(sent);
  }

  /// Puts what was heard of [sent] on its chat row and record. Writes go one
  /// at a time, each with the latest.
  void _showRepeats(PhotoRepeats sent) {
    if (!_toWrite.add(sent)) return;
    _writes = _writes.then((_) async {
      _toWrite.remove(sent);
      final id = sent.messageId;
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

  /// Where the photo rules apply, a photo through repeaters that no repeater
  /// was heard carrying at all, not even a car repeater or a packet sent
  /// again, gives back its time ([photoGapRepeaters]) when a repeater was
  /// heard in the last minute: this radio hears repeaters, so none carried
  /// it. Where observers are asked about it, only once their last answer is
  /// in, and only if none heard it.
  void _giveBackIfNotCarried(PhotoRepeats sent, int imgId) {
    final counted = sent.counted;
    if (counted == null ||
        sent.copies > 0 ||
        !connector.repeaterHeardWithin(photoUncarriedRepeaterWindow)) {
      return;
    }
    void giveBack() {
      if (HeardService.instance.heardBy(sent.messageId)?.isNotEmpty ?? false) {
        _log('an observer heard ${_id(imgId)}: its time through repeaters stays');
        return;
      }
      _log(
        'no repeater carried ${_id(imgId)}, and one was heard in the last '
        'minute: its time through repeaters is given back',
      );
      unawaited(notePhotoNotCarried(counted.radio, counted.at));
    }

    final last = sent.lastSentAt;
    if (last == null || !HeardService.instance.asksAboutPhoto(sent.messageId)) {
      giveBack();
      return;
    }
    final wait = last
        .add(
          observerWaitOverride ??
              HeardService.instance.lastAsk + const Duration(seconds: 5),
        )
        .difference(DateTime.now());
    Timer(wait.isNegative ? Duration.zero : wait, giveBack);
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

  /// The reassembler for this radio's own sender prefix, made again when the
  /// radio changes; null while the radio's key is unknown.
  ImageReassembler? _ensureReassembler() {
    final prefix = senderPrefixFromKey(connector.selfPublicKey);
    if (prefix == null) return null;
    if (_reassembler == null || _reassemblerPrefix != prefix) {
      _reassemblerPrefix = prefix;
      _reassembler = ImageReassembler(
        selfPrefix: prefix,
        onImage: (r) {
          unawaited(_fileReceived(r));
          _log(
            'received from ${_hex4(r.key.senderPrefix)} on channel '
            '${r.key.channelIndex}: ${r.data.length} bytes, '
            '${r.chunkCount} packets'
            '${r.recoveredWithParity ? ', one lost packet rebuilt from the repair packet' : ''}',
          );
        },
        onFailed: (f) {
          unawaited(_fileIncomplete(f));
          _log(
            'incomplete photo from ${_hex4(f.key.senderPrefix)}: '
            '${f.receivedDataChunks} of ${f.total} data packets'
            '${f.hadParity ? ' plus the repair packet' : ''} (${f.reason.name})',
          );
        },
      );
    }
    return _reassembler;
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
        subjectOnly: parts.extras.subjectOnly,
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

  /// Files a coded photo in the chat as mine, with the sender's preview as
  /// its picture (what the receivers will see), and hands its packets to the
  /// chat to send ([MeshCoreConnector.sendChannelPackets]): as the channel
  /// sends its messages, or zero hop (always on a Nearby only channel), with
  /// the sender's [tag] and [position] if any and a repair packet if
  /// [repairPacket]. Returns once the photo is in the chat; [sending] says
  /// how its packets go. Sent through repeaters, its row shows Delivered
  /// once a repeater was heard passing on every packet the receivers need.
  Future<void> sendPhoto(
    Uint8List bitstream,
    int channelIndex, {
    String? tag,
    PhotoPosition? position,
    bool subjectOnly = false,
    List<double>? subjectBox,
    bool zeroHop = false,
    bool repairPacket = true,
    Uint8List? previewPng,
  }) async {
    final prefix = senderPrefixFromKey(connector.selfPublicKey);
    final channel = connector.channels
        .where((c) => c.index == channelIndex)
        .firstOrNull;
    if (prefix == null || channel == null || !connector.isConnected) {
      throw const PhotoSendException(PhotoSendFailure.notConnected);
    }
    final extras = PhotoExtras(
      tag: tag,
      position: position,
      subjectOnly: subjectOnly,
    );
    final goesZeroHop = zeroHop || connector.isNearbyOnlyChannel(channelIndex);
    final payload = photoPayload(bitstream, extras);
    final chunks = buildImageChunks(
      payload: payload,
      metadata: ImageStreamMetadata(
        rate: ImageCodecRatePoint.ft8,
        hasExtras: !extras.isEmpty,
      ),
      senderPrefix: prefix,
      imgId: _ids.next(),
      parity: repairPacket,
    );
    final senderName = connector.selfName ?? 'Me';
    final messageId = await connector.ingestPhotoMessage(
      channelIndex: channelIndex,
      senderName: senderName,
      text: _text(chunks.imgId, extras.sentTag),
      isOutgoing: true,
      packetHash:
          'photo:own:${chunks.imgId}:${DateTime.now().millisecondsSinceEpoch}',
      messageId: _ownRowId(DateTime.now(), senderName, chunks.imgId),
    );
    if (messageId == null) return;
    // Before the record, so the row never shows unheard while it goes.
    connector.waitForRepeats(messageId, waiting: true);
    _say(messageId, PhotoSendStep.waiting);
    await PhotoStore.instance.save(
      PhotoRecord(
        messageId: messageId,
        bytes: bitstream.length,
        packets: chunks.blobs.length,
        outgoing: true,
        tag: extras.sentTag,
        position: position,
        packetsPassedOn: goesZeroHop ? null : 0,
        subjectOnly: subjectOnly,
        subjectBox: subjectBox,
      ),
      bitstream,
      png: previewPng,
    );
    final gap = photoGapFor(
      payload.length,
      zeroHop: goesZeroHop,
      repairPacket: repairPacket,
      airtimeMs: connector.estimatePacketAirtimeMs,
      shared: photoRulesApply(connector.currentFreqHz),
    );
    _going++;
    unawaited(
      _send(channel, chunks, messageId, gap, zeroHop: goesZeroHop).whenComplete(
        () => _going--,
      ),
    );
  }

  /// The id the chat row of photo [imgId] of mine gets: unique as any row's
  /// id is ([ChannelMessage.messageId]), from the time, the sender and the
  /// photo. The chat sends its packets under it, and the observer server is
  /// asked about them by it.
  static String _ownRowId(DateTime at, String sender, int imgId) =>
      '${at.millisecondsSinceEpoch}_${sender.hashCode}_photo'
      '${imgId.toRadixString(16)}';

  /// What photo [messageId] of mine is doing, for its chat row.
  static void _say(
    String messageId,
    PhotoSendStep step, {
    int packet = 0,
    int packets = 0,
    bool repair = false,
    Object? error,
  }) {
    sending.value = {
      ...sending.value,
      messageId: (
        step: step,
        packet: packet,
        packets: packets,
        repair: repair,
        error: error,
      ),
    };
  }

  /// Hands photo [chunks], filed as [messageId] on [channel], to the chat,
  /// which sends its packets one at a time on a channel message's terms; a
  /// packet sent again has its retry byte bumped ([photoPacketAgain]), so
  /// every repeater passes it on, and goes only while the receivers keep the
  /// rest ([photoReceiveWindow]). Says on the row what each packet does,
  /// notes the copies repeaters passed on, and once the chat stops listening
  /// for them, leaves the row as it is.
  Future<void> _send(
    Channel channel,
    ImageChunkSet chunks,
    String messageId,
    Duration gap, {
    required bool zeroHop,
  }) async {
    final packets = chunks.blobs.length;
    final sent = zeroHop
        ? null
        : PhotoRepeats(
            packets: packets,
            hasRepair: chunks.hasParity,
            messageId: messageId,
          );
    final sw = Stopwatch();
    try {
      await connector.sendChannelPackets(
        channel: channel,
        groupId: messageId,
        dataType: dataTypeMeshTraxPhoto,
        packets: chunks.blobs,
        again: photoPacketAgain,
        same: samePhotoPacket,
        gap: gap,
        zeroHop: zeroHop,
        againWithin: photoReceiveWindow * 0.75,
        onPacket: (index, step) {
          if (_disposed) return;
          final repair = chunks.hasParity && index == packets - 1;
          switch (step) {
            case ChannelPacketStep.sending || ChannelPacketStep.again:
              if (index == 0 && step == ChannelPacketStep.sending) {
                sw.start();
                if (sent != null) unawaited(_count(sent));
              }
              sent?.lastSentAt = DateTime.now();
              _say(
                messageId,
                step == ChannelPacketStep.sending
                    ? PhotoSendStep.sending
                    : PhotoSendStep.again,
                packet: index + 1,
                packets: packets,
                repair: repair,
              );
            case ChannelPacketStep.waiting:
              _say(
                messageId,
                PhotoSendStep.observers,
                packet: index + 1,
                packets: packets,
                repair: repair,
              );
            case ChannelPacketStep.done:
              if (index == packets - 1) {
                sending.value = Map.of(sending.value)..remove(messageId);
                _log(
                  'sent ${_id(chunks.imgId)} on channel ${channel.index} as '
                  '$packets packets ${zeroHop ? 'zero hop' : 'as a flood'}, '
                  '${gap.inMilliseconds} ms apart or more, in '
                  '${sw.elapsedMilliseconds} ms',
                );
              }
          }
        },
        onCopy: sent == null
            ? null
            : (index, path, width) => _heardOwnPacket(sent, index, path, width),
      );
    } on ChannelPacketsFailed catch (why) {
      _log('could not send ${_id(chunks.imgId)}: $why');
      _say(messageId, PhotoSendStep.failed, error: PhotoSendException.from(why));
      await connector.failOwnSend(messageId);
      connector.waitForRepeats(messageId, waiting: false);
      return;
    }
    if (_disposed) return;
    if (sent == null) {
      connector.waitForRepeats(messageId, waiting: false);
      return;
    }
    _log(
      'repeaters passed on ${sent.passedOnCount} of $packets packets of '
      '${_id(chunks.imgId)}; copies heard: ${sent.copies}',
    );
    _giveBackIfNotCarried(sent, chunks.imgId);
    _showRepeats(sent);
    _writes = _writes.then(
      (_) => connector.waitForRepeats(messageId, waiting: false),
    );
  }

  /// Where the photo rules apply ([photoRulesApply]), a photo through
  /// repeaters of more than one packet counts against them from its first
  /// packet ([notePhotoSent]).
  Future<void> _count(PhotoRepeats sent) async {
    if (!photoRulesApply(connector.currentFreqHz) ||
        photoGapRepeaters(sent.packets) <= Duration.zero) {
      return;
    }
    final counted = (radio: connector.selfPublicKeyHex, at: DateTime.now());
    sent.counted = counted;
    await notePhotoSent(counted.radio, counted.at, packets: sent.packets);
  }

  void _log(String line) => appLogger.info(line, tag: 'Photos');

  void dispose() {
    _disposed = true;
    _datagrams.cancel();
    _sweep.cancel();
  }
}
