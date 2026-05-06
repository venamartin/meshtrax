import '../utils/platform_info.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class BackgroundService {
  bool _initialized = false;

  Future<void> initialize() async {
    if (!PlatformInfo.isAndroid || _initialized) return;
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
        allowWifiLock: false,
      ),
    );
    _initialized = true;
  }

  Future<void> start() async {
    if (!PlatformInfo.isAndroid) return;
    if (!_initialized) {
      await initialize();
    }
    final running = await FlutterForegroundTask.isRunningService;
    if (running) return;
    await FlutterForegroundTask.startService(
      notificationTitle: 'MeshTrax running',
      notificationText: 'Keeping BLE connected',
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
