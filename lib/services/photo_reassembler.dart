import 'dart:typed_data';

import 'package:traxpix/traxpix.dart';

/// How long a receiver keeps the packets of a photo, from its first, for the
/// rest to come. A sender sends a photo's packets one at a time, each under a
/// channel message's rules, so a photo with lost packets can take minutes.
/// MeshTrax 1.12.0 kept them for 60 s.
const Duration photoReceiveWindow = Duration(minutes: 20);

/// Identity of one photo being received.
class ImageStreamKey {
  final int senderPrefix;
  final int imgId;
  final int channelIndex;

  const ImageStreamKey({
    required this.senderPrefix,
    required this.imgId,
    required this.channelIndex,
  });

  @override
  bool operator ==(Object other) =>
      other is ImageStreamKey &&
      other.senderPrefix == senderPrefix &&
      other.imgId == imgId &&
      other.channelIndex == channelIndex;

  @override
  int get hashCode => Object.hash(senderPrefix, imgId, channelIndex);

  @override
  String toString() =>
      'ImageStreamKey(0x'
      '${senderPrefix.toRadixString(16).padLeft(4, '0')}/$imgId@$channelIndex)';
}

/// What happened to a single received packet.
enum ImageChunkStatus {
  /// Not a well-formed photo packet; ignored.
  malformed,

  /// It bears this radio's own sender prefix: one of its own photos.
  fromSelf,

  /// Stored; the photo is still incomplete.
  accepted,

  /// Already had this packet; ignored.
  duplicate,

  /// Conflicted with what was held for this photo (a different `total`, or a
  /// different body for the same index). The photo was started again from
  /// this packet.
  conflicting,

  /// Every packet came, but packet 0's metadata byte names a format this
  /// build cannot read ([ImageStreamMetadata.decode]).
  unsupportedFormat,

  /// This packet completed the photo; [ImageChunkOutcome.result] is set.
  completed,
}

/// Why a photo was given up on.
enum ImageReassemblyFailureReason {
  /// The window elapsed with packets still missing.
  expired,

  /// Dropped to keep the photos being received within their cap.
  overflow,

  /// Every packet came, but the metadata byte was unreadable
  /// ([ImageChunkStatus.unsupportedFormat]).
  unsupportedFormat,

  /// Dropped by [ImageReassembler.clear] (disconnect / new session).
  disconnected,

  /// Dropped by [ImageReassembler.clearChannel] because the radio slot it
  /// arrived on now holds a different channel.
  channelChanged,
}

/// A photo received whole.
class ImageReassemblyResult {
  final ImageStreamKey key;

  /// Its metadata byte, as decoded.
  final ImageStreamMetadata? metadata;

  /// The encoded image bitstream, exactly as the sender produced it.
  final Uint8List data;

  /// True when one packet was rebuilt from the repair packet.
  final bool recoveredWithParity;

  /// Number of data packets in the photo.
  final int chunkCount;

  /// The fewest repeaters any copy of its packets came through: 0 when this
  /// radio heard the sender's own. Null when no copy said.
  final int? fewestHops;

  const ImageReassemblyResult({
    required this.key,
    required this.metadata,
    required this.data,
    required this.recoveredWithParity,
    required this.chunkCount,
    this.fewestHops,
  });
}

/// A photo given up on: expired, dropped, or unreadable.
class ImageReassemblyFailure {
  final ImageStreamKey key;
  final int total;
  final int receivedDataChunks;
  final bool hadParity;
  final DateTime firstSeen;
  final DateTime expiredAt;

  /// As [ImageReassemblyResult.fewestHops], of the packets that came.
  final int? fewestHops;

  final ImageReassemblyFailureReason reason;

  const ImageReassemblyFailure({
    required this.key,
    required this.total,
    required this.receivedDataChunks,
    required this.hadParity,
    required this.firstSeen,
    required this.expiredAt,
    this.fewestHops,
    this.reason = ImageReassemblyFailureReason.expired,
  });

  int get missingChunks => total - receivedDataChunks;

  /// True when every packet arrived but the bytes were unusable: the chat
  /// says "needs a newer MeshTrax", not "incomplete".
  bool get isCorrupt =>
      reason == ImageReassemblyFailureReason.unsupportedFormat;

  @override
  String toString() =>
      'ImageReassemblyFailure($key, '
      '$receivedDataChunks/$total, parity: $hadParity, ${reason.name})';
}

/// Result of feeding one packet to [ImageReassembler.addChunk].
class ImageChunkOutcome {
  final ImageChunkStatus status;
  final ImageChunkHeader? header;
  final ImageReassemblyResult? result;

  const ImageChunkOutcome(this.status, {this.header, this.result});

  bool get isComplete => status == ImageChunkStatus.completed;
}

/// A photo received recently, kept for the [ImageReassembler.ttl] so a late
/// copy of one of its packets is told apart from a new photo that reuses its
/// id.
class _CompletedImage {
  final DateTime at;
  final ImagePackets packets;

  _CompletedImage(this.at, this.packets);
}

/// A photo being received, as it stands.
class ImageReceiving {
  final ImageStreamKey key;

  /// Its data packets.
  final int total;

  /// The data packets in.
  final int received;

  /// The data packets it lacks, one bit each: packet i at bit i
  /// ([missingPacketBits]).
  final int missing;

  final bool hasParity;

  /// The highest packet index seen; the repair packet is [total].
  final int highest;

  final DateTime firstSeen;
  final DateTime lastSeen;
  final int? fewestHops;

  const ImageReceiving({
    required this.key,
    required this.total,
    required this.received,
    required this.missing,
    required this.hasParity,
    required this.highest,
    required this.firstSeen,
    required this.lastSeen,
    this.fewestHops,
  });
}

class _PendingImage {
  final ImageStreamKey key;
  final ImagePackets packets;
  final DateTime firstSeen;
  DateTime lastSeen;

  /// The highest packet index seen; the repair packet is the data count.
  int highest = -1;

  /// The fewest repeaters any copy of a packet came through; null when none
  /// said.
  int? fewestHops;

  _PendingImage({
    required this.key,
    required int total,
    required this.firstSeen,
  }) : packets = ImagePackets(total: total),
       lastSeen = firstSeen;

  void heard(int? hops) {
    if (hops != null && (fewestHops == null || hops < fewestHops!)) {
      fewestHops = hops;
    }
  }

  ImageReassemblyFailure failure(
    DateTime at, [
    ImageReassemblyFailureReason reason = ImageReassemblyFailureReason.expired,
  ]) => ImageReassemblyFailure(
    key: key,
    total: packets.total,
    receivedDataChunks: packets.received,
    hadParity: packets.hasParity,
    firstSeen: firstSeen,
    fewestHops: fewestHops,
    expiredAt: at,
    reason: reason,
  );
}

/// Collects received photo packets into whole photos, by sender, photo and
/// channel, for up to [ttl] from each photo's first packet; traxpix's
/// [ImagePackets] makes the photo. Pure Dart, injectable clock.
///
/// Photos given up on are reported through [onFailed].
class ImageReassembler {
  /// Prefix of this radio's own public key: packets bearing it are its own
  /// photos, not received ones. Null disables the check.
  final int? selfPrefix;

  final Duration ttl;

  /// Cap on photos being received at once; the oldest is dropped (and
  /// reported as failed) beyond it.
  final int maxConcurrentStreams;

  /// Cap on remembered finished photos; the oldest is forgotten beyond it.
  ///
  /// Without it the memory would be bounded only by [ttl] times the packet
  /// rate. A lone repair packet with `total == 1, idx == 1` completes a whole
  /// photo by itself, so every received packet (noise, a fuzzer, a hostile
  /// neighbour) could add an entry.
  final int maxCompletedStreams;

  final void Function(ImageReassemblyResult result)? onImage;
  final void Function(ImageReassemblyFailure failure)? onFailed;

  final DateTime Function() _clock;

  final Map<ImageStreamKey, _PendingImage> _pending = {};

  /// Photos finished within the last [ttl]. Needed because in the loss-free
  /// case the repair packet arrives AFTER the photo is complete, and a packet
  /// sent again (its retry byte bumped) can come later still; without this
  /// each would start a photo that never finishes, later reported as
  /// incomplete.
  ///
  /// The bodies are kept (a photo is a couple of KiB at most) so a late
  /// packet can be told apart from a NEW photo that reuses the id:
  /// [ImageIdAllocator] seeds from `Random().nextInt(256)`, so a restart can
  /// re-roll onto an id used minutes earlier.
  final Map<ImageStreamKey, _CompletedImage> _recentlyCompleted = {};

  ImageReassembler({
    this.selfPrefix,
    this.ttl = photoReceiveWindow,
    this.maxConcurrentStreams = 8,
    this.maxCompletedStreams = 8,
    this.onImage,
    this.onFailed,
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  /// Number of photos being received.
  int get pendingCount => _pending.length;

  /// Keys of the photos being received (test/debug aid).
  Iterable<ImageStreamKey> get pendingKeys => _pending.keys;

  /// The photos being received, as they stand.
  List<ImageReceiving> get receiving => [
    for (final entry in _pending.values)
      ImageReceiving(
        key: entry.key,
        total: entry.packets.total,
        received: entry.packets.received,
        missing: missingPacketBits(entry.packets),
        hasParity: entry.packets.hasParity,
        highest: entry.highest,
        firstSeen: entry.firstSeen,
        lastSeen: entry.lastSeen,
        fewestHops: entry.fewestHops,
      ),
  ];

  /// Number of finished photos remembered for late copies.
  int get completedCount => _recentlyCompleted.length;

  /// Keys of the remembered finished photos (test/debug aid).
  Iterable<ImageStreamKey> get completedKeys => _recentlyCompleted.keys;

  /// Drops everything (e.g. on disconnect). Photos being received are
  /// reported through [onFailed] right away.
  void clear({DateTime? now}) {
    final at = now ?? _clock();
    final dropped = _pending.values.toList();
    _pending.clear();
    _recentlyCompleted.clear();
    for (final entry in dropped) {
      onFailed?.call(
        entry.failure(at, ImageReassemblyFailureReason.disconnected),
      );
    }
  }

  /// Drops every photo that arrived on [channelIndex], whose radio slot now
  /// holds a different channel, so a new photo there can never be completed
  /// with the old channel's bytes. Photos being received are reported through
  /// [onFailed].
  void clearChannel(int channelIndex, {DateTime? now}) {
    final at = now ?? _clock();
    _recentlyCompleted.removeWhere(
      (key, _) => key.channelIndex == channelIndex,
    );
    final dropped = _pending.values
        .where((entry) => entry.key.channelIndex == channelIndex)
        .toList();
    for (final entry in dropped) {
      _pending.remove(entry.key);
      onFailed?.call(
        entry.failure(at, ImageReassemblyFailureReason.channelChanged),
      );
    }
  }

  /// Feeds one received photo packet, [blob]. [hops]: how many
  /// repeaters this copy came through, 0 when heard from the sender's own
  /// radio; null when not known. The photo keeps the fewest.
  ///
  /// [now] overrides the clock for tests. Expired photos are swept first, so
  /// a caller that only ever calls [addChunk] still gets the window.
  ImageChunkOutcome addChunk(
    Uint8List blob, {
    int channelIndex = 0,
    int? hops,
    DateTime? now,
  }) {
    final at = now ?? _clock();
    evictExpired(now: at);

    final header = parseImageChunkHeader(blob);
    if (header == null) {
      return const ImageChunkOutcome(ImageChunkStatus.malformed);
    }
    if (selfPrefix != null && header.senderPrefix == selfPrefix) {
      return ImageChunkOutcome(ImageChunkStatus.fromSelf, header: header);
    }

    final key = ImageStreamKey(
      senderPrefix: header.senderPrefix,
      imgId: header.imgId,
      channelIndex: channelIndex,
    );
    final body = Uint8List.sublistView(blob, header.bodyOffset);
    if (!ImagePackets(total: header.total).fits(
      header,
      body,
    )) {
      return ImageChunkOutcome(ImageChunkStatus.malformed, header: header);
    }

    final completed = _recentlyCompleted[key];
    if (completed != null) {
      if (completed.packets.repeats(header, body)) {
        // A late copy of a photo already received (often the repair packet,
        // or a packet sent again).
        return ImageChunkOutcome(ImageChunkStatus.duplicate, header: header);
      }
      // Same key, other content: a NEW photo reusing the id, not a late copy.
      // Forget the finished one so a fresh photo starts; dropping this as a
      // duplicate would lose the photo with no trace at all.
      _recentlyCompleted.remove(key);
    }

    var conflicted = false;
    var entry = _pending[key];
    if (entry != null && entry.packets.total != header.total) {
      // Same key, different shape: an id wrap or a new photo reusing the id.
      _pending.remove(key);
      entry = null;
      conflicted = true;
    }
    if (entry == null) {
      entry = _PendingImage(key: key, total: header.total, firstSeen: at);
      _pending[key] = entry;
      _evictOverflow(at);
    }
    entry.lastSeen = at;
    entry.heard(hops);
    if (header.index > entry.highest) entry.highest = header.index;

    switch (entry.packets.add(header, body)) {
      case ImagePacketAdded.duplicate:
        return ImageChunkOutcome(ImageChunkStatus.duplicate, header: header);
      case ImagePacketAdded.conflicting:
        // Same index, different content: a new photo on a reused id.
        _pending.remove(key);
        final fresh = _PendingImage(
          key: key,
          total: header.total,
          firstSeen: at,
        );
        fresh.packets.add(header, body);
        fresh.heard(hops);
        fresh.highest = header.index;
        _pending[key] = fresh;
        return ImageChunkOutcome(ImageChunkStatus.conflicting, header: header);
      case ImagePacketAdded.accepted:
        break;
    }

    final rebuilt = entry.packets.rebuild();
    if (rebuilt == null) {
      return ImageChunkOutcome(
        conflicted ? ImageChunkStatus.conflicting : ImageChunkStatus.accepted,
        header: header,
      );
    }
    _pending.remove(key);
    // Remembered even when the bytes were unreadable: a verbatim re-send of
    // the same packets must not start the photo again, while a new photo
    // (different bytes) still fails `repeats` and starts a fresh one.
    _remember(key, at, entry.packets);
    if (rebuilt.metadata == null) {
      onFailed?.call(
        entry.failure(at, ImageReassemblyFailureReason.unsupportedFormat),
      );
      return ImageChunkOutcome(
        ImageChunkStatus.unsupportedFormat,
        header: header,
      );
    }
    final result = ImageReassemblyResult(
      key: key,
      metadata: rebuilt.metadata,
      data: rebuilt.data,
      recoveredWithParity: rebuilt.recoveredWithParity,
      chunkCount: rebuilt.chunkCount,
      fewestHops: entry.fewestHops,
    );
    onImage?.call(result);
    return ImageChunkOutcome(
      ImageChunkStatus.completed,
      header: header,
      result: result,
    );
  }

  /// Removes photos whose first packet is older than [ttl], reporting each
  /// through [onFailed]. Returns the failures, oldest first.
  List<ImageReassemblyFailure> evictExpired({DateTime? now}) {
    final at = now ?? _clock();
    _recentlyCompleted.removeWhere((_, c) => at.difference(c.at) >= ttl);
    final expired = <ImageReassemblyFailure>[];
    _pending.removeWhere((key, entry) {
      if (at.difference(entry.firstSeen) < ttl) return false;
      expired.add(entry.failure(at));
      return true;
    });
    expired.sort((a, b) => a.firstSeen.compareTo(b.firstSeen));
    for (final failure in expired) {
      onFailed?.call(failure);
    }
    return expired;
  }

  /// Records a finished (received OR unreadable) photo and keeps
  /// [_recentlyCompleted] within [maxCompletedStreams], oldest first.
  void _remember(ImageStreamKey key, DateTime at, ImagePackets packets) {
    _recentlyCompleted[key] = _CompletedImage(at, packets);
    while (_recentlyCompleted.length > maxCompletedStreams) {
      ImageStreamKey? oldestKey;
      DateTime? oldest;
      _recentlyCompleted.forEach((k, c) {
        if (oldest == null || c.at.isBefore(oldest!)) {
          oldest = c.at;
          oldestKey = k;
        }
      });
      if (oldestKey == null) return;
      _recentlyCompleted.remove(oldestKey);
    }
  }

  void _evictOverflow(DateTime at) {
    while (_pending.length > maxConcurrentStreams) {
      ImageStreamKey? oldestKey;
      DateTime? oldest;
      _pending.forEach((key, entry) {
        if (oldest == null || entry.firstSeen.isBefore(oldest!)) {
          oldest = entry.firstSeen;
          oldestKey = key;
        }
      });
      if (oldestKey == null) return;
      final victim = _pending.remove(oldestKey)!;
      onFailed?.call(
        victim.failure(at, ImageReassemblyFailureReason.overflow),
      );
    }
  }
}
