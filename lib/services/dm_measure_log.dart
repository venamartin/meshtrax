import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart' as crypto;

/// The measurement lines for the weeks of measuring before Pathfinder's new
/// numbers decide anything: one fixed format a script can read,
/// `M1 <kind> key=value ...`. M1 is the version: a line whose meaning
/// changes takes M2.
///
/// They never name a contact or quote a message. A contact is the first two
/// bytes of its key; an area is a keyed hash that differs on each phone, so
/// the area key itself is never written to a log (owner, 2026-10-25).
///
/// Kinds: `try` (a DM try goes out), `end` (its ladder is over), `ack` (an
/// ACK arrived), `out` (a repeater was heard passing my routed DM on),
/// `echo` (a repeater was heard passing my flooded DM on), `got` (a copy of
/// a DM to me was heard), `hear` (who this radio heard, per area and hour).
class MeasureLog {
  MeasureLog({required this.write, this.areaKey, this.salt, DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  /// Hands a finished line to the debug log.
  final void Function(String line) write;

  /// The area the radio is in now, or null when it is not known.
  final String? Function()? areaKey;

  /// The phone's own secret for area hashes, made once and kept; null when
  /// there is none to be had (then no area is written).
  final String? Function()? salt;

  final DateTime Function() _now;

  static const version = 'M1';

  /// One line of [kind]; fields that are null are left out.
  void line(String kind, Map<String, Object?> fields) {
    final b = StringBuffer('$version $kind');
    for (final MapEntry(:key, :value) in fields.entries) {
      if (value == null) continue;
      b.write(' $key=${value is double ? value.toStringAsFixed(2) : value}');
    }
    write(b.toString());
  }

  /// A contact as the lines name it: the first two bytes of its key.
  static String contact(String publicKeyHex) => publicKeyHex
      .substring(0, math.min(4, publicKeyHex.length))
      .toUpperCase();

  /// The area the radio is in, as a keyed hash of 8 hex digits, or null.
  String? area() {
    final key = areaKey?.call();
    if (key == null) return null;
    final secret = salt?.call();
    if (secret == null) return null;
    final mac = crypto.Hmac(crypto.sha256, utf8.encode(secret))
        .convert(utf8.encode(key));
    return mac.toString().substring(0, 8).toUpperCase();
  }

  // Who this radio heard since the hour began, in the area it was in: by
  // repeater code and how it was heard, a count and the sum of the levels.
  final Map<String, ({int n, double dB})> _heard = {};
  String? _heardArea;
  DateTime? _heardHour;

  /// A transmission from the repeater [code] reached this radio at [dB]:
  /// a flood it passed on (`flood`) or its own advert (`advert`).
  void noteHeard(String code, double dB, {required String from}) {
    final hour = _hourOf(_now());
    final area = this.area();
    if (_heardHour != hour || _heardArea != area) {
      flushHeard();
      _heardHour = hour;
      _heardArea = area;
    }
    final k = '$code $from';
    final was = _heard[k];
    _heard[k] = (n: (was?.n ?? 0) + 1, dB: (was?.dB ?? 0) + dB);
  }

  /// Writes the `hear` lines for the hour so far and starts again.
  void flushHeard() {
    final hour = _heardHour;
    if (hour != null) {
      final keys = _heard.keys.toList()..sort();
      for (final k in keys) {
        final [code, from] = k.split(' ');
        final h = _heard[k]!;
        line('hear', {
          'a': _heardArea,
          'hour': hour.toUtc().toIso8601String().substring(0, 13),
          'r': code,
          'from': from,
          'n': h.n,
          'db': h.dB / h.n,
        });
      }
    }
    _heard.clear();
    _heardHour = null;
  }

  static DateTime _hourOf(DateTime t) => DateTime(t.year, t.month, t.day, t.hour);
}
