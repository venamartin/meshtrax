import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';

import '../services/app_debug_log_service.dart';
import '../utils/platform_info.dart';
import 'app_logger.dart';

/// Saves the app debug log as a text file via the native OS save dialog
/// (same flow as ContactBackupService).
class DebugLogExport {
  /// Returns the saved path, or null when unsupported or cancelled.
  static Future<String?> saveToFile(List<AppDebugLogEntry> entries) async {
    try {
      if (PlatformInfo.isWeb) {
        appLogger.warn('Debug log export to file is not supported on Web.');
        return null;
      }

      final text = AppDebugLogService.buildExportText(entries);
      final data = Uint8List.fromList(utf8.encode(text));

      final resultPath = await FileSaver.instance.saveAs(
        name: _fileName(DateTime.now()),
        fileExtension: 'txt',
        mimeType: MimeType.text,
        bytes: data,
      );

      if (resultPath == null || resultPath.isEmpty) {
        return null;
      }
      return resultPath;
    } catch (e) {
      appLogger.error('Failed to export debug log: $e');
      return null;
    }
  }

  static String _fileName(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'meshtrax_debug_log_'
        '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
