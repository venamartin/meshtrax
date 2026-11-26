import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../storage/app_debug_log_store.dart';

enum AppDebugLogLevel { info, warning, error }

class AppDebugLogEntry {
  final DateTime timestamp;
  final AppDebugLogLevel level;
  final String tag;
  final String message;

  AppDebugLogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
  });

  String get levelLabel {
    switch (level) {
      case AppDebugLogLevel.info:
        return 'INFO';
      case AppDebugLogLevel.warning:
        return 'WARN';
      case AppDebugLogLevel.error:
        return 'ERROR';
    }
  }

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}.'
        '${timestamp.millisecond.toString().padLeft(3, '0')}';
  }

  /// Full local date + time. The log ring buffer can span days, and a bare
  /// HH:MM:SS from yesterday reads as today's.
  String get formattedDateTime {
    return '${timestamp.year}-'
        '${timestamp.month.toString().padLeft(2, '0')}-'
        '${timestamp.day.toString().padLeft(2, '0')} '
        '$formattedTime';
  }

  /// One export/copy line: `[date time] [LEVEL] [tag] message`.
  String get formattedLine =>
      '[$formattedDateTime] [$levelLabel] [$tag] $message';
}

class AppDebugLogService extends ChangeNotifier {
  AppDebugLogService({this._store});

  // A day of field logging: a 2-hour hike filled 673 lines (2026-10-16).
  static const int maxEntries = 20000;
  final List<AppDebugLogEntry> _entries = [];

  /// Keeps the lines between runs; null where there are no files (the web).
  final AppDebugLogStore? _store;
  int _clears = 0;
  bool _enabled = false;

  List<AppDebugLogEntry> get entries => List.unmodifiable(_entries);
  bool get enabled => _enabled;

  /// Entries at [minLevel] or more severe — the level filter authority, so
  /// the screen never re-implements severity ordering.
  List<AppDebugLogEntry> entriesAtOrAbove(AppDebugLogLevel minLevel) {
    if (minLevel == AppDebugLogLevel.info) return entries;
    return List.unmodifiable(
      _entries.where((e) => e.level.index >= minLevel.index),
    );
  }

  /// The export text for [entries], oldest first.
  static String buildExportText(Iterable<AppDebugLogEntry> entries) =>
      entries.map((e) => e.formattedLine).join('\n');

  /// [buildExportText] under a line naming the build the log came from.
  static Future<String> buildExport(Iterable<AppDebugLogEntry> entries) async {
    return 'MeshTrax ${await _build()} ${defaultTargetPlatform.name} debug '
        'log, exported ${DateTime.now()}\n${buildExportText(entries)}';
  }

  static Future<String> _build() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      // No package info here (tests, a bare desktop binary).
      return 'unknown build';
    }
  }

  /// Puts the lines kept from earlier runs ahead of this run's, which get a
  /// line naming their build: one log can hold the lines of several builds.
  /// Call it once, as logging starts.
  Future<void> restore() async {
    final store = _store;
    if (store == null) return;
    final clears = _clears;
    final loading = store.load();
    info('MeshTrax ${await _build()} started');
    final earlier = await loading;
    // Cleared while the files were read: those lines are gone as well.
    if (clears != _clears || earlier.isEmpty) return;
    _entries.insertAll(0, earlier);
    _trim();
    notifyListeners();
  }

  void setEnabled(bool value) {
    _enabled = value;
    notifyListeners();
  }

  void log(
    String message, {
    String tag = 'App',
    AppDebugLogLevel level = AppDebugLogLevel.info,
    bool noNotify = false,
  }) {
    if (!_enabled && !kDebugMode) return;
    if (!_enabled) {
      // In debug mode, still print to console but don't store entries.
      debugPrint('[$tag] $message');
      return;
    }

    final entry = AppDebugLogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
    );
    _entries.add(entry);
    _store?.add(entry);
    _trim();

    if (!noNotify) {
      notifyListeners();
    }

    // Also print to console for development
    debugPrint('[$tag] $message');
  }

  void info(String message, {String tag = 'App', bool noNotify = false}) {
    log(message, tag: tag, level: AppDebugLogLevel.info, noNotify: noNotify);
  }

  void warn(String message, {String tag = 'App', bool noNotify = false}) {
    log(message, tag: tag, level: AppDebugLogLevel.warning, noNotify: noNotify);
  }

  void error(String message, {String tag = 'App', bool noNotify = false}) {
    log(message, tag: tag, level: AppDebugLogLevel.error, noNotify: noNotify);
  }

  void clear() {
    _entries.clear();
    _clears++;
    _store?.clear();
    notifyListeners();
  }

  void _trim() {
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
  }
}
