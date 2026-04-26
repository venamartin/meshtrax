import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/contact.dart';
import '../utils/app_logger.dart';
import '../utils/platform_info.dart';

class ContactBackupService {
  /// Exports contacts to a JSON file.
  /// On Mobile, it uses the native share sheet. On Desktop, it saves to the Documents directory.
  /// Returns the path of the saved file on success (or a generic success string), or null on failure.
  static Future<String?> exportContacts(List<Contact> contacts) async {
    try {
      if (PlatformInfo.isWeb) {
        appLogger.warn('Contact export to file is not fully supported on Web.');
        return null;
      }

      final jsonList = contacts.map((c) => c.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '').split('.')[0];
      final defaultFileName = 'meshtrax_contacts_$timestamp.json';

      if (PlatformInfo.isDesktop) {
        // file_picker 3.x does not support saveFile, so we save to Documents
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$defaultFileName');
        
        await file.writeAsString(jsonString);
        return file.path;
      } else {
        // Use share sheet on mobile
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$defaultFileName');
        
        await file.writeAsString(jsonString);

        final xFile = XFile(file.path, mimeType: 'application/json');
        final result = await Share.shareXFiles([xFile], subject: 'meshtrax Contacts Backup');
        
        return (result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed) 
            ? 'Shared successfully' 
            : null;
      }
    } catch (e) {
      appLogger.error('Failed to export contacts: $e');
      return null;
    }
  }

  /// Reads a JSON backup file at [path] and parses it into a list of Contacts.
  static Future<List<Contact>?> importContactsFromPath(String path) async {
    try {
      final file = File(path.trim());
      if (!await file.exists()) {
        appLogger.error('Backup file not found: $path');
        return null;
      }

      final jsonString = await file.readAsString();
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
}
