import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../services/app_debug_log_service.dart';
import '../utils/platform_info.dart';

/// Keeps the app debug log's lines in files, so they are still there after
/// the app restarts or a new build is installed.
///
/// New lines go to `app.log`. At [maxLines] it becomes `app.1.log`, in place
/// of the one before, so the two files always hold the newest [maxLines]
/// lines and never more than twice that.
class AppDebugLogStore {
  AppDebugLogStore(
    this.directory, {
    this.maxLines = AppDebugLogService.maxEntries,
  });

  /// The store in this device's cache folder, which no device backup takes;
  /// null where there are no files (the web) or no such folder.
  static Future<AppDebugLogStore?> open() async {
    if (PlatformInfo.isWeb) return null;
    try {
      final cache = await getApplicationCacheDirectory();
      return AppDebugLogStore(Directory('${cache.path}/debug_log'));
    } on Object {
      return null;
    }
  }

  final Directory directory;
  final int maxLines;

  /// New lines wait this long to be written together, so a stop of the app
  /// loses the lines of its last second at most.
  static const writeDelay = Duration(seconds: 1);

  static const _currentName = 'app.log';
  static const _previousName = 'app.1.log';

  final List<String> _waiting = [];
  Timer? _timer;
  Future<void> _work = Future.value();
  int _currentLines = 0;

  void add(AppDebugLogEntry entry) {
    _waiting.add(
      jsonEncode({
        't': entry.timestamp.millisecondsSinceEpoch,
        'l': entry.level.name,
        'g': entry.tag,
        'm': entry.message,
      }),
    );
    _timer ??= Timer(writeDelay, flush);
  }

  /// Writes the waiting lines now; completes when they are in the file.
  Future<void> flush() {
    _timer?.cancel();
    _timer = null;
    if (_waiting.isEmpty) return _work;
    final lines = List.of(_waiting);
    _waiting.clear();
    return _then(() async {
      await directory.create(recursive: true);
      final current = File('${directory.path}/$_currentName');
      // Every line starts on a new one, so a line that a stop of the app
      // cut short spoils only itself.
      await current.writeAsString(
        '\n${lines.join('\n')}',
        mode: FileMode.append,
      );
      _currentLines += lines.length;
      if (_currentLines < maxLines) return;
      await current.rename('${directory.path}/$_previousName');
      _currentLines = 0;
    });
  }

  /// The lines kept from earlier runs, oldest first. For the start of a
  /// run: called later, it returns what this run has written as well.
  Future<List<AppDebugLogEntry>> load() async {
    var earlier = const <AppDebugLogEntry>[];
    await _then(() async {
      // Most people never turn the log on: nothing to read, no isolate.
      if (!await directory.exists()) return;
      final (entries, currentLines) = await compute(
        _read,
        (directory.path, maxLines),
      );
      earlier = entries;
      _currentLines = currentLines;
    });
    return earlier;
  }

  /// Forgets every line, waiting or written.
  Future<void> clear() {
    _timer?.cancel();
    _timer = null;
    _waiting.clear();
    return _then(() async {
      if (await directory.exists()) await directory.delete(recursive: true);
      _currentLines = 0;
    });
  }

  /// One file step after another. A step that fails (a full disk, a folder
  /// taken away) costs its lines, never the app.
  Future<void> _then(Future<void> Function() step) {
    return _work = _work.then((_) async {
      try {
        await step();
      } on Object catch (e) {
        debugPrint('Debug log file: $e');
      }
    });
  }

  /// Off the UI thread: the newest [maxLines] lines of both files, and how
  /// many lines the current file holds.
  static (List<AppDebugLogEntry>, int) _read((String, int) args) {
    final (dir, maxLines) = args;
    final current = _linesOf(File('$dir/$_currentName'));
    final lines = [
      if (current.length < maxLines) ..._linesOf(File('$dir/$_previousName')),
      ...current,
    ];
    final entries = lines
        .skip(max(0, lines.length - maxLines))
        .map(_decode)
        .nonNulls
        .toList();
    return (entries, current.length);
  }

  static List<String> _linesOf(File file) {
    if (!file.existsSync()) return const [];
    // A stop of the app can cut a character in half: read it as damaged
    // text, and the one line it is in fails to decode.
    final text = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
    return const LineSplitter()
        .convert(text)
        .where((line) => line.isNotEmpty)
        .toList();
  }

  static AppDebugLogEntry? _decode(String line) {
    try {
      final json = jsonDecode(line) as Map<String, dynamic>;
      return AppDebugLogEntry(
        timestamp: DateTime.fromMillisecondsSinceEpoch(json['t'] as int),
        level: AppDebugLogLevel.values.byName(json['l'] as String),
        tag: json['g'] as String,
        message: json['m'] as String,
      );
    } on Object {
      // Cut short by a stop of the app.
      return null;
    }
  }
}
