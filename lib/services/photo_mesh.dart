import 'dart:async';
import 'dart:io' show File, Platform;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show MethodChannel;
import 'package:traxpix/traxpix.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/app_localizations.dart';
import '../models/channel_message.dart';
import '../utils/app_logger.dart';
import 'notification_service.dart';
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

  final MeshCoreConnector connector;
  ImageChunkTransport? _transport;
  ImageReassembler? _reassembler;
  int? _transportPrefix;
  late final StreamSubscription<Uint8List> _frames;

  /// The reassembler only gives up on a photo when the next chunk arrives,
  /// so this asks it every few seconds: an incomplete photo then shows about
  /// 60 s after its first chunk, even when nothing else comes in.
  late final Timer _sweep;

  PhotoMesh._(this.connector) {
    _frames = connector.receivedFrames.listen((frame) {
      _ensureTransport()?.handleFrame(frame);
    });
    // The radio's raw log too: there a photo sent through repeaters reaches
    // every radio along the way, not only the last. Chunks heard both ways
    // arrive twice, which the reassembler ignores.
    // A deleted photo message takes its picture and bytes with it.
    connector.onChannelMessageDeleted = (id) =>
        unawaited(PhotoStore.instance.forget(id));
    connector.onRawChannelData = (channelIndex, dataType, blob) {
      if (dataType != dataTypeMeshTraxPhoto) return;
      _ensureTransport();
      _reassembler?.addChunk(blob, channelIndex: channelIndex);
    };
    _sweep = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _reassembler?.evictExpired(),
    );
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
    final got = f.receivedDataChunks + (f.hadParity ? 1 : 0);
    return l10n.photo_incomplete(_id(f.key.imgId), got, f.total + 1);
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
      packetHash:
          'photo:${prefix.toRadixString(16)}:${r.key.imgId}:'
          '${DateTime.now().millisecondsSinceEpoch}',
    );
    if (messageId == null) return;
    await PhotoStore.instance.save(
      PhotoRecord(
        messageId: messageId,
        bytes: parts.bitstream.length,
        packets: r.chunkCount + 1,
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
      packetHash:
          'photo-incomplete:${prefix.toRadixString(16)}:${f.key.imgId}:'
          '${f.expiredAt.millisecondsSinceEpoch}',
      notify: false,
    );
  }

  /// Sends a coded photo as the channel sends its messages, or zero hop, with
  /// the sender's [tag] and [position] if any, and files it in the chat as
  /// ours, with the sender's preview as its picture (what the receivers will
  /// see).
  Future<void> sendPhoto(
    Uint8List bitstream,
    int channelIndex, {
    String? tag,
    PhotoPosition? position,
    bool zeroHop = false,
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
    await PhotoStore.instance.save(
      PhotoRecord(
        messageId: messageId,
        bytes: bitstream.length,
        packets: set.blobs.length,
        outgoing: true,
        tag: tagged,
        position: position,
      ),
      bitstream,
      png: previewPng,
    );
  }

  /// Sends a coded photo on [channelIndex], one chunk at a time, with its
  /// [extras] ahead of it: as a flood, the way the radio sends the channel's
  /// messages, or zero hop.
  Future<ImageChunkSet> send(
    Uint8List bitstream,
    int channelIndex, {
    PhotoExtras extras = const PhotoExtras(),
    bool zeroHop = false,
    void Function(ImageSendProgress)? onProgress,
  }) async {
    final transport = _ensureTransport();
    if (transport == null) {
      throw const PhotoSendException(PhotoSendFailure.notConnected);
    }
    final payload = photoPayload(bitstream, extras);
    final gap = photoGapFor(
      payload.length,
      zeroHop: zeroHop,
      airtimeMs: connector.estimatePacketAirtimeMs,
      shared: photoRulesApply(connector.currentFreqHz),
    );
    final sw = Stopwatch()..start();
    final set = await transport.sendImage(
      payload: payload,
      metadata: ImageStreamMetadata(
        rate: ImageCodecRatePoint.ft8,
        hasExtras: !extras.isEmpty,
      ),
      channelIndex: channelIndex,
      gap: gap,
      zeroHop: zeroHop,
      onProgress: onProgress,
    );
    _log(
      'sent ${bitstream.length} bytes on channel $channelIndex as '
      '${set.blobs.length} packets ${zeroHop ? 'zero hop' : 'as a flood'}, '
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
