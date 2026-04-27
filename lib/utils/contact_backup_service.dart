import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';

import '../models/contact.dart';
import '../utils/app_logger.dart';
import '../utils/platform_info.dart';

class ContactBackupService {
  /// Internal helper to generate a standardized backup filename.
  static String _generateBackupFileName() {
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '').split('.')[0];
    return 'meshtrax_contacts_$timestamp';
  }

  /// Internal helper to serialize contacts to a JSON string.
  static String _serializeContacts(List<Contact> contacts) {
    final jsonList = contacts.map((c) => c.toJson()).toList();
    return jsonEncode(jsonList);
  }

  /// Exports contacts to a JSON file.
  /// Uses file_saver to trigger the native OS save dialog on ALL platforms.
  static Future<String?> exportContacts(List<Contact> contacts) async {
    try {
      if (PlatformInfo.isWeb) {
        appLogger.warn('Contact export to file is not fully supported on Web.');
        return null;
      }

      final jsonString = _serializeContacts(contacts);
      
      // FIX APPLIED: Safely encode the JSON string as UTF-8 to preserve all 
      // emojis and 16-bit surrogate pairs (e.g., node icons like 🍓 or 🤖).
      final fileData = Uint8List.fromList(utf8.encode(jsonString));
      
      final baseFileName = _generateBackupFileName();

      // Trigger the native Save dialog
      // On Android, this opens SAF allowing you to select the Documents folder natively.
      final resultPath = await FileSaver.instance.saveAs(
        name: baseFileName,
        fileExtension: 'json',
        mimeType: MimeType.json,
        bytes: fileData,
      );

      // resultPath will be empty/null if the user cancels
      if (resultPath == null || resultPath.isEmpty) {
        appLogger.warn('Save dialog was canceled by the user.');
        return null;
      }

      return resultPath;
    } catch (e) {
      appLogger.error('Failed to export contacts: $e');
      return null;
    }
  }

  /// Saves contacts to a specific file path.
  static Future<bool> saveContactsToPath(List<Contact> contacts, String path) async {
    try {
      final jsonString = _serializeContacts(contacts);
      final file = File(path);
      // Explicitly enforce UTF-8 when writing raw strings to disk
      await file.writeAsString(jsonString, encoding: utf8);
      return true;
    } catch (e) {
      appLogger.error('Failed to save contacts to path: $e');
      return false;
    }
  }

  /// Reads a JSON backup file at [path] and parses it into a list of Contacts.
  /// Note: When importing via file_selector on Android, prefer using XFile.readAsString()
  /// directly in your UI code to avoid Scoped Storage path restrictions.
  static Future<List<Contact>?> importContactsFromPath(String path) async {
    try {
      final file = File(path.trim());
      if (!await file.exists()) {
        appLogger.error('Backup file not found: $path');
        return null;
      }

      // Explicitly enforce UTF-8 decoding when reading
      final jsonString = await file.readAsString(encoding: utf8);
      return importContactsFromJson(jsonString);
    } catch (e) {
      appLogger.error('Failed to import contacts from path: $e');
      return null;
    }
  }

  /// Parses a JSON string and returns a list of Contacts.
  static List<Contact>? importContactsFromJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        throw const FormatException('Expected a list of contacts in JSON');
      }

      final contacts = decoded.map((item) {
        if (item is Map<String, dynamic>) {
          return Contact.fromJson(item);
        }
        throw const FormatException('Invalid contact format in JSON');
      }).toList();

      return contacts;
    } catch (e) {
      appLogger.error('Failed to parse contacts JSON: $e');
      return null;
    }
  }

  /// Lists all JSON backup files in both internal and external storage.
  static Future<List<File>> listBackups() async {
    try {
      final searchDirs = <Directory>[];
      
      // Internal storage
      searchDirs.add(await getApplicationDocumentsDirectory());
      
      // External storage (Android visible)
      if (Platform.isAndroid) {
        final extDir = await getExternalStorageDirectory();
        if (extDir != null) searchDirs.add(extDir);
      }

      final backups = <File>[];

      for (final dir in searchDirs) {
        if (!await dir.exists()) continue;
        
        try {
          final files = dir.listSync();
          for (final entity in files) {
            if (entity is File && 
                entity.path.endsWith('.json') && 
                entity.path.split(Platform.pathSeparator).last.startsWith('meshtrax_contacts_')) {
              backups.add(entity);
            }
          }
        } catch (e) {
          appLogger.warn('Could not list directory ${dir.path}: $e');
        }
      }

      // Sort by modified date (newest first)
      backups.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      
      return backups;
    } catch (e) {
      appLogger.error('Failed to list backups: $e');
      return [];
    }
  }
}