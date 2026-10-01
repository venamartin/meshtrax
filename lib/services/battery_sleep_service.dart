import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import '../utils/platform_info.dart';

/// Detects Android phones whose battery saver puts MeshTrax to sleep,
/// cutting off the radio link while the app is in the background.
class BatterySleepService {
  static const MethodChannel _channel = MethodChannel('meshtrax/system');

  /// Makers known to stop background apps beyond stock Android
  /// (see dontkillmyapp.com).
  static const _aggressiveMakers = {
    'samsung',
    'xiaomi',
    'redmi',
    'poco',
    'huawei',
    'honor',
    'oneplus',
    'oppo',
    'realme',
    'vivo',
  };

  static Future<String?> manufacturer() async {
    if (!PlatformInfo.isAndroid) return null;
    return _channel.invokeMethod<String>('manufacturer');
  }

  static Future<bool> shouldWarn() async {
    if (!PlatformInfo.isAndroid) return false;
    if (await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
      return false;
    }
    if (_aggressiveMakers.contains(await manufacturer())) return true;
    return await _channel.invokeMethod<bool>('isBackgroundRestricted') ??
        false;
  }

  static Future<void> openSettings() async {
    await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
  }
}
