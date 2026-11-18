enum LoRaBandwidth {
  bw7_8(7800, '7.8 kHz'),
  bw10_4(10400, '10.4 kHz'),
  bw15_6(15600, '15.6 kHz'),
  bw20_8(20800, '20.8 kHz'),
  bw31_25(31250, '31.25 kHz'),
  bw41_7(41700, '41.7 kHz'),
  bw62_5(62500, '62.5 kHz'),
  bw125(125000, '125 kHz'),
  bw250(250000, '250 kHz'),
  bw500(500000, '500 kHz');

  final int hz;
  final String label;

  const LoRaBandwidth(this.hz, this.label);
}

enum LoRaSpreadingFactor {
  sf5(5, 'SF5'),
  sf6(6, 'SF6'),
  sf7(7, 'SF7'),
  sf8(8, 'SF8'),
  sf9(9, 'SF9'),
  sf10(10, 'SF10'),
  sf11(11, 'SF11'),
  sf12(12, 'SF12');

  final int value;
  final String label;

  const LoRaSpreadingFactor(this.value, this.label);
}

enum LoRaCodingRate {
  cr4_5(5, '4/5'),
  cr4_6(6, '4/6'),
  cr4_7(7, '4/7'),
  cr4_8(8, '4/8');

  final int value;
  final String label;

  const LoRaCodingRate(this.value, this.label);
}

class RadioSettings {
  final double frequencyMHz;
  final LoRaBandwidth bandwidth;
  final LoRaSpreadingFactor spreadingFactor;
  final LoRaCodingRate codingRate;
  final int txPowerDbm;

  RadioSettings({
    required this.frequencyMHz,
    required this.bandwidth,
    required this.spreadingFactor,
    required this.codingRate,
    required this.txPowerDbm,
  });

  // Regional preset configurations
  static final List<(String, RadioSettings)> presets = [
    (
      'Australia',
      RadioSettings(
        frequencyMHz: 915.8,
        bandwidth: LoRaBandwidth.bw250,
        spreadingFactor: LoRaSpreadingFactor.sf10,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    (
      'Australia (Narrow)',
      RadioSettings(
        frequencyMHz: 916.575,
        bandwidth: LoRaBandwidth.bw62_5,
        spreadingFactor: LoRaSpreadingFactor.sf7,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    (
      'Australia SA, WA, QLD',
      RadioSettings(
        frequencyMHz: 923.125,
        bandwidth: LoRaBandwidth.bw62_5,
        spreadingFactor: LoRaSpreadingFactor.sf8,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    (
      'Czech Republic',
      RadioSettings(
        frequencyMHz: 869.432,
        bandwidth: LoRaBandwidth.bw62_5,
        spreadingFactor: LoRaSpreadingFactor.sf7,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 14,
      ),
    ),
    (
      'EU 433MHz',
      RadioSettings(
        frequencyMHz: 433.650,
        bandwidth: LoRaBandwidth.bw250,
        spreadingFactor: LoRaSpreadingFactor.sf11,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    (
      'EU/UK (Long Range)',
      RadioSettings(
        frequencyMHz: 869.525,
        bandwidth: LoRaBandwidth.bw250,
        spreadingFactor: LoRaSpreadingFactor.sf11,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 14,
      ),
    ),
    (
      'EU/UK (Medium Range)',
      RadioSettings(
        frequencyMHz: 869.525,
        bandwidth: LoRaBandwidth.bw250,
        spreadingFactor: LoRaSpreadingFactor.sf10,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 14,
      ),
    ),
    (
      'EU/UK (Narrow)',
      RadioSettings(
        frequencyMHz: 869.618,
        bandwidth: LoRaBandwidth.bw62_5,
        spreadingFactor: LoRaSpreadingFactor.sf8,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 14,
      ),
    ),
    (
      'New Zealand',
      RadioSettings(
        frequencyMHz: 917.375,
        bandwidth: LoRaBandwidth.bw250,
        spreadingFactor: LoRaSpreadingFactor.sf11,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    (
      'New Zealand (Narrow)',
      RadioSettings(
        frequencyMHz: 917.375,
        bandwidth: LoRaBandwidth.bw62_5,
        spreadingFactor: LoRaSpreadingFactor.sf7,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    (
      'Portugal 433',
      RadioSettings(
        frequencyMHz: 433.375,
        bandwidth: LoRaBandwidth.bw62_5,
        spreadingFactor: LoRaSpreadingFactor.sf9,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    (
      'Portugal 869',
      RadioSettings(
        frequencyMHz: 869.618,
        bandwidth: LoRaBandwidth.bw62_5,
        spreadingFactor: LoRaSpreadingFactor.sf7,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 14,
      ),
    ),
    (
      'Switzerland',
      RadioSettings(
        frequencyMHz: 869.618,
        bandwidth: LoRaBandwidth.bw62_5,
        spreadingFactor: LoRaSpreadingFactor.sf8,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 14,
      ),
    ),
    (
      'USA Arizona',
      RadioSettings(
        frequencyMHz: 908.205,
        bandwidth: LoRaBandwidth.bw62_5,
        spreadingFactor: LoRaSpreadingFactor.sf10,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    (
      'USA Southern California',
      RadioSettings(
        frequencyMHz: 927.875,
        bandwidth: LoRaBandwidth.bw62_5,
        spreadingFactor: LoRaSpreadingFactor.sf7,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    (
      'USA/Canada',
      RadioSettings(
        frequencyMHz: 910.525,
        bandwidth: LoRaBandwidth.bw62_5,
        spreadingFactor: LoRaSpreadingFactor.sf7,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    (
      'Vietnam',
      RadioSettings(
        frequencyMHz: 920.250,
        bandwidth: LoRaBandwidth.bw250,
        spreadingFactor: LoRaSpreadingFactor.sf11,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    // Off-grid repeat presets (stock firmware's client repeat frequencies)
    (
      'Off-Grid 433',
      RadioSettings(
        frequencyMHz: 433.0,
        bandwidth: LoRaBandwidth.bw250,
        spreadingFactor: LoRaSpreadingFactor.sf11,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
    (
      'Off-Grid 869',
      RadioSettings(
        frequencyMHz: 869.495,
        bandwidth: LoRaBandwidth.bw250,
        spreadingFactor: LoRaSpreadingFactor.sf11,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 14,
      ),
    ),
    (
      'Off-Grid 918',
      RadioSettings(
        frequencyMHz: 918.0,
        bandwidth: LoRaBandwidth.bw250,
        spreadingFactor: LoRaSpreadingFactor.sf11,
        codingRate: LoRaCodingRate.cr4_5,
        txPowerDbm: 20,
      ),
    ),
  ];

  /// The name of the preset on these numbers, the frequency in kHz as the
  /// radio reports it; null for settings no preset uses.
  static String? presetNameFor(
          {required int freqKHz,
          required int bwHz,
          required int sf,
          required int cr}) =>
      presets
          .where((p) =>
              p.$2.frequencyHz == freqKHz &&
              p.$2.bandwidthHz == bwHz &&
              p.$2.sf == sf &&
              p.$2.cr == cr)
          .firstOrNull
          ?.$1;

  /// Where off-grid repeat moves a radio on [baseMHz]: the allowed frequency
  /// nearest it, from the radio's own list when it gave one. Without a list,
  /// stock firmware's: 869.495 MHz from ver code 13 (1.16), 869.000 before
  /// (MyMesh.cpp repeat_freq_ranges). A range gives its lowest frequency.
  static double offGridFrequencyMHz(
    double baseMHz, {
    List<({int lowerKhz, int upperKhz})>? allowed,
    int? firmwareVerCode,
  }) {
    final eu = firmwareVerCode == null || firmwareVerCode >= 13
        ? 869495
        : 869000;
    final ranges = allowed == null || allowed.isEmpty
        ? [
            (lowerKhz: 433000, upperKhz: 433000),
            (lowerKhz: eu, upperKhz: eu),
            (lowerKhz: 918000, upperKhz: 918000),
          ]
        : allowed;
    final baseKhz = (baseMHz * 1000).round();
    int distance(({int lowerKhz, int upperKhz}) r) => baseKhz < r.lowerKhz
        ? r.lowerKhz - baseKhz
        : baseKhz > r.upperKhz
        ? baseKhz - r.upperKhz
        : 0;
    var best = ranges.first;
    for (final r in ranges.skip(1)) {
      if (distance(r) < distance(best)) best = r;
    }
    return best.lowerKhz / 1000;
  }

  int get frequencyHz => (frequencyMHz * 1000).round();
  int get bandwidthHz => bandwidth.hz;
  int get sf => spreadingFactor.value;
  int get cr => codingRate.value;
}

/// The four numbers that make a mesh: radios hear each other only when all
/// four match. [cr] is 5 to 8 (4/5 to 4/8), whichever way the radio counts.
class LoRaParams {
  final int freqKhz;
  final int bwHz;
  final int sf;
  final int cr;

  const LoRaParams({
    required this.freqKhz,
    required this.bwHz,
    required this.sf,
    required this.cr,
  });

  /// Settings the firmware takes (MyMesh.cpp CMD_SET_RADIO_PARAMS), with a
  /// bandwidth from the app's list.
  bool get isValid =>
      freqKhz >= 150000 &&
      freqKhz <= 2500000 &&
      LoRaBandwidth.values.any((b) => b.hz == bwHz) &&
      sf >= 5 &&
      sf <= 12 &&
      cr >= 5 &&
      cr <= 8;

  String get mhzText => (freqKhz / 1000).toStringAsFixed(3);

  String get khzText => bwHz % 1000 == 0
      ? '${bwHz ~/ 1000}'
      : (bwHz / 1000)
            .toStringAsFixed(2)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceFirst(RegExp(r'\.$'), '');

  /// `918.000 MHz 62.5 kHz SF7 CR5`, as TRAX messages carry it.
  String get wireText => '$mhzText MHz $khzText kHz SF$sf CR$cr';

  /// `918.000 MHz · 62.5 kHz · SF7 · CR5`, for the screen; a number never
  /// wraps away from its unit.
  String get label =>
      '$mhzText\u00A0MHz · $khzText\u00A0kHz · SF$sf · CR$cr';

  @override
  bool operator ==(Object other) =>
      other is LoRaParams &&
      other.freqKhz == freqKhz &&
      other.bwHz == bwHz &&
      other.sf == sf &&
      other.cr == cr;

  @override
  int get hashCode => Object.hash(freqKhz, bwHz, sf, cr);

  @override
  String toString() => wireText;
}
