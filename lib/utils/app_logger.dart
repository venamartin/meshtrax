import 'package:flutter/foundation.dart';
import '../services/app_debug_log_service.dart';


/// Global app logger instance
/// Usage: appLogger.info('Message', tag: 'MyClass');
class AppLogger {
  AppDebugLogService? _service;
  bool _enabled = false;

  /// Initialize the logger with the debug log service
  void initialize(AppDebugLogService service, {bool enabled = false}) {
    _service = service;
    _enabled = enabled;
    _service?.setEnabled(enabled);
  }

  /// Update whether logging is enabled
  void setEnabled(bool enabled) {
    _enabled = enabled;
    _service?.setEnabled(enabled);
  }

  /// Check if logging is currently enabled
  bool get isEnabled => _enabled;

  /// Log an info message
  void info(String message, {String tag = 'App', bool noNotify = false}) {
    if (_enabled && _service != null) {
      _service!.info(message, tag: tag, noNotify: noNotify);
    } else {
      debugPrint('[$tag] INFO: $message');
    }
  }

  /// Log a warning message
  void warn(String message, {String tag = 'App', bool noNotify = false}) {
    if (_enabled && _service != null) {
      _service!.warn(message, tag: tag, noNotify: noNotify);
    } else {
      debugPrint('[$tag] WARN: $message');
    }
  }

  /// Log an error message
  void error(String message, {String tag = 'App', bool noNotify = false}) {
    if (_enabled && _service != null) {
      _service!.error(message, tag: tag, noNotify: noNotify);
    } else {
      debugPrint('[$tag] ERROR: $message');
    }
  }

  /// [perf] and the UI stall lines are built in only with
  /// `--dart-define=MESHTRAX_PERF=true` (`PERF=1 ./buildapk.sh`).
  static const perfEnabled = bool.fromEnvironment('MESHTRAX_PERF');

  /// One line when a step took a frame (16 ms) or longer, nothing
  /// otherwise, and nothing at all while the log is off. Wall time: a step
  /// that awaits the database includes the wait, so read these next to the
  /// UI stall lines, which are the UI thread's own figures.
  void perf(String what, Stopwatch sw, {String detail = ''}) {
    if (!perfEnabled || !_enabled || sw.elapsedMilliseconds < 16) return;
    final suffix = detail.isEmpty ? '' : ' ($detail)';
    info('$what ${sw.elapsedMilliseconds} ms$suffix', tag: 'Perf', noNotify: true);
  }

  /// Log a message with custom level
  void log(
    String message, {
    String tag = 'App',
    AppDebugLogLevel level = AppDebugLogLevel.info,
    bool noNotify = false,
  }) {
    if (_enabled && _service != null) {
      _service!.log(message, tag: tag, level: level, noNotify: noNotify);
    }
  }
}

/// Global logger instance
final appLogger = AppLogger();
