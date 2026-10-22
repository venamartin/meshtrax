import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'helpers/snack_bar_builder.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';
import 'package:provider/provider.dart';


import 'screens/chrome_required_screen.dart';
import 'utils/platform_info.dart';

import 'connector/meshcore_connector.dart';
import 'models/channel.dart';
import 'models/contact.dart';
import 'screens/chat_screen.dart';
import 'screens/channel_chat_screen.dart';
import 'screens/scanner_screen.dart';
import 'services/storage_service.dart';
import 'services/message_retry_service.dart';
import 'services/path_graph/path_graph_service.dart';
import 'services/app_settings_service.dart';
import 'services/notification_service.dart';
import 'services/companion_cli_service.dart';
import 'services/ble_debug_log_service.dart';
import 'services/app_debug_log_service.dart';
import 'services/background_service.dart';
import 'services/map_tile_cache_service.dart';
import 'services/phone_location_service.dart';
import 'services/map_packs_service.dart';
import 'services/chat_text_scale_service.dart';
import 'services/ui_view_state_service.dart';
import 'storage/prefs_manager.dart';
import 'utils/app_logger.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences cache
  await PrefsManager.initialize();

  // Initialize services
  final storage = StorageService();
  final connector = MeshCoreConnector();
  final pathGraphService = PathGraphService();
  final retryService = MessageRetryService();
  final appSettingsService = AppSettingsService();
  final bleDebugLogService = BleDebugLogService();
  final appDebugLogService = AppDebugLogService();
  final backgroundService = BackgroundService();
  final mapTileCacheService = MapTileCacheService();
  final chatTextScaleService = ChatTextScaleService();
  final uiViewStateService = UiViewStateService();

  // Load settings
  await appSettingsService.loadSettings();

  // Initialize app logger
  appLogger.initialize(
    appDebugLogService,
    enabled: appSettingsService.settings.appDebugLogEnabled,
  );

  // UI stall reporter: a debug-log line for every frame that took 50 ms or
  // longer (three dropped frames), at most two a second so one long stall
  // cannot flood the ring buffer. Flutter collects these timings anyway;
  // this only reads them.
  var lastStallLog = DateTime.fromMillisecondsSinceEpoch(0);
  SchedulerBinding.instance.addTimingsCallback((timings) {
    if (!appLogger.isEnabled) return;
    for (final t in timings) {
      final total = t.totalSpan.inMilliseconds;
      if (total < 50) continue;
      final now = DateTime.now();
      if (now.difference(lastStallLog).inMilliseconds < 500) continue;
      lastStallLog = now;
      appLogger.info(
        'UI stall $total ms (build ${t.buildDuration.inMilliseconds}, '
        'raster ${t.rasterDuration.inMilliseconds})',
        tag: 'Perf',
        noNotify: true,
      );
    }
  });

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await backgroundService.initialize();
  // Clear any orphaned foreground service from a previously killed instance
  await backgroundService.stop();
  _registerThirdPartyLicenses();

  await chatTextScaleService.initialize();
  await uiViewStateService.initialize();

  // Wire up connector with services
  connector.initialize(
    retryService: retryService,
    appSettingsService: appSettingsService,
    bleDebugLogService: bleDebugLogService,
    appDebugLogService: appDebugLogService,
    backgroundService: backgroundService,
  );

  // The path graph is an observe-only hook on the raw frame stream; it
  // runs only while its debug setting is on.
  Future<void> syncPathGraph() => appSettingsService.settings.pathGraphEnabled
      ? pathGraphService.start(connector)
      : pathGraphService.stop();
  appSettingsService.addListener(syncPathGraph);
  await syncPathGraph();

  // Offline map packs: cached catalogue, installed packs, and downloads
  // restored from the last run. Pack storage doesn't exist on the web.
  final mapPacksService = PlatformInfo.isWeb
      ? null
      : await MapPacksService.create(appSettingsService);

  await connector.loadContactCache();
  // Channel settings and messages are keyed by channel identity, so the
  // cached channel list must load first.
  await connector.loadCachedChannels();
  await connector.loadChannelSettings();

  // Channel messages live in the database and reach the UI through watched
  // queries — nothing to preload (Phase 3d).

  runApp(
    MeshTraxApp(
      connector: connector,
      pathGraphService: pathGraphService,
      retryService: retryService,
      storage: storage,
      appSettingsService: appSettingsService,
      bleDebugLogService: bleDebugLogService,
      appDebugLogService: appDebugLogService,
      mapTileCacheService: mapTileCacheService,
      mapPacksService: mapPacksService,
      chatTextScaleService: chatTextScaleService,
      uiViewStateService: uiViewStateService,
    ),
  );
}

void _registerThirdPartyLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      <String>['Open-Meteo Elevation API Data'],
      '''
Data used by LOS elevation lookups is provided by Open-Meteo.

Open-Meteo terms and attribution:
https://open-meteo.com/en/terms

Elevation API:
https://open-meteo.com/en/docs/elevation-api

Attribution license reference:
Creative Commons Attribution 4.0 International (CC BY 4.0)
https://creativecommons.org/licenses/by/4.0/
''',
    );
  });
}

class MeshTraxApp extends StatefulWidget {
  final MeshCoreConnector connector;
  final PathGraphService pathGraphService;
  final MessageRetryService retryService;
  final StorageService storage;
  final AppSettingsService appSettingsService;
  final BleDebugLogService bleDebugLogService;
  final AppDebugLogService appDebugLogService;
  final MapTileCacheService mapTileCacheService;

  /// Null on the web, where offline maps aren't available.
  final MapPacksService? mapPacksService;
  final ChatTextScaleService chatTextScaleService;
  final UiViewStateService uiViewStateService;

  const MeshTraxApp({
    super.key,
    required this.connector,
    required this.pathGraphService,
    required this.retryService,
    required this.storage,
    required this.appSettingsService,
    required this.bleDebugLogService,
    required this.appDebugLogService,
    required this.mapTileCacheService,
    required this.mapPacksService,
    required this.chatTextScaleService,
    required this.uiViewStateService,
  });

  @override
  State<MeshTraxApp> createState() => _MeshTraxAppState();
}

class _MeshTraxAppState extends State<MeshTraxApp> {
  late final AppLifecycleListener _lifecycleListener;
  late final StreamSubscription<BlockedCliCommand> _blockedCliSubscription;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: () => NotificationService().cancelAll(),
      onDetach: () => widget.connector.disconnect(manual: true),
    );
    // Notifications don't show on desktop; the snackbar covers every
    // platform while the app is open.
    _blockedCliSubscription = widget.connector.blockedCliCommands.listen((
      blocked,
    ) {
      final context = NotificationService.navigatorKey.currentContext;
      if (context == null || !context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(
          context.l10n.companionCli_blocked(
            blocked.contactName,
            blocked.command,
          ),
        ),
      );
    });

    // Route notification taps to the relevant chat, and handle a notification
    // that cold-started the app once the first frame is ready.
    NotificationService().onNotificationTap = _handleNotificationTap;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pending = NotificationService().consumePendingLaunchPayload();
      if (pending != null) _handleNotificationTap(pending);
    });
  }

  void _handleNotificationTap(String payload) {
    final navigator = NotificationService.navigatorKey.currentState;
    if (navigator == null) return;
    final connector = widget.connector;

    if (payload.startsWith('mention:')) {
      // mention:<channelIndex>:<messageId> — open the channel AND land on
      // the message the user was mentioned in.
      final rest = payload.substring('mention:'.length);
      final cut = rest.indexOf(':');
      if (cut <= 0) return;
      final index = int.tryParse(rest.substring(0, cut));
      final messageId = rest.substring(cut + 1);
      if (index == null || messageId.isEmpty) return;
      Channel? channel;
      for (final c in connector.channels) {
        if (c.index == index) {
          channel = c;
          break;
        }
      }
      if (channel == null) return;
      navigator.push(
        MaterialPageRoute(
          builder: (_) => ChannelChatScreen(
            channel: channel!,
            scrollToMessageId: messageId,
          ),
        ),
      );
    } else if (payload.startsWith('channel:')) {
      final index = int.tryParse(payload.substring('channel:'.length));
      if (index == null) return;
      Channel? channel;
      for (final c in connector.channels) {
        if (c.index == index) {
          channel = c;
          break;
        }
      }
      if (channel == null) return;
      navigator.push(
        MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: channel!)),
      );
    } else {
      Contact? contact;
      for (final c in connector.contacts) {
        if (c.publicKeyHex == payload) {
          contact = c;
          break;
        }
      }
      if (contact == null) return;
      navigator.push(
        MaterialPageRoute(builder: (_) => ChatScreen(contact: contact!)),
      );
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    _blockedCliSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.connector),
        ChangeNotifierProvider.value(value: widget.pathGraphService),
        ChangeNotifierProvider.value(value: widget.retryService),
        ChangeNotifierProvider.value(value: widget.appSettingsService),
        ChangeNotifierProvider.value(value: widget.bleDebugLogService),
        ChangeNotifierProvider.value(value: widget.appDebugLogService),
        ChangeNotifierProvider.value(value: widget.chatTextScaleService),
        ChangeNotifierProvider.value(value: widget.uiViewStateService),
        Provider.value(value: widget.storage),
        Provider.value(value: widget.mapTileCacheService),
        if (widget.mapPacksService case final maps?)
          ChangeNotifierProvider.value(value: maps),
        ChangeNotifierProvider(create: (_) => PhoneLocationService()),
      ],
      child: Consumer<AppSettingsService>(
        builder: (context, settingsService, child) {
          return MaterialApp(
            navigatorKey: NotificationService.navigatorKey,
            title: 'MeshTrax',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: _localeFromSetting(
              settingsService.settings.languageOverride,
            ),
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
              fontFamily: 'DejaVu Sans',
              fontFamilyFallback: const ['Noto Color Emoji'],
              snackBarTheme: const SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
              ),
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              fontFamily: 'DejaVu Sans',
              fontFamilyFallback: const ['Noto Color Emoji'],
              snackBarTheme: const SnackBarThemeData(
                behavior: SnackBarBehavior.floating,
              ),
            ),
            themeMode: _themeModeFromSetting(
              settingsService.settings.themeMode,
            ),
            builder: (context, child) {
              // Update notification service with resolved locale
              final locale = Localizations.localeOf(context);
              NotificationService().setLocale(locale);
              final l10n = AppLocalizations.of(context);
              widget.mapPacksService?.setNotificationTitles(
                running: l10n.offlineMaps_notificationRunning,
                paused: l10n.offlineMaps_notificationPaused,
                failed: l10n.offlineMaps_notificationFailed,
              );
              return child ?? const SizedBox.shrink();
            },
            home: (PlatformInfo.isWeb && !PlatformInfo.isChrome)
                ? const ChromeRequiredScreen()
                : const ScannerScreen(),
          );
        },
      ),
    );
  }

  ThemeMode _themeModeFromSetting(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Locale? _localeFromSetting(String? languageCode) {
    if (languageCode == null) return null;
    return Locale(languageCode);
  }
}
