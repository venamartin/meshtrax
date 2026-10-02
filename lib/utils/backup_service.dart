import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/contact.dart';
import '../models/device_backup.dart';
import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';
import '../utils/platform_info.dart';

/// A parsed backup file: either a full device backup or a legacy
/// contacts-only list (the old bare JSON array format).
sealed class ParsedBackup {}

class FullBackup extends ParsedBackup {
  final int version;
  final DateTime? createdAt;
  final String? appVersion;
  final DeviceBackup device;
  final Map<String, dynamic> appSettings;

  FullBackup({
    required this.version,
    this.createdAt,
    this.appVersion,
    required this.device,
    this.appSettings = const {},
  });
}

class LegacyContactsBackup extends ParsedBackup {
  final List<Contact> contacts;

  LegacyContactsBackup(this.contacts);
}

class BackupService {
  static const _format = 'meshtrax_backup';
  static const _version = 1;

  /// App settings included in a backup. Device-bound state (last connected
  /// device, sync cursors) and the legal gate stay out on purpose.
  static const _settingsKeys = {
    'app_settings',
    'chat_text_scale',
    'repeater_passwords',
    'repeater_auto_clock_sync_after_login',
    'room_admin_flags',
    'map_removed_marker_ids',
    'ui_contacts_selected_group',
    'ui_contacts_sort_option',
    'ui_contacts_show_unread_only',
    'ui_contacts_type_filter',
    'ui_channels_sort_option',
    'ui_render_gifs',
    'ui_send_gifs_as_links',
  };
  static const _settingsPrefixes = [
    'channel_order_',
    'contact_smaz_',
    'channel_smaz_',
  ];

  static bool _isBackupSettingsKey(String key) =>
      _settingsKeys.contains(key) || _settingsPrefixes.any(key.startsWith);

  static String _generateBackupFileName() {
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .split('.')[0];
    return 'meshtrax_backup_$timestamp';
  }

  /// Snapshot of the backed-up app settings, with each value tagged by type
  /// so restore can call the matching SharedPreferences setter.
  static Map<String, dynamic> exportAppSettings() {
    final prefs = PrefsManager.instance;
    final out = <String, dynamic>{};
    for (final key in prefs.getKeys()) {
      if (!_isBackupSettingsKey(key)) continue;
      final tagged = switch (prefs.get(key)) {
        String v => {'t': 's', 'v': v},
        bool v => {'t': 'b', 'v': v},
        int v => {'t': 'i', 'v': v},
        double v => {'t': 'd', 'v': v},
        List<Object?> v => {'t': 'sl', 'v': v.whereType<String>().toList()},
        _ => null,
      };
      if (tagged != null) out[key] = tagged;
    }
    return out;
  }

  static Future<void> restoreAppSettings(Map<String, dynamic> settings) async {
    final prefs = PrefsManager.instance;
    for (final entry in settings.entries) {
      final key = entry.key;
      // Only ever write keys this app would itself have backed up.
      if (!_isBackupSettingsKey(key)) continue;
      final tagged = entry.value;
      if (tagged is! Map) continue;
      final v = tagged['v'];
      switch (tagged['t']) {
        case 's':
          if (v is String) await prefs.setString(key, v);
        case 'b':
          if (v is bool) await prefs.setBool(key, v);
        case 'i':
          if (v is num) await prefs.setInt(key, v.toInt());
        case 'd':
          if (v is num) await prefs.setDouble(key, v.toDouble());
        case 'sl':
          if (v is List) {
            await prefs.setStringList(key, v.whereType<String>().toList());
          }
      }
    }
  }

  static Future<String> createBackupJson(DeviceBackup device) async {
    String? appVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {}
    return jsonEncode({
      'format': _format,
      'version': _version,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'appVersion': appVersion,
      'device': device.toJson(),
      'channels': device.channels.map((c) => c.toJson()).toList(),
      'contacts': device.contacts.map((c) => c.toJson()).toList(),
      'appSettings': exportAppSettings(),
    });
  }

  /// Parses either a full backup or a legacy contacts-only array.
  static ParsedBackup? parseBackup(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        return LegacyContactsBackup([
          for (final item in decoded)
            if (item is Map<String, dynamic>) Contact.fromJson(item),
        ]);
      }
      if (decoded is! Map<String, dynamic> || decoded['format'] != _format) {
        return null;
      }
      final deviceJson = decoded['device'] as Map<String, dynamic>? ?? {};
      final channels = [
        for (final item in decoded['channels'] as List? ?? [])
          if (item is Map<String, dynamic>) BackupChannel.fromJson(item),
      ];
      final contacts = [
        for (final item in decoded['contacts'] as List? ?? [])
          if (item is Map<String, dynamic>) BackupContact.fromJson(item),
      ];
      final createdAtRaw = decoded['createdAt'] as String?;
      return FullBackup(
        version: (decoded['version'] as num?)?.toInt() ?? 1,
        createdAt: createdAtRaw != null
            ? DateTime.tryParse(createdAtRaw)
            : null,
        appVersion: decoded['appVersion'] as String?,
        device: DeviceBackup.fromJson(
          deviceJson,
          channels: channels,
          contacts: contacts,
        ),
        appSettings: decoded['appSettings'] as Map<String, dynamic>? ?? {},
      );
    } catch (e) {
      appLogger.error('Failed to parse backup: $e');
      return null;
    }
  }

  /// Saves the backup via the native save dialog (SAF on Android).
  /// Returns the saved path, or null on cancel/error.
  static Future<String?> exportToFile(String jsonString) async {
    try {
      if (PlatformInfo.isWeb) {
        appLogger.warn('Backup export to file is not supported on Web.');
        return null;
      }
      // UTF-8 keeps emoji in node and channel names intact.
      final fileData = Uint8List.fromList(utf8.encode(jsonString));
      final resultPath = await FileSaver.instance.saveAs(
        name: _generateBackupFileName(),
        fileExtension: 'json',
        mimeType: MimeType.json,
        bytes: fileData,
      );
      if (resultPath == null || resultPath.isEmpty) {
        appLogger.warn('Save dialog was canceled by the user.');
        return null;
      }
      return resultPath;
    } catch (e) {
      appLogger.error('Failed to export backup: $e');
      return null;
    }
  }

  static Future<bool> saveToPath(String jsonString, String path) async {
    try {
      await File(path).writeAsString(jsonString, encoding: utf8);
      return true;
    } catch (e) {
      appLogger.error('Failed to save backup to path: $e');
      return false;
    }
  }

  static String suggestedFileName() => '${_generateBackupFileName()}.json';

  static Future<ParsedBackup?> parseBackupFromPath(String path) async {
    try {
      final file = File(path.trim());
      if (!await file.exists()) {
        appLogger.error('Backup file not found: $path');
        return null;
      }
      return parseBackup(await file.readAsString(encoding: utf8));
    } catch (e) {
      appLogger.error('Failed to read backup from path: $e');
      return null;
    }
  }
}
