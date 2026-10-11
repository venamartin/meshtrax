import 'dart:typed_data';

import '../connector/meshcore_protocol.dart';
import 'contact.dart';

/// One contact in a full backup: the app-side record plus the raw signed
/// advert blob the radio needs before it can share/export the contact again.
class BackupContact {
  final Contact contact;
  final Uint8List? rawAdvert;
  final int? lastAdvertTimestamp;

  BackupContact({
    required this.contact,
    this.rawAdvert,
    this.lastAdvertTimestamp,
  });

  Map<String, dynamic> toJson() => {
    ...contact.toJson(),
    'rawAdvert': rawAdvert != null ? pubKeyToHex(rawAdvert!) : null,
    'lastAdvertTimestamp': lastAdvertTimestamp,
  };

  factory BackupContact.fromJson(Map<String, dynamic> json) {
    final rawHex = json['rawAdvert'] as String?;
    return BackupContact(
      contact: Contact.fromJson(json),
      rawAdvert: (rawHex != null && rawHex.isNotEmpty)
          ? hex2Uint8List(rawHex)
          : null,
      lastAdvertTimestamp: (json['lastAdvertTimestamp'] as num?)?.toInt(),
    );
  }
}

class BackupChannel {
  final int index;
  final String name;
  final String pskHex;

  BackupChannel({
    required this.index,
    required this.name,
    required this.pskHex,
  });

  Map<String, dynamic> toJson() => {
    'index': index,
    'name': name,
    'psk': pskHex,
  };

  factory BackupChannel.fromJson(Map<String, dynamic> json) => BackupChannel(
    index: (json['index'] as num).toInt(),
    name: json['name'] as String? ?? '',
    pskHex: json['psk'] as String,
  );
}

class BackupTuning {
  final int rxDelayBase; // x1000
  final int airtimeFactor; // x1000

  BackupTuning({required this.rxDelayBase, required this.airtimeFactor});

  Map<String, dynamic> toJson() => {
    'rxDelayBase': rxDelayBase,
    'airtimeFactor': airtimeFactor,
  };

  factory BackupTuning.fromJson(Map<String, dynamic> json) => BackupTuning(
    rxDelayBase: (json['rxDelayBase'] as num).toInt(),
    airtimeFactor: (json['airtimeFactor'] as num).toInt(),
  );
}

/// Settings whose presence on the companion depends on its firmware.
enum RadioSetting {
  telemetry,
  customVars,
  advertLocPolicy,
  multiAcks,
  autoAdd,
  clientRepeat,
  pathHash,
  autoAddMaxHops,
  floodScope,
}

/// Whether companion firmware [verCode] (and, where ver_code is ambiguous,
/// the version string) speaks [setting]. Verified against the companion_radio
/// tags in ./MeshCore.
bool firmwareSupports(RadioSetting setting, int? verCode, String? version) {
  final vc = verCode ?? 0;
  return switch (setting) {
    RadioSetting.telemetry || RadioSetting.customVars => vc >= 5,
    RadioSetting.advertLocPolicy => vc >= 6,
    // 1.7.3 ships ver_code 7 but still ignores the multi_acks byte.
    RadioSetting.multiAcks => vc >= 7 && !(version ?? '').contains('1.7.3'),
    // ver_code 8 covers 1.10–1.12; only 1.12 has CMD 58/59.
    RadioSetting.autoAdd =>
      vc >= 9 || (vc == 8 && _versionAtLeast(version, 1, 12)),
    RadioSetting.clientRepeat => vc >= 9,
    RadioSetting.pathHash || RadioSetting.autoAddMaxHops => vc >= 10,
    RadioSetting.floodScope => vc >= 11,
  };
}

bool _versionAtLeast(String? version, int major, int minor) {
  final m = RegExp(r'(\d+)\.(\d+)').firstMatch(version ?? '');
  if (m == null) return false;
  final a = int.parse(m.group(1)!);
  final b = int.parse(m.group(2)!);
  return a > major || (a == major && b >= minor);
}

/// Snapshot of everything restorable on the radio over the companion protocol.
/// A null setting means the radio it came from never reported it; restoring
/// such a backup leaves that setting alone on the target.
class DeviceBackup {
  final String? firmwareVersion;
  final int? firmwareVerCode;
  final String publicKeyHex;
  final String? privateKeyHex; // null when the firmware refuses key export
  final String name;
  final int? txPower;
  final double? latitude;
  final double? longitude;
  final int? freqHz;
  final int? bwHz;
  final int? sf;
  final int? cr;
  final bool? clientRepeat;
  final int? pathHashMode;
  final int? multiAcks;
  final int? advertLocPolicy;
  final int? telemetryBase;
  final int? telemetryLoc;
  final int? telemetryEnv;
  final int? manualAddContacts; // raw firmware byte: bit0 set = no auto-add
  final bool? autoAddChat;
  final bool? autoAddRepeater;
  final bool? autoAddRoomServer;
  final bool? autoAddSensor;
  final bool? autoAddOverwriteOldest;
  final int? autoAddMaxHops;
  final bool hasFloodScope; // the radio reported its default scope (maybe none)
  final String? floodScopeName;
  final String? floodScopeKeyHex;
  final BackupTuning? tuning;
  final Map<String, String> customVars;
  final List<BackupChannel> channels;
  final List<BackupContact> contacts;

  DeviceBackup({
    this.firmwareVersion,
    this.firmwareVerCode,
    required this.publicKeyHex,
    this.privateKeyHex,
    required this.name,
    this.txPower,
    this.latitude,
    this.longitude,
    this.freqHz,
    this.bwHz,
    this.sf,
    this.cr,
    this.clientRepeat,
    this.pathHashMode,
    this.multiAcks,
    this.advertLocPolicy,
    this.telemetryBase,
    this.telemetryLoc,
    this.telemetryEnv,
    this.manualAddContacts,
    this.autoAddChat,
    this.autoAddRepeater,
    this.autoAddRoomServer,
    this.autoAddSensor,
    this.autoAddOverwriteOldest,
    this.autoAddMaxHops,
    this.hasFloodScope = false,
    this.floodScopeName,
    this.floodScopeKeyHex,
    this.tuning,
    this.customVars = const {},
    this.channels = const [],
    this.contacts = const [],
  });

  /// Plain-words labels of the settings this backup does not carry.
  List<String> get notSaved => [
    if (telemetryBase == null) 'telemetry sharing',
    if (advertLocPolicy == null) 'location in adverts',
    if (multiAcks == null) 'multiple acks',
    if (autoAddChat == null) 'contact auto-add',
    if (autoAddMaxHops == null) 'auto-add hop limit',
    if (clientRepeat == null) 'client repeat',
    if (pathHashMode == null) 'path hash size',
    if (!hasFloodScope) 'default flood scope',
    if (tuning == null) 'tuning',
  ];

  Map<String, dynamic> toJson() => {
    'firmwareVersion': firmwareVersion,
    'firmwareVerCode': firmwareVerCode,
    'publicKey': publicKeyHex,
    'privateKey': privateKeyHex,
    'name': name,
    'txPower': txPower,
    'latitude': latitude,
    'longitude': longitude,
    'radio': {
      'freqHz': freqHz,
      'bwHz': bwHz,
      'sf': sf,
      'cr': cr,
      'clientRepeat': clientRepeat,
    },
    'pathHashMode': pathHashMode,
    'multiAcks': multiAcks,
    'advertLocPolicy': advertLocPolicy,
    'telemetry': {
      'base': telemetryBase,
      'loc': telemetryLoc,
      'env': telemetryEnv,
    },
    'manualAddContacts': manualAddContacts,
    'autoAdd': {
      'chat': autoAddChat,
      'repeater': autoAddRepeater,
      'roomServer': autoAddRoomServer,
      'sensor': autoAddSensor,
      'overwriteOldest': autoAddOverwriteOldest,
      'maxHops': autoAddMaxHops,
    },
    if (hasFloodScope)
      'floodScope': {'name': floodScopeName, 'key': floodScopeKeyHex},
    'tuning': tuning?.toJson(),
    'customVars': customVars,
  };

  factory DeviceBackup.fromJson(
    Map<String, dynamic> json, {
    List<BackupChannel> channels = const [],
    List<BackupContact> contacts = const [],
  }) {
    final radio = json['radio'] as Map<String, dynamic>? ?? {};
    final telemetry = json['telemetry'] as Map<String, dynamic>? ?? {};
    final autoAdd = json['autoAdd'] as Map<String, dynamic>? ?? {};
    final tuningJson = json['tuning'] as Map<String, dynamic>?;
    final verCode = (json['firmwareVerCode'] as num?)?.toInt();
    final version = json['firmwareVersion'] as String?;
    // Files written before the app gated on firmware carry made-up values
    // for settings the radio never had; drop anything it couldn't have sent.
    bool had(RadioSetting s) => firmwareSupports(s, verCode, version);
    T? only<T>(RadioSetting s, T? value) => had(s) ? value : null;

    final floodScope = json['floodScope'] as Map<String, dynamic>?;
    return DeviceBackup(
      firmwareVersion: version,
      firmwareVerCode: verCode,
      publicKeyHex: json['publicKey'] as String? ?? '',
      privateKeyHex: json['privateKey'] as String?,
      name: json['name'] as String? ?? '',
      txPower: (json['txPower'] as num?)?.toInt(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      freqHz: (radio['freqHz'] as num?)?.toInt(),
      bwHz: (radio['bwHz'] as num?)?.toInt(),
      sf: (radio['sf'] as num?)?.toInt(),
      cr: (radio['cr'] as num?)?.toInt(),
      clientRepeat: only(
        RadioSetting.clientRepeat,
        radio['clientRepeat'] as bool?,
      ),
      pathHashMode: only(
        RadioSetting.pathHash,
        (json['pathHashMode'] as num?)?.toInt(),
      ),
      multiAcks: only(
        RadioSetting.multiAcks,
        (json['multiAcks'] as num?)?.toInt(),
      ),
      advertLocPolicy: only(
        RadioSetting.advertLocPolicy,
        (json['advertLocPolicy'] as num?)?.toInt(),
      ),
      telemetryBase: only(
        RadioSetting.telemetry,
        (telemetry['base'] as num?)?.toInt(),
      ),
      telemetryLoc: only(
        RadioSetting.telemetry,
        (telemetry['loc'] as num?)?.toInt(),
      ),
      telemetryEnv: only(
        RadioSetting.telemetry,
        (telemetry['env'] as num?)?.toInt(),
      ),
      manualAddContacts: (json['manualAddContacts'] as num?)?.toInt(),
      autoAddChat: only(RadioSetting.autoAdd, autoAdd['chat'] as bool?),
      autoAddRepeater: only(RadioSetting.autoAdd, autoAdd['repeater'] as bool?),
      autoAddRoomServer: only(
        RadioSetting.autoAdd,
        autoAdd['roomServer'] as bool?,
      ),
      autoAddSensor: only(RadioSetting.autoAdd, autoAdd['sensor'] as bool?),
      autoAddOverwriteOldest: only(
        RadioSetting.autoAdd,
        autoAdd['overwriteOldest'] as bool?,
      ),
      autoAddMaxHops: only(
        RadioSetting.autoAddMaxHops,
        (autoAdd['maxHops'] as num?)?.toInt(),
      ),
      hasFloodScope: floodScope != null && had(RadioSetting.floodScope),
      floodScopeName: floodScope?['name'] as String?,
      floodScopeKeyHex: floodScope?['key'] as String?,
      tuning: tuningJson != null ? BackupTuning.fromJson(tuningJson) : null,
      customVars: (json['customVars'] as Map<String, dynamic>? ?? {}).map(
        (k, v) => MapEntry(k, v.toString()),
      ),
      channels: channels,
      contacts: contacts,
    );
  }
}

enum RestoreStep { identity, settings, channels, contacts, resync }

enum PrivateKeyImportResult { ok, error, disabled }

/// What actually happened during a restore, for the summary dialog.
class RestoreReport {
  bool identityRestored = false;
  bool identityUnsupported = false;
  bool identityMissing = false;
  final List<String> failures = [];

  /// Settings left as they were, and why. Information, not problems.
  final List<String> notes = [];
  int channelsWritten = 0;
  int channelsDropped = 0;
  int contactsWritten = 0;
  int advertsReplayed = 0;

  bool get hasFailures => failures.isNotEmpty;
}
