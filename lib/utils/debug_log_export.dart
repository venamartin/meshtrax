import 'dart:io';

import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';

import '../services/app_debug_log_service.dart';
import '../utils/platform_info.dart';
import 'app_logger.dart';

/// Saves the app debug log as a text file via the native OS save dialog
/// (same flow as BackupService). The log is written to a file first and
/// handed over by its path, so weeks of lines never sit in memory at once.
class DebugLogExport {
  /// Returns the saved path, or null when unsupported or cancelled.
  static Future<String?> saveToFile(
    AppDebugLogService log, {
    AppDebugLogLevel minLevel = AppDebugLogLevel.info,
  }) async {
    if (PlatformInfo.isWeb) {
      appLogger.warn('Debug log export to file is not supported on Web.');
      return null;
    }
    File? temp;
    try {
      final now = DateTime.now();
      final dir = await getTemporaryDirectory();
      temp = File('${dir.path}/${_fileName(now)}.txt');
      if (!await log.exportToFile(temp.path, minLevel: minLevel)) return null;

      final resultPath = await FileSaver.instance.saveAs(
        name: _fileName(now),
        fileExtension: 'txt',
        mimeType: MimeType.text,
        filePath: temp.path,
      );

      if (resultPath == null || resultPath.isEmpty) {
        return null;
      }
      return resultPath;
    } catch (e) {
      appLogger.error('Failed to export debug log: $e');
      return null;
    } finally {
      try {
        await temp?.delete();
      } on Object {
        // Already gone, or the temporary folder is cleaned up by the system.
      }
    }
  }

  static String _fileName(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return 'meshtrax_debug_log_'
        '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
