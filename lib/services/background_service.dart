import '../utils/platform_info.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BackgroundService {
  bool _initialized = false;
  bool _wifiLock = false;

  /// [wifiLock] holds the WiFi radio awake while the service runs. TCP needs
  /// it: without it the socket stalls once the screen is off. BLE does not,
  /// and the lock costs battery, so it is off by default.
  Future<void> initialize({bool wifiLock = false}) async {
    if (!PlatformInfo.isAndroid) return;
    if (_initialized && _wifiLock == wifiLock) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'meshtrax_background',
        channelName: 'MeshTrax Background',
        channelDescription: 'Keeps MeshTrax running in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWifiLock: wifiLock,
      ),
    );
    _initialized = true;
    _wifiLock = wifiLock;
  }

  Future<void> start({bool wifiLock = false}) async {
    if (!PlatformInfo.isAndroid) return;
    final running = await FlutterForegroundTask.isRunningService;
    if (running && _wifiLock == wifiLock) return;
    // A BLE→TCP switch without a manual disconnect leaves the service up
    // without the lock; restart it with the right options.
    if (running) await FlutterForegroundTask.stopService();
    await initialize(wifiLock: wifiLock);
    await FlutterForegroundTask.startService(
      notificationTitle: 'MeshTrax running',
      notificationText: 'Keeping radio connected',
      notificationIcon: const NotificationIcon(metaDataName: 'com.meshtrax.notification.icon'),
      callback: startCallback,
    );
  }

  Future<void> stop() async {
    if (!PlatformInfo.isAndroid) return;
    final running = await FlutterForegroundTask.isRunningService;
    if (!running) return;
    await FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_MeshTraxTaskHandler());
}

class _MeshTraxTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
  }
}
