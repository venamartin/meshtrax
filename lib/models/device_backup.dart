import 'dart:typed_data';

import '../connector/meshcore_protocol.dart';
import 'contact.dart';

/// One contact in a full backup: the app-side record plus the raw signed
/// advert blob the radio needs before it can share/export the contact again.
class BackupContact {
  final Contact contact;
  final Uint8List? rawAdvert;
  final int? lastAdvertTimestamp;

  BackupContact({required this.contact, this.rawAdvert, this.lastAdvertTimestamp});

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

  BackupChannel({required this.index, required this.name, required this.pskHex});

  Map<String, dynamic> toJson() => {'index': index, 'name': name, 'psk': pskHex};

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

  Map<String, dynamic> toJson() =>
      {'rxDelayBase': rxDelayBase, 'airtimeFactor': airtimeFactor};

  factory BackupTuning.fromJson(Map<String, dynamic> json) => BackupTuning(
        rxDelayBase: (json['rxDelayBase'] as num).toInt(),
        airtimeFactor: (json['airtimeFactor'] as num).toInt(),
      );
}

/// Snapshot of everything restorable on the radio over the companion protocol.
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
  final int pathHashMode;
  final int multiAcks;
  final int advertLocPolicy;
  final int telemetryBase;
  final int telemetryLoc;
  final int telemetryEnv;
  final bool autoAddChat;
  final bool autoAddRepeater;
  final bool autoAddRoomServer;
  final bool autoAddSensor;
  final bool autoAddOverwriteOldest;
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
    required this.pathHashMode,
    required this.multiAcks,
    required this.advertLocPolicy,
    required this.telemetryBase,
    required this.telemetryLoc,
    required this.telemetryEnv,
    required this.autoAddChat,
    required this.autoAddRepeater,
    required this.autoAddRoomServer,
    required this.autoAddSensor,
    required this.autoAddOverwriteOldest,
    this.tuning,
    this.customVars = const {},
    this.channels = const [],
    this.contacts = const [],
  });

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
        'autoAdd': {
          'chat': autoAddChat,
          'repeater': autoAddRepeater,
          'roomServer': autoAddRoomServer,
          'sensor': autoAddSensor,
          'overwriteOldest': autoAddOverwriteOldest,
        },
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
    return DeviceBackup(
      firmwareVersion: json['firmwareVersion'] as String?,
      firmwareVerCode: (json['firmwareVerCode'] as num?)?.toInt(),
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
      clientRepeat: radio['clientRepeat'] as bool?,
      pathHashMode: (json['pathHashMode'] as num?)?.toInt() ?? 0,
      multiAcks: (json['multiAcks'] as num?)?.toInt() ?? 0,
      advertLocPolicy: (json['advertLocPolicy'] as num?)?.toInt() ?? 0,
      telemetryBase: (telemetry['base'] as num?)?.toInt() ?? 1,
      telemetryLoc: (telemetry['loc'] as num?)?.toInt() ?? 0,
      telemetryEnv: (telemetry['env'] as num?)?.toInt() ?? 0,
      autoAddChat: autoAdd['chat'] as bool? ?? true,
      autoAddRepeater: autoAdd['repeater'] as bool? ?? true,
      autoAddRoomServer: autoAdd['roomServer'] as bool? ?? true,
      autoAddSensor: autoAdd['sensor'] as bool? ?? true,
      autoAddOverwriteOldest: autoAdd['overwriteOldest'] as bool? ?? false,
      tuning: tuningJson != null ? BackupTuning.fromJson(tuningJson) : null,
      customVars: (json['customVars'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, v.toString())),
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
  int channelsWritten = 0;
  int channelsDropped = 0;
  int contactsWritten = 0;
  int advertsReplayed = 0;

  bool get hasFailures => failures.isNotEmpty;
}
