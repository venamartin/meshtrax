import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../services/app_debug_log_service.dart';
import '../utils/platform_info.dart';

/// Keeps the app debug log's lines in files, so they are still there after
/// the app restarts or a new build is installed, for the weeks a field log
/// is collected: about two weeks of lines at a heavy day's pace.
///
/// New lines go to `app.log`. At [maxLines] it becomes `app.1.log`, in place
/// of the one before, so the two files always hold the newest [maxLines]
/// lines and never more than twice that. Only the newest [loadLines] come
/// back into memory at the start of a run; an export reads the files.
class AppDebugLogStore {
  AppDebugLogStore(
    this.directory, {
    this.maxLines = fileLines,
    this.loadLines = AppDebugLogService.maxEntries,
  });

  /// Lines per file before it is turned over: two weeks of a heavy day's
  /// logging fit in the two files, 20 to 40 MB.
  static const int fileLines = 150000;

  /// The store in the app's own support folder, which the system never
  /// empties to free space (a cache folder it may). Left out of device
  /// backups on Android (backup_rules.xml, data_extraction_rules.xml). A
  /// log kept in the cache folder by an earlier build moves here. Null
  /// where there are no files (the web) or no such folder.
  static Future<AppDebugLogStore?> open() async {
    if (PlatformInfo.isWeb) return null;
    try {
      final support = await getApplicationSupportDirectory();
      final directory = Directory('${support.path}/$folderName');
      await _moveFromCache(directory);
      return AppDebugLogStore(directory);
    } on Object {
      return null;
    }
  }

  static const folderName = 'debug_log';

  static Future<void> _moveFromCache(Directory to) async {
    try {
      final cache = await getApplicationCacheDirectory();
      final from = Directory('${cache.path}/$folderName');
      if (!await from.exists() || await to.exists()) return;
      await to.parent.create(recursive: true);
      await from.rename(to.path);
    } on Object {
      // A different volume, or no cache folder: the old lines stay behind.
    }
  }

  final Directory directory;
  final int maxLines;
  final int loadLines;

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

  /// The newest [loadLines] lines kept from earlier runs, oldest first. For
  /// the start of a run: called later, it returns what this run has written
  /// as well.
  Future<List<AppDebugLogEntry>> load() async {
    var earlier = const <AppDebugLogEntry>[];
    await _then(() async {
      // Most people never turn the log on: nothing to read, no isolate.
      if (!await directory.exists()) return;
      final (entries, currentLines) = await compute(
        _read,
        (directory.path, loadLines),
      );
      earlier = entries;
      _currentLines = currentLines;
    });
    return earlier;
  }

  /// Writes every line the files keep, at [minLevel] or more severe and
  /// oldest first, to the file at [path] under [header], one formatted line
  /// each; nothing of it is held in memory. False when it could not be
  /// written.
  Future<bool> exportTo(
    String path, {
    required String header,
    AppDebugLogLevel minLevel = AppDebugLogLevel.info,
  }) async {
    await flush();
    var done = false;
    final dir = directory.path;
    final level = minLevel.index;
    await _then(() async {
      await Isolate.run(() => _export(dir, path, header, level));
      done = true;
    });
    return done;
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

  /// Off the UI thread: the newest [loadLines] lines of both files, and how
  /// many lines the current file holds. Only those lines are decoded.
  static (List<AppDebugLogEntry>, int) _read((String, int) args) {
    final (dir, loadLines) = args;
    final current = _bytesOf(File('$dir/$_currentName'));
    final lines = _lastLines(current, loadLines);
    if (lines.length < loadLines) {
      lines.insertAll(
        0,
        _lastLines(
          _bytesOf(File('$dir/$_previousName')),
          loadLines - lines.length,
        ),
      );
    }
    return (lines.map(_decode).nonNulls.toList(), _countLines(current));
  }

  static Uint8List _bytesOf(File file) =>
      file.existsSync() ? file.readAsBytesSync() : Uint8List(0);

  static const _newline = 0x0A;

  /// How many lines [bytes] hold, empty ones not counted.
  static int _countLines(Uint8List bytes) {
    var count = 0;
    var inLine = false;
    for (final b in bytes) {
      if (b == _newline) {
        inLine = false;
      } else if (!inLine) {
        inLine = true;
        count++;
      }
    }
    return count;
  }

  /// The last [n] lines of [bytes], oldest first, empty ones skipped. A stop
  /// of the app can cut a character in half: it is read as damaged text, and
  /// the one line it is in fails to decode.
  static List<String> _lastLines(Uint8List bytes, int n) {
    final lines = <String>[];
    var end = bytes.length;
    for (var i = bytes.length - 1; i >= -1 && lines.length < n; i--) {
      if (i >= 0 && bytes[i] != _newline) continue;
      if (end > i + 1) {
        lines.add(utf8.decode(bytes.sublist(i + 1, end), allowMalformed: true));
      }
      end = i;
    }
    return lines.reversed.toList();
  }

  static Future<void> _export(
    String dir,
    String path,
    String header,
    int minLevel,
  ) async {
    final sink = File(path).openWrite();
    try {
      sink.writeln(header);
      for (final name in [_previousName, _currentName]) {
        final file = File('$dir/$name');
        if (!await file.exists()) continue;
        final lines = file
            .openRead()
            .transform(const Utf8Decoder(allowMalformed: true))
            .transform(const LineSplitter());
        await for (final line in lines) {
          if (line.isEmpty) continue;
          final entry = _decode(line);
          if (entry == null || entry.level.index < minLevel) continue;
          sink.writeln(entry.formattedLine);
        }
      }
    } finally {
      await sink.close();
    }
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
