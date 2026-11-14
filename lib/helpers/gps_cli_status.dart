/// What the radio's `gps` CLI command (firmware 1.18+) says about its GPS:
/// `on, active, fix, 7 sats`, `on, active, no fix, 0 sats` or `off`.
class GpsCliStatus {
  /// The GPS module has power.
  final bool powered;

  /// The GPS has a position.
  final bool hasFix;

  /// Satellites in use; null when the reply gave no count.
  final int? satellites;

  const GpsCliStatus({
    required this.powered,
    required this.hasFix,
    this.satellites,
  });

  static final _sats = RegExp(r'(\d+)\s*sats?');

  /// Null when [reply] is not a GPS status (an error, or a radio with no GPS).
  static GpsCliStatus? parse(String reply) {
    final text = reply.trim().toLowerCase();
    if (text == 'off') {
      return const GpsCliStatus(powered: false, hasFix: false);
    }
    if (!text.startsWith('on,')) return null;
    final parts = text.split(',').map((p) => p.trim()).toList();
    final sats = _sats.firstMatch(text);
    return GpsCliStatus(
      powered: true,
      hasFix: parts.contains('fix'),
      satellites: sats == null ? null : int.parse(sats.group(1)!),
    );
  }
}
