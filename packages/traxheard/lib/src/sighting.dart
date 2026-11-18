/// One observer that heard a packet, as its server reports it.
class Sighting {
  const Sighting({
    required this.observer,
    this.snr,
    this.rssi,
    this.hops,
    this.heardAt,
  });

  /// The observer's name, else its id.
  final String observer;

  /// Signal to noise, in dB.
  final double? snr;

  /// Signal strength, in dBm.
  final double? rssi;

  /// Repeaters the packet passed before the observer heard it: 0 when it
  /// heard the sending radio directly. Null when the server didn't say.
  final int? hops;

  final DateTime? heardAt;

  Map<String, Object?> toJson() => {
        'observer': observer,
        if (snr != null) 'snr': snr,
        if (rssi != null) 'rssi': rssi,
        if (hops != null) 'hops': hops,
        if (heardAt != null) 'heardAt': heardAt!.toIso8601String(),
      };

  factory Sighting.fromJson(Map<String, Object?> json) => Sighting(
        observer: json['observer'] as String? ?? '?',
        snr: (json['snr'] as num?)?.toDouble(),
        rssi: (json['rssi'] as num?)?.toDouble(),
        hops: json['hops'] as int?,
        heardAt: DateTime.tryParse(json['heardAt'] as String? ?? ''),
      );
}
