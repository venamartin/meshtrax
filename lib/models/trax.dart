import 'radio_settings.dart';

/// Which settings TRAX mode moves the radio to.
enum TraxPresetKind {
  /// The off-grid frequency nearest the regular one, with the mesh's own
  /// bandwidth, SF and CR: 918.000 MHz, 62.5 kHz, SF7, CR5 in the US.
  mesh,

  /// The firmware's off-grid preset, 250 kHz and SF11: about 4–5 dB more
  /// link margin for 2.5 to 3 times the airtime. Picked by hand.
  longRange,
}

/// TRAX settings, one set per phone.
class TraxSetup {
  final TraxPresetKind preset;

  /// The trip channel's key ([Channel.idKey]); private channels only.
  final String? channelKey;

  /// The trip's end.
  final DateTime? until;

  /// Post a TRAX message on the trip channel before switching or leaving.
  final bool tellGroup;

  const TraxSetup({
    this.preset = TraxPresetKind.mesh,
    this.channelKey,
    this.until,
    this.tellGroup = true,
  });

  TraxSetup copyWith({
    TraxPresetKind? preset,
    String? Function()? channelKey,
    DateTime? Function()? until,
    bool? tellGroup,
  }) => TraxSetup(
    preset: preset ?? this.preset,
    channelKey: channelKey == null ? this.channelKey : channelKey(),
    until: until == null ? this.until : until(),
    tellGroup: tellGroup ?? this.tellGroup,
  );

  Map<String, dynamic> toJson() => {
    'preset': preset.name,
    'channel': ?channelKey,
    'until': ?until?.millisecondsSinceEpoch,
    'tell': tellGroup,
  };

  static TraxSetup fromJson(Map<String, dynamic> json) => TraxSetup(
    preset:
        TraxPresetKind.values
            .where((k) => k.name == json['preset'])
            .firstOrNull ??
        TraxPresetKind.mesh,
    channelKey: json['channel'] as String?,
    until: switch (json['until']) {
      final int ms => DateTime.fromMillisecondsSinceEpoch(ms),
      _ => null,
    },
    tellGroup: json['tell'] as bool? ?? true,
  );
}

/// A radio's settings from before TRAX mode, as it reported them: [cr] in
/// the radio's own count (5–8, or 1–4 on some firmware).
class TraxSavedRadio {
  final int freqKhz;
  final int bwHz;
  final int sf;
  final int cr;
  final int txPowerDbm;
  final bool repeat;

  const TraxSavedRadio({
    required this.freqKhz,
    required this.bwHz,
    required this.sf,
    required this.cr,
    required this.txPowerDbm,
    required this.repeat,
  });

  LoRaParams get params => LoRaParams(
    freqKhz: freqKhz,
    bwHz: bwHz,
    sf: sf,
    cr: cr <= 4 ? cr + 4 : cr,
  );

  Map<String, dynamic> toJson() => {
    'freq_khz': freqKhz,
    'bw_hz': bwHz,
    'sf': sf,
    'cr': cr,
    'tx_dbm': txPowerDbm,
    'repeat': repeat,
  };

  static TraxSavedRadio? fromJson(Object? json) {
    if (json is! Map) return null;
    final f = json['freq_khz'], b = json['bw_hz'], s = json['sf'];
    final c = json['cr'], t = json['tx_dbm'];
    if (f is! int || b is! int || s is! int || c is! int || t is! int) {
      return null;
    }
    return TraxSavedRadio(
      freqKhz: f,
      bwHz: b,
      sf: s,
      cr: c,
      txPowerDbm: t,
      repeat: json['repeat'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is TraxSavedRadio &&
      other.freqKhz == freqKhz &&
      other.bwHz == bwHz &&
      other.sf == sf &&
      other.cr == cr &&
      other.txPowerDbm == txPowerDbm &&
      other.repeat == repeat;

  @override
  int get hashCode => Object.hash(freqKhz, bwHz, sf, cr, txPowerDbm, repeat);
}

/// One radio's TRAX mode on this phone: what Leave puts back, and when it
/// switched and until when.
class TraxSession {
  final TraxSavedRadio saved;
  final DateTime switchedAt;
  final DateTime? until;

  const TraxSession({
    required this.saved,
    required this.switchedAt,
    this.until,
  });

  Map<String, dynamic> toJson() => {
    'saved': saved.toJson(),
    'switched_at': switchedAt.millisecondsSinceEpoch,
    'until': ?until?.millisecondsSinceEpoch,
  };

  static TraxSession? fromJson(Object? json) {
    if (json is! Map) return null;
    final saved = TraxSavedRadio.fromJson(json['saved']);
    final at = json['switched_at'];
    if (saved == null || at is! int) return null;
    final until = json['until'];
    return TraxSession(
      saved: saved,
      switchedAt: DateTime.fromMillisecondsSinceEpoch(at),
      until: until is int ? DateTime.fromMillisecondsSinceEpoch(until) : null,
    );
  }
}

typedef RepeatRanges = List<({int lowerKhz, int upperKhz})>;

/// TRAX mode in radio terms.
abstract final class Trax {
  /// The logo's orange: the TRAX button while TRAX mode is on.
  static const orange = 0xFFD23E0B;

  /// Stock firmware's off-grid frequencies (MyMesh.cpp repeat_freq_ranges),
  /// with 869.000 MHz from companion 1.13–1.15.
  static const RepeatRanges stockRanges = [
    (lowerKhz: 433000, upperKhz: 433000),
    (lowerKhz: 869000, upperKhz: 869000),
    (lowerKhz: 869495, upperKhz: 869495),
    (lowerKhz: 918000, upperKhz: 918000),
  ];

  static bool isRepeatFrequency(int freqKhz, [RepeatRanges? allowed]) =>
      (allowed == null || allowed.isEmpty ? stockRanges : allowed).any(
        (r) => freqKhz >= r.lowerKhz && freqKhz <= r.upperKhz,
      );

  /// A radio on a TRAX preset: Off-Grid Repeat on, on an off-grid
  /// frequency. Whichever phone or app switched it.
  static bool isOn({
    required bool? clientRepeat,
    required int? freqKhz,
    RepeatRanges? allowed,
  }) =>
      clientRepeat == true &&
      freqKhz != null &&
      isRepeatFrequency(freqKhz, allowed);

  /// The TRAX preset for a radio on [regular].
  static LoRaParams presetFor(
    LoRaParams regular,
    TraxPresetKind kind, {
    RepeatRanges? allowed,
    int? firmwareVerCode,
  }) {
    final freq =
        (RadioSettings.offGridFrequencyMHz(
                  regular.freqKhz / 1000,
                  allowed: allowed,
                  firmwareVerCode: firmwareVerCode,
                ) *
                1000)
            .round();
    return switch (kind) {
      TraxPresetKind.mesh => LoRaParams(
        freqKhz: freq,
        bwHz: regular.bwHz,
        sf: regular.sf,
        cr: regular.cr,
      ),
      TraxPresetKind.longRange => LoRaParams(
        freqKhz: freq,
        bwHz: 250000,
        sf: 11,
        cr: 5,
      ),
    };
  }

  /// The regular presets Leave can return to when this phone saved nothing:
  /// the app's presets without the off-grid ones.
  static List<(String, RadioSettings)> get regularPresets => [
    for (final p in RadioSettings.presets)
      if (!p.$1.startsWith('Off-Grid ')) p,
  ];

  /// The regular preset a radio on [trax] came from, when only one has it
  /// as its TRAX preset: several share 918 MHz, 62.5 kHz and SF7.
  static int? likelyRegularPreset(
    LoRaParams trax, {
    RepeatRanges? allowed,
    int? firmwareVerCode,
  }) {
    final presets = regularPresets;
    int? found;
    for (var i = 0; i < presets.length; i++) {
      final p = presets[i].$2;
      final regular = LoRaParams(
        freqKhz: p.frequencyHz,
        bwHz: p.bandwidthHz,
        sf: p.sf,
        cr: p.cr,
      );
      final candidate = presetFor(
        regular,
        TraxPresetKind.mesh,
        allowed: allowed,
        firmwareVerCode: firmwareVerCode,
      );
      if (candidate != trax) continue;
      if (found != null) return null;
      found = i;
    }
    return found;
  }
}
