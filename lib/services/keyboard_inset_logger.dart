import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_logger.dart';
import '../utils/platform_info.dart';

/// Debug-log lines for the keyboard gap: Android hides the keyboard but the
/// app keeps laying out as if it were still up. Logs every change to the
/// keyboard inset, text-field focus and app lifecycle, and flags a
/// "phantom" inset when Android says the keyboard is hidden but the app
/// still reserves room for it. Logs only; changes nothing.
class KeyboardInsetLogger with WidgetsBindingObserver {
  static const MethodChannel _channel = MethodChannel('meshtrax/system');
  static const _tag = 'Keyboard';

  double _lastInset = 0;
  bool _textFocused = false;

  void start() {
    if (!PlatformInfo.isAndroid) return;
    _lastInset = _insetPx();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_onFocusChange);
  }

  double _insetPx() =>
      WidgetsBinding.instance.platformDispatcher.implicitView?.viewInsets
          .bottom ??
      0;

  double _ratio() =>
      WidgetsBinding.instance.platformDispatcher.implicitView
          ?.devicePixelRatio ??
      1;

  String _dp(double px) => (px / _ratio()).round().toString();

  @override
  void didChangeMetrics() {
    final inset = _insetPx();
    if (inset == _lastInset) return;
    final old = _lastInset;
    _lastInset = inset;
    if (!appLogger.isEnabled) return;
    appLogger.info(
      'inset ${_dp(old)} → ${_dp(inset)} dp',
      tag: _tag,
      noNotify: true,
    );
    if (inset > 0) _checkAfterSettle();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!appLogger.isEnabled) return;
    appLogger.info(
      'app ${state.name}, inset ${_dp(_insetPx())} dp',
      tag: _tag,
      noNotify: true,
    );
    if (state == AppLifecycleState.resumed) _checkAfterSettle();
  }

  void _onFocusChange() {
    final focused = FocusManager.instance.primaryFocus?.context
            ?.findAncestorStateOfType<EditableTextState>() !=
        null;
    if (focused == _textFocused) return;
    _textFocused = focused;
    if (!appLogger.isEnabled) return;
    appLogger.info(
      '${focused ? 'text field focused' : 'text field lost focus'}, '
      'inset ${_dp(_insetPx())} dp',
      tag: _tag,
      noNotify: true,
    );
  }

  /// Waits past the keyboard animation, then compares the app's inset
  /// with what Android reports.
  Future<void> _checkAfterSettle() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final inset = _insetPx();
    if (inset <= 0 || !appLogger.isEnabled) return;
    final Map<Object?, Object?>? ime;
    try {
      ime = await _channel.invokeMethod<Map<Object?, Object?>>('imeState');
    } on PlatformException catch (e) {
      appLogger.warn('imeState failed: ${e.message}', tag: _tag);
      return;
    }
    if (ime == null) return;
    final androidPx = (ime['bottomPx'] as int?) ?? 0;
    if (ime['visible'] == true) {
      appLogger.info(
        'settled: inset ${_dp(inset)} dp, '
        'Android: visible, ${_dp(androidPx.toDouble())} dp',
        tag: _tag,
        noNotify: true,
      );
      return;
    }
    appLogger.warn(
      'phantom keyboard inset ${_dp(inset)} dp '
      '(Android: hidden, ${_dp(androidPx.toDouble())} dp), '
      'text field ${_textFocused ? 'focused' : 'not focused'}',
      tag: _tag,
    );
  }
}
