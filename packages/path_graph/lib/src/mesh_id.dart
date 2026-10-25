/// The radio preset a graph belongs to. Repeaters, links and doorsteps are
/// facts about one mesh: the same two-byte code names different repeaters
/// on 910.525 and on 920.000, and a doorstep heard on one preset says
/// nothing on another. TX power is left out (per-radio rows absorb it) and
/// so are channel keys (radios on the same frequency share repeaters).
class MeshId {
  const MeshId({
    required this.freqHz,
    required this.bwHz,
    required this.sf,
    required this.cr,
  });

  final int freqHz;
  final int bwHz;
  final int sf;
  final int cr;

  /// Stable file-name-safe key: `m910525000_62500_8_8`.
  String get key => 'm${freqHz}_${bwHz}_${sf}_$cr';

  /// `910.525 MHz · 62.5 kHz · SF8 · CR8`.
  String get label {
    final mhz = (freqHz / 1000000).toStringAsFixed(3);
    final khz = bwHz % 1000 == 0
        ? '${bwHz ~/ 1000}'
        : (bwHz / 1000).toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '');
    return '$mhz MHz · $khz kHz · SF$sf · CR$cr';
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'freq_hz': freqHz,
        'bw_hz': bwHz,
        'sf': sf,
        'cr': cr,
        'label': label,
      };

  static MeshId? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final f = raw['freq_hz'], b = raw['bw_hz'], s = raw['sf'], c = raw['cr'];
    if (f is! num || b is! num || s is! num || c is! num) return null;
    return MeshId(
        freqHz: f.toInt(), bwHz: b.toInt(), sf: s.toInt(), cr: c.toInt());
  }

  @override
  bool operator ==(Object other) => other is MeshId && other.key == key;

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => label;
}
