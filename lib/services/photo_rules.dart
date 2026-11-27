import 'package:flutter/foundation.dart';
import 'package:traxpix/traxpix.dart';

import '../models/channel.dart';
import '../models/radio_settings.dart';
import '../storage/prefs_manager.dart';
import 'photo_reassembler.dart';

/// The frequencies of MeshTrax's MeshCore presets, in kHz: every preset in
/// the list but the three Off-Grid ones.
final Set<int> meshCoreFrequenciesKhz = {
  for (final (name, settings) in RadioSettings.presets)
    if (!name.startsWith('Off-Grid')) settings.frequencyHz,
};

/// Whether the rules apply to a radio on [freqKhz]: a MeshCore preset's
/// frequency, whatever its other settings.
bool photoRulesApply(int? freqKhz) =>
    freqKhz != null && meshCoreFrequenciesKhz.contains(freqKhz);

/// On a MeshCore frequency, how long after a photo of [packets] packets (the
/// repair packet included) through repeaters the next photo can go through
/// repeaters: none after one packet, no more on the air than a long message,
/// then 5, 10 and 20 minutes after 2, 3, and 4 or more. Zero hop has no
/// limit: it reaches only the radio's neighbours.
Duration photoGapRepeaters(int packets) => switch (packets) {
  <= 1 => Duration.zero,
  2 => const Duration(minutes: 5),
  3 => const Duration(minutes: 10),
  _ => const Duration(minutes: 20),
};

/// A photo through repeaters that no repeater was heard carrying gives back
/// its time ([photoGapRepeaters]) when a repeater was heard this recently
/// as its wait ended: this radio hears repeaters, so their silence means
/// none carried it.
const Duration photoUncarriedRepeaterWindow = Duration(minutes: 1);

/// On a MeshCore frequency, at least this many packet airtimes from one
/// photo packet to the next, so a photo takes no more than about a quarter of
/// the air around the sender. Slow settings get less where a photo would
/// otherwise miss the receiver's reassembly window ([photoGapFor]).
const int photoMinGapAirtimes = 4;

/// Bytes a typical channel text message puts on the air with no path:
/// header and path length (2), channel hash and MAC (3), then a sender name
/// and about 40 characters, encrypted (64). The yardstick for a photo's
/// airtime.
const int photoTextMessageAirBytes = 69;

/// How many typical text messages take as long on the air as [onAir], with
/// [airtimeMs] the radio's airtime for a packet of so many bytes.
int photoTextMessages(Duration onAir, int Function(int bytes) airtimeMs) =>
    (onAir.inMilliseconds / airtimeMs(photoTextMessageAirBytes)).round();

/// The least pause after each photo packet before the next one goes to the
/// radio: the packet's own time on air, then half a second.
///
/// Zero-hop packets have MeshCore's top send priority (0, `Mesh::sendDirect`)
/// and channel messages the next (1, `Mesh::sendFlood`). The radio always
/// sends the highest priority waiting (`PacketQueue::get`), back to back while
/// its airtime budget lasts, and nothing can be cancelled once handed over. So
/// photo packets handed over together would all go before an SOS sent
/// meanwhile. Handed over one at a time, each once the last is off the air,
/// anything sent in between goes first: an SOS waits for one photo packet at
/// most. Checked against meshcore-dev/MeshCore 75b04ef.
Duration photoPacketGap(Duration packetAirtime) =>
    packetAirtime + const Duration(milliseconds: 500);

/// A repeater's longest wait before passing a flood on, in airtimes of the
/// packet: 5 × `tx_delay_factor`, 0.5 by default
/// (`MyMesh::getRetransmitDelay`, MeshCore 75b04ef).
const double _floodWaitMaxAirtimes = 2.5;

/// The least pause after each photo packet sent as a flood, through
/// repeaters.
///
/// Each repeater that hears a packet passes it on once, after a random wait
/// of up to [_floodWaitMaxAirtimes] airtimes. The sender's next packet could
/// reach a nearby repeater while one further out is passing the previous one
/// on, out of the sender's hearing: the nearby repeater hears both and loses
/// one. So the next packet waits until the previous one has, at worst,
/// cleared two hops: its own airtime, then two hops of wait and airtime, then
/// the half second.
///
/// Capped so that all [packets] still go out within three quarters of the
/// receiver's [photoReceiveWindow]; never shorter than [photoPacketGap].
Duration photoPacketGapFlood(Duration packetAirtime, {required int packets}) {
  final gap = photoPacketGap(packetAirtime);
  final clear =
      packetAirtime * (1 + 2 * (1 + _floodWaitMaxAirtimes)) +
      const Duration(milliseconds: 500);
  if (packets < 2) return clear;
  final cap = photoReceiveWindow * 0.75 ~/ (packets - 1);
  final spaced = clear < cap ? clear : cap;
  return spaced > gap ? spaced : gap;
}

/// The least pause after each packet of a photo whose payload is
/// [payloadBytes] long, with the repair packet if [repairPacket]: zero hop,
/// or as a flood through repeaters; [airtimeMs] is the radio's airtime for a
/// packet of so many bytes. On a frequency [shared] with other MeshCore
/// users, at least [photoMinGapAirtimes] airtimes, as long as every packet
/// still goes out within three quarters of the receiver's window.
Duration photoGapFor(
  int payloadBytes, {
  required bool zeroHop,
  required bool repairPacket,
  required int Function(int bytes) airtimeMs,
  bool shared = false,
}) {
  final airtime = Duration(milliseconds: airtimeMs(kPhotoPacketAirBytes));
  final packets = imageDataChunkCount(payloadBytes) + (repairPacket ? 1 : 0);
  final gap = zeroHop
      ? photoPacketGap(airtime)
      : photoPacketGapFlood(airtime, packets: packets);
  if (!shared || packets < 2) return gap;
  final least = airtime * photoMinGapAirtimes;
  final cap = photoReceiveWindow * 0.75 ~/ (packets - 1);
  final floor = least < cap ? least : cap;
  return gap > floor ? gap : floor;
}

/// Public, or a hashtag channel: anyone who knows the name can join it.
bool isOpenChannel(Channel channel) =>
    channel.isPublicChannel ||
    (channel.name.startsWith('#') &&
        listEquals(channel.psk, Channel.derivePskFromHashtag(channel.name)));

/// What the sender is asked before a photo goes out (see [photoWarningFor]).
enum PhotoWarning {
  /// Off-grid and custom frequencies: nothing beyond the figures.
  none,

  /// A private channel on a MeshCore frequency: its airtime.
  airtime,

  /// Public or a hashtag channel on a MeshCore frequency: also that most
  /// people there won't see it.
  openChannel,
}

PhotoWarning photoWarningFor(Channel channel, int? freqKhz) {
  if (!photoRulesApply(freqKhz)) return PhotoWarning.none;
  return isOpenChannel(channel)
      ? PhotoWarning.openChannel
      : PhotoWarning.airtime;
}

/// The last photo's packets, the wait after it ([photoGapRepeaters]) and the
/// minutes of it left, both whole minutes.
typedef PhotoBlock = ({int packets, int gap, int minutes});

/// This radio's last photo through repeaters where the rules apply: when it
/// went, and its packets.
typedef PhotoSentLast = ({DateTime at, int packets});

/// What the next photo through repeaters still waits after [last], this
/// radio's last one, by that photo's size; null when it can go. Asked as
/// the sender starts a photo, before its own size is known. The rules hold
/// only on a MeshCore preset's frequency, on every channel; off-grid and
/// custom frequencies have none, and zero hop has none anywhere.
PhotoBlock? photoSendBlocked({
  required int? freqKhz,
  required PhotoSentLast? last,
  required DateTime now,
}) {
  if (!photoRulesApply(freqKhz) || last == null) return null;
  final gap = photoGapRepeaters(last.packets);
  final left = _minutesLeft(last.at, gap, now);
  return left == null
      ? null
      : (packets: last.packets, gap: gap.inMinutes, minutes: left);
}

int? _minutesLeft(DateTime? since, Duration gap, DateTime now) {
  final wait = since?.add(gap).difference(now);
  if (wait == null || wait <= Duration.zero) return null;
  return (wait.inSeconds / 60).ceil();
}

String _lastSentKey(String radioKeyHex) =>
    'photo_last_sent_via_${radioKeyHex.substring(0, 16)}';

String _lastPacketsKey(String radioKeyHex) =>
    'photo_last_sent_packets_${radioKeyHex.substring(0, 16)}';

/// The last photo the radio with public key [radioKeyHex] sent through
/// repeaters where the rules apply.
PhotoSentLast? photoLastSentViaRepeaters(String radioKeyHex) {
  if (radioKeyHex.length < 16) return null;
  final ms = PrefsManager.instance.getInt(_lastSentKey(radioKeyHex));
  if (ms == null) return null;
  return (
    at: DateTime.fromMillisecondsSinceEpoch(ms),
    // MeshTrax 1.12.0 kept only the time: the longest wait.
    packets: PrefsManager.instance.getInt(_lastPacketsKey(radioKeyHex)) ?? 4,
  );
}

/// The radio sent a photo of [packets] packets through repeaters [at] that
/// counts against the rules: one of more than one packet
/// ([photoGapRepeaters]).
Future<void> notePhotoSent(
  String radioKeyHex,
  DateTime at, {
  required int packets,
}) async {
  if (radioKeyHex.length < 16) return;
  await PrefsManager.instance.setInt(
    _lastSentKey(radioKeyHex),
    at.millisecondsSinceEpoch,
  );
  await PrefsManager.instance.setInt(_lastPacketsKey(radioKeyHex), packets);
}

/// Gives back the time of the photo through repeaters sent [at], which no
/// repeater carried: the next photo waits for none of it. A later photo's
/// time is left alone; an earlier one's had run out, or this one couldn't
/// have gone.
Future<void> notePhotoNotCarried(String radioKeyHex, DateTime at) async {
  if (radioKeyHex.length < 16) return;
  final key = _lastSentKey(radioKeyHex);
  if (PrefsManager.instance.getInt(key) != at.millisecondsSinceEpoch) return;
  await PrefsManager.instance.remove(key);
  await PrefsManager.instance.remove(_lastPacketsKey(radioKeyHex));
}
