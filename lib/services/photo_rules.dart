import 'package:flutter/foundation.dart';
import 'package:traxpix/traxpix.dart';

import '../models/channel.dart';
import '../models/radio_settings.dart';
import '../storage/prefs_manager.dart';

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

/// On a MeshCore frequency: one photo per radio in this long, however it
/// goes.
const Duration photoGapZeroHop = Duration(minutes: 10);

/// On a MeshCore frequency: one photo through repeaters per radio in this
/// long.
const Duration photoGapRepeaters = Duration(minutes: 20);

/// A photo through repeaters that no repeater was heard carrying gives back
/// its [photoGapRepeaters] when a repeater was heard this recently as its
/// wait ended: this radio hears repeaters, so their silence means none
/// carried it.
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

/// The pause after each packet of a photo whose payload is [payloadBytes]
/// long, with the repair packet if [repairPacket]: zero hop, or as a flood
/// through repeaters; [airtimeMs] is the radio's airtime for a packet of so
/// many bytes. On a frequency [shared] with other MeshCore users, at least
/// [photoMinGapAirtimes] airtimes, as long as every packet still goes out
/// within three quarters of the receiver's reassembly window.
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
  final cap = kImageReassemblyTtl * 0.75 ~/ (packets - 1);
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

/// Why a photo can't be sent now (see [photoSendBlocked]).
enum PhotoBlockReason {
  /// One photo per [photoGapZeroHop], however it goes.
  wait,

  /// One photo through repeaters per [photoGapRepeaters].
  waitRepeaters,
}

/// A [reason], and the minutes left before the next photo for a wait.
typedef PhotoBlock = ({PhotoBlockReason reason, int minutes});

/// Why a photo can't go out now, or null when it can. The rules hold only on
/// a MeshCore preset's frequency, on every channel; off-grid and custom
/// frequencies have none. [lastSent] is when this radio last sent one where
/// the rules apply, and [lastSentViaRepeaters] when it last sent one through
/// repeaters there.
PhotoBlock? photoSendBlocked({
  required int? freqKhz,
  required DateTime? lastSent,
  DateTime? lastSentViaRepeaters,
  bool viaRepeaters = false,
  required DateTime now,
}) {
  if (!photoRulesApply(freqKhz)) return null;
  final wait = _minutesLeft(lastSent, photoGapZeroHop, now);
  if (wait != null) return (reason: PhotoBlockReason.wait, minutes: wait);
  final waitVia = viaRepeaters
      ? _minutesLeft(lastSentViaRepeaters, photoGapRepeaters, now)
      : null;
  if (waitVia != null) {
    return (reason: PhotoBlockReason.waitRepeaters, minutes: waitVia);
  }
  return null;
}

int? _minutesLeft(DateTime? since, Duration gap, DateTime now) {
  final wait = since?.add(gap).difference(now);
  if (wait == null || wait <= Duration.zero) return null;
  return (wait.inSeconds / 60).ceil();
}

String _lastSentKey(String radioKeyHex, {bool viaRepeaters = false}) =>
    'photo_last_sent_${viaRepeaters ? 'via_' : ''}'
    '${radioKeyHex.substring(0, 16)}';

DateTime? _lastSent(String radioKeyHex, {required bool viaRepeaters}) {
  if (radioKeyHex.length < 16) return null;
  final ms = PrefsManager.instance.getInt(
    _lastSentKey(radioKeyHex, viaRepeaters: viaRepeaters),
  );
  return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
}

/// When the radio with public key [radioKeyHex] last sent a photo where the
/// rules apply.
DateTime? photoLastSent(String radioKeyHex) =>
    _lastSent(radioKeyHex, viaRepeaters: false);

/// When it last sent one through repeaters there.
DateTime? photoLastSentViaRepeaters(String radioKeyHex) =>
    _lastSent(radioKeyHex, viaRepeaters: true);

Future<void> notePhotoSent(
  String radioKeyHex,
  DateTime at, {
  bool viaRepeaters = false,
}) async {
  if (radioKeyHex.length < 16) return;
  for (final via in [false, if (viaRepeaters) true]) {
    await PrefsManager.instance.setInt(
      _lastSentKey(radioKeyHex, viaRepeaters: via),
      at.millisecondsSinceEpoch,
    );
  }
}

/// Gives back the [photoGapRepeaters] of the photo through repeaters sent
/// [at], which no repeater carried: the next photo waits only the
/// [photoGapZeroHop]. A later photo's time is left alone; an earlier one's
/// had run out, or this one couldn't have gone.
Future<void> notePhotoNotCarried(String radioKeyHex, DateTime at) async {
  if (radioKeyHex.length < 16) return;
  final key = _lastSentKey(radioKeyHex, viaRepeaters: true);
  if (PrefsManager.instance.getInt(key) != at.millisecondsSinceEpoch) return;
  await PrefsManager.instance.remove(key);
}
