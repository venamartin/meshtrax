import 'dart:typed_data';

import '../connector/meshcore_protocol.dart';
import '../models/device_backup.dart';

/// One settings write of a restore. [retry] is sent instead if [frame] is
/// refused, and [retryNote] then explains what changed.
typedef RestoreWrite = ({
  String label,
  Uint8List frame,
  Uint8List? retry,
  String? retryNote,
});

/// Decides which settings frames a restore sends to the connected radio.
///
/// A setting is written only when the backup carries it AND the target
/// firmware understands it; otherwise it is left as-is and a plain-words
/// note says why. Pure so the firmware matrix is unit-testable.
({List<RestoreWrite> writes, List<String> notes}) planRestoreSettings(
  DeviceBackup backup, {
  required int? targetVerCode,
  required String? targetVersion,
  required bool? currentClientRepeat,
  required int currentManualAddByte,
  required int currentTelemetryByte,
  required int currentAdvertLocPolicy,
  required int currentMultiAcks,
}) {
  final writes = <RestoreWrite>[];
  final notes = <String>[];
  bool targetHas(RadioSetting s) =>
      firmwareSupports(s, targetVerCode, targetVersion);
  const notInBackup = 'not in the backup';
  const unsupported = "not supported by this radio's firmware";
  void note(String what, String why) => notes.add('$what ($why)');
  void write(String label, Uint8List frame) =>
      writes.add((label: label, frame: frame, retry: null, retryNote: null));

  write('Name', buildSetAdvertNameFrame(backup.name));

  if (backup.freqHz != null &&
      backup.bwHz != null &&
      backup.sf != null &&
      backup.cr != null) {
    Uint8List radio(bool? repeat) => buildSetRadioParamsFrame(
      backup.freqHz!,
      backup.bwHz!,
      backup.sf!,
      backup.cr!,
      clientRepeat: repeat,
    );
    if (targetHas(RadioSetting.clientRepeat)) {
      // Omitting the byte on v9+ firmware would turn repeat OFF.
      final repeat = backup.clientRepeat ?? currentClientRepeat ?? false;
      writes.add((
        label: 'Radio settings',
        frame: radio(repeat),
        // Repeat is refused outright on an off-grid frequency, which would
        // lose the frequency, bandwidth, SF and CR with it.
        retry: repeat ? radio(false) : null,
        retryNote:
            'Client repeat was turned off: the backed-up frequency '
            'is not allowed for repeating',
      ));
      if (backup.clientRepeat == null) note('Client repeat', notInBackup);
    } else {
      write('Radio settings', radio(null));
    }
  }

  if (backup.txPower != null) {
    write('Transmit power', buildSetRadioTxPowerFrame(backup.txPower!));
  }
  if (backup.latitude != null && backup.longitude != null) {
    write(
      'Location',
      buildSetAdvertLatLonFrame(backup.latitude!, backup.longitude!),
    );
  }

  if (!targetHas(RadioSetting.pathHash)) {
    note('Path hash size', unsupported);
  } else if (backup.pathHashMode == null) {
    note('Path hash size', notInBackup);
  } else {
    write('Path hash size', buildSetPathHashModeFrame(backup.pathHashMode!));
  }

  final targetHasAutoAdd = targetHas(RadioSetting.autoAdd);
  if ((targetVerCode ?? 0) >= 4) {
    final telemetry = backup.telemetryBase != null
        ? (backup.telemetryEnv! << 4) |
              (backup.telemetryLoc! << 2) |
              backup.telemetryBase!
        : currentTelemetryByte;
    if (backup.telemetryBase == null && targetHas(RadioSetting.telemetry)) {
      note('Telemetry sharing', notInBackup);
    }
    if (backup.advertLocPolicy == null &&
        targetHas(RadioSetting.advertLocPolicy)) {
      note('Location in adverts', notInBackup);
    }
    if (backup.multiAcks == null && targetHas(RadioSetting.multiAcks)) {
      note('Multiple acks', notInBackup);
    }
    write(
      'Telemetry and advert settings',
      buildSetOtherParamsFrame(
        telemetry,
        backup.advertLocPolicy ?? currentAdvertLocPolicy,
        backup.multiAcks ?? currentMultiAcks,
        manualAdd: _manualAddByte(
          backup,
          targetHasAutoAdd: targetHasAutoAdd,
          current: currentManualAddByte,
          note: note,
        ),
      ),
    );
  } else {
    note('Telemetry and advert settings', unsupported);
  }

  if (!targetHasAutoAdd) {
    // On/off-only firmware: handled by the manual-add byte above.
  } else if (backup.autoAddChat == null) {
    note('Contact auto-add', notInBackup);
  } else {
    final sendHops =
        backup.autoAddMaxHops != null && targetHas(RadioSetting.autoAddMaxHops);
    if (!sendHops && targetHas(RadioSetting.autoAddMaxHops)) {
      note('Auto-add hop limit', notInBackup);
    }
    write(
      'Contact auto-add settings',
      buildSetAutoAddConfigFrame(
        autoAddChat: backup.autoAddChat!,
        autoAddRepeater: backup.autoAddRepeater!,
        autoAddRoomServer: backup.autoAddRoomServer!,
        autoAddSensor: backup.autoAddSensor!,
        overwriteOldest: backup.autoAddOverwriteOldest!,
        maxHops: sendHops ? backup.autoAddMaxHops : null,
      ),
    );
  }

  if (!targetHas(RadioSetting.floodScope)) {
    note('Default flood scope', unsupported);
  } else if (!backup.hasFloodScope) {
    note('Default flood scope', notInBackup);
  } else {
    final keyHex = backup.floodScopeKeyHex;
    write(
      'Default flood scope',
      buildSetDefaultFloodScopeFrame(
        backup.floodScopeName,
        keyHex != null ? hex2Uint8List(keyHex) : null,
      ),
    );
  }

  if (backup.tuning != null) {
    write(
      'Tuning settings',
      buildSetTuningParamsFrame(
        backup.tuning!.rxDelayBase,
        backup.tuning!.airtimeFactor,
      ),
    );
  }

  if (backup.customVars.isNotEmpty) {
    if (targetHas(RadioSetting.customVars)) {
      for (final entry in backup.customVars.entries) {
        write(
          'Setting ${entry.key}',
          buildSetCustomVarFrame('${entry.key}:${entry.value}'),
        );
      }
    } else {
      note('Radio settings ${backup.customVars.keys.join(', ')}', unsupported);
    }
  }

  return (writes: writes, notes: notes);
}

/// Byte 1 of CMD_SET_OTHER_PARAMS. On per-type firmware (1.12+) MeshTrax
/// keeps the radio in manual mode and filters with the auto-add flags, so
/// the byte is always 1 there — writing 0 would make the connector's
/// _checkManualAddContacts overwrite the flags just restored. Older firmware
/// only knows on/off, so derive that from the flags when the backup has them.
int _manualAddByte(
  DeviceBackup backup, {
  required bool targetHasAutoAdd,
  required int current,
  required void Function(String what, String why) note,
}) {
  if (targetHasAutoAdd) return 1;
  final flags = [
    backup.autoAddChat,
    backup.autoAddRepeater,
    backup.autoAddRoomServer,
    backup.autoAddSensor,
  ];
  if (flags.every((f) => f == true)) return 0;
  if (flags.every((f) => f == false)) return 1;
  if (flags.any((f) => f != null)) {
    note(
      'Contact auto-add',
      'this radio can only turn it on or off, and the backup allows some '
          'types but not others',
    );
    return current;
  }
  if (backup.manualAddContacts == null) {
    note('Contact auto-add', 'not in the backup');
  }
  return backup.manualAddContacts ?? current;
}
