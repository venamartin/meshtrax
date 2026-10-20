import 'dart:typed_data';

import 'meshcore_protocol.dart';

/// Spots another app driving the same radio. A BLE+WiFi companion
/// (firmware 1.18) writes every reply to every connected app, so a reply to
/// a request this app never made means someone else is connected.
///
/// Only replies the firmware sends solely in answer to one command are
/// watched; pushes and shared acks (OK/ERR/SENT) prove nothing.
class SecondAppDetector {
  SecondAppDetector({DateTime Function()? clock})
    : _now = clock ?? DateTime.now;

  /// A local round trip takes milliseconds; a reply this late is not ours.
  static const Duration replyWindow = Duration(seconds: 30);

  static const Map<int, int> _replyTo = {
    cmdDeviceQuery: respCodeDeviceInfo,
    cmdAppStart: respCodeSelfInfo,
    cmdGetContacts: respCodeContactsStart,
    cmdGetBattAndStorage: respCodeBattAndStorage,
    cmdGetDeviceTime: respCodeCurrTime,
  };

  final DateTime Function() _now;
  final Map<int, List<DateTime>> _asked = {};

  /// Call for every frame this app writes, before the write.
  void onSent(Uint8List frame) {
    if (frame.isEmpty) return;
    final reply = _replyTo[frame[0]];
    if (reply != null) (_asked[reply] ??= []).add(_now());
  }

  /// True when [frame] answers nothing this app asked for within
  /// [replyWindow]. A reply that is ours uses up its request.
  bool isForeign(Uint8List frame) {
    if (frame.isEmpty || !_replyTo.containsValue(frame[0])) return false;
    final asked = _asked[frame[0]];
    if (asked == null) return true;
    final now = _now();
    asked.removeWhere((at) => now.difference(at) > replyWindow);
    if (asked.isEmpty) return true;
    asked.removeAt(0);
    return false;
  }

  void reset() => _asked.clear();
}
