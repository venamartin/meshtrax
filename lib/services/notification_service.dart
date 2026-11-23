import 'dart:async';
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart' show MaterialPageRoute;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:url_launcher/url_launcher.dart';

import '../helpers/date_time_helper.dart';
import '../helpers/gif_helper.dart';
import '../helpers/markdown_helper.dart';
import '../helpers/reaction_helper.dart';
import '../helpers/structured_message.dart';
import '../l10n/app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Global navigator key so a notification tap can navigate. Wired onto the
  /// app's [MaterialApp] and used by the tap handler set in the app.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Tells the chat screens when a page covers them or comes off them. Wired
  /// onto the app's [MaterialApp]; dialogs and sheets aren't pages.
  static final RouteObserver<PageRoute<dynamic>> routeObserver =
      RouteObserver<PageRoute<dynamic>>();

  /// The pages showing a chat (a DM, a room or a channel), each added by its
  /// chat screen and removed when it goes.
  static final Set<Route<dynamic>> chatRoutes = {};

  /// Opens [chat] from a notification the way other messaging apps do: in
  /// place of the chat pages on top, so taps one after another never stack
  /// chats and Back leaves the chat. Any other page stays where it is, since
  /// one may be in the middle of something (a backup saves its file only
  /// while Settings is open).
  static void openChat(NavigatorState navigator, Widget chat) {
    navigator.popUntil((r) => r.isFirst || !chatRoutes.contains(r));
    navigator.push(MaterialPageRoute(builder: (_) => chat));
  }

  /// Set by the app to handle a tapped notification's payload (navigation).
  void Function(String payload)? onNotificationTap;

  /// Payload of the notification that cold-started the app, if any.
  String? _pendingLaunchPayload;

  /// Returns and clears any payload from a notification that launched the app.
  String? consumePendingLaunchPayload() {
    final payload = _pendingLaunchPayload;
    _pendingLaunchPayload = null;
    return payload;
  }

  // Locale for localized notification strings
  Locale _locale = const Locale('en');

  /// The app's language is known from its first frame on; a time can't be
  /// written in it before.
  bool _localeKnown = false;

  /// Set the locale for notification strings (call when app locale changes)
  void setLocale(Locale locale) {
    final changed = !_localeKnown || locale != _locale;
    _locale = locale;
    _localeKnown = true;
    // The user's own SOS in the shade speaks the app's language.
    if (changed) unawaited(_postMySos());
  }

  AppLocalizations get _l10n => lookupAppLocalizations(_locale);

  /// The app's language, for text written away from any screen.
  Locale get locale => _locale;

  // Rate limiting to prevent notification storms
  // (Added after getting notification-flooded while evaluating RF flood management. The irony.)
  static const _minNotificationInterval = Duration(seconds: 3);
  static const _batchWindow = Duration(seconds: 5);

  DateTime? _lastNotificationTime;
  final List<_PendingNotification> _pendingNotifications = [];
  bool _isBatchingActive = false;
  bool _suppressNotifications = false;

  /// Temporarily suppress all notifications (e.g., during sync)
  void suppressNotifications(bool suppress) {
    _suppressNotifications = suppress;
    if (suppress) {
      _pendingNotifications.clear();
    }
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Skip notification initialization on Windows and Linux (plugin not supported)
    if (Platform.isWindows || Platform.isLinux) {
      _isInitialized = true;
      debugPrint('Notifications unavailable on this platform');
      return;
    }

    const androidSettings = AndroidInitializationSettings('ic_notification');
    // Permissions are requested from [requestPermissions] once the UI is up,
    // not here: initialization runs before runApp() and awaiting the Darwin
    // authorization prompt would leave the app blank until it is answered.
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: handleTap,
    );
    // Test builds 215-224 made the SOS category with the alarm sound.
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.deleteNotificationChannel(channelId: 'meshtrax_sos');

    // Capture a notification that cold-started the app so the payload can be
    // routed once the UI is ready.
    final launchDetails = await _notifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      final response = launchDetails?.notificationResponse;
      if (response != null) _keepGotIt(response);
      _pendingLaunchPayload = response == null ? null : tapPayload(response);
    }

    _isInitialized = true;
    debugPrint('Notifications initialized (mobile platform)');
  }

  Future<bool> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  Future<bool> requestPermissions() async {
    if (!_isInitialized) {
      await initialize();
    }

    // Notifications are unavailable on these desktop platforms.
    if (Platform.isWindows || Platform.isLinux) {
      return true;
    }

    // On Android 13+ (API 33+) POST_NOTIFICATIONS is a runtime permission and
    // must be requested explicitly; without it the foreground-service and
    // message notifications are hidden.
    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      return granted ?? false;
    }

    if (Platform.isIOS) {
      final ios = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    if (Platform.isMacOS) {
      final macos = _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      final granted = await macos?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    return true;
  }

  /// False when the device blocks this app's messages, in whole or in part;
  /// null where that can't be known.
  Future<bool?> notificationsAllowed() async {
    if (Platform.isWindows || Platform.isLinux) return null;
    await _ensureInitialized();
    if (Platform.isAndroid) {
      final android = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final allowed = await android?.areNotificationsEnabled();
      if (allowed != true) return allowed;
      // Android can also block one category; mentions share the channel one.
      // A category does not exist until its first notification.
      final categories = await android?.getNotificationChannels() ?? const [];
      return !categories.any(
        (c) =>
            (c.id == 'meshtrax_messages' || c.id == 'meshtrax_channels') &&
            c.importance == Importance.none,
      );
    }
    if (Platform.isIOS) {
      final options = await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return options == null ? null : options.isEnabled && options.isAlertEnabled;
    }
    if (Platform.isMacOS) {
      final options = await _notifications
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.checkPermissions();
      return options == null ? null : options.isEnabled && options.isAlertEnabled;
    }
    return null;
  }

  /// Asks the device to allow notifications. One that was refused before won't
  /// ask again and answers at once, so this opens its settings instead. A
  /// slower no is the user's own answer to the prompt, so it stops there. With
  /// the permission granted, a blocked category or alerts turned off can still
  /// keep [notificationsAllowed] false, and only the settings page changes that.
  Future<void> askToAllow() async {
    final asked = Stopwatch()..start();
    if (await requestPermissions()) {
      if (await notificationsAllowed() != false) return;
    } else if (asked.elapsed > const Duration(seconds: 1)) {
      return;
    }
    if (Platform.isAndroid) {
      await const MethodChannel(
        'meshtrax/system',
      ).invokeMethod<void>('openNotificationSettings');
    } else if (Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
    } else if (Platform.isMacOS) {
      await launchUrl(
        Uri.parse(
          'x-apple.systempreferences:com.apple.preference.notifications',
        ),
      );
    }
  }

  /// The category SOS alerts go out on, and nothing else (Android). Its
  /// sound, vibration and importance are fixed when it is first made, so
  /// they live in [sosChannel] and [sosAndroidDetails] alike, and a new
  /// sound needs a new id.
  static const sosChannelId = 'meshtrax_sos_morse';

  /// The Got it button on a channel's SOS notification.
  static const sosGotItAction = 'sos_got_it';

  static final _sosVibration =
      Int64List.fromList([0, 1200, 400, 1200, 400, 1200]);

  /// "SOS" in Morse, twice (tool/make_sos_sound.py), played as an alarm.
  static const _sosSound = RawResourceAndroidNotificationSound('sos_morse');

  /// Android lets a category through Do Not Disturb only when the user says
  /// so in its settings ([openSosSettings]); asking for it here takes
  /// effect only for an app holding notification policy access.
  static AndroidNotificationChannel sosChannel(AppLocalizations l10n) =>
      AndroidNotificationChannel(
        sosChannelId,
        l10n.notification_sosChannel,
        description: l10n.notification_sosChannelDescription,
        importance: Importance.max,
        bypassDnd: true,
        sound: _sosSound,
        vibrationPattern: _sosVibration,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      );

  /// [silent]: an update that must not sound again (a cancel). [gotIt]:
  /// with a Got it button, which opens the app to send it. The button
  /// leaves the alert up: the app takes it away once Got it went, and with
  /// the radio away nothing went.
  @visibleForTesting
  static AndroidNotificationDetails sosAndroidDetails(
    AppLocalizations l10n, {
    bool silent = false,
    bool gotIt = false,
  }) {
    final channel = sosChannel(l10n);
    return AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.description,
      importance: channel.importance,
      priority: Priority.max,
      channelBypassDnd: channel.bypassDnd,
      sound: channel.sound,
      enableVibration: true,
      vibrationPattern: channel.vibrationPattern,
      audioAttributesUsage: channel.audioAttributesUsage,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      silent: silent,
      actions: gotIt
          ? [
              AndroidNotificationAction(
                sosGotItAction,
                l10n.sos_gotIt,
                showsUserInterface: true,
                cancelNotification: false,
              ),
            ]
          : null,
    );
  }

  /// What the SOS category may do on this phone, for the settings row.
  Future<SosAlertState> sosAlertState() async {
    if (!Platform.isAndroid) return SosAlertState.unknown;
    if (!await _ensureInitialized()) return SosAlertState.unknown;
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (await android?.areNotificationsEnabled() == false) {
      return SosAlertState.blocked;
    }
    final categories = await android?.getNotificationChannels() ?? const [];
    final sos = categories.where((c) => c.id == sosChannelId).firstOrNull;
    if (sos == null) return SosAlertState.silencedByDnd;
    if (sos.importance == Importance.none) return SosAlertState.blocked;
    return sos.bypassDnd
        ? SosAlertState.throughDnd
        : SosAlertState.silencedByDnd;
  }

  /// The SOS category's own settings page (Android), made first so the
  /// page exists, where "Override Do Not Disturb" is switched on; the app's
  /// settings elsewhere.
  Future<void> openSosSettings() async {
    if (Platform.isAndroid) {
      await _ensureInitialized();
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(sosChannel(_l10n));
      await const MethodChannel('meshtrax/system').invokeMethod<void>(
        'openNotificationChannelSettings',
        {'channelId': sosChannelId},
      );
    } else if (Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
    } else if (Platform.isMacOS) {
      await launchUrl(
        Uri.parse(
          'x-apple.systempreferences:com.apple.preference.notifications',
        ),
      );
    }
  }

  /// The category TRAX mode's reminder goes out on: an ordinary one, not
  /// an alarm.
  static const traxChannelId = 'meshtrax_trax';

  /// The reminder at the trip's end, clear of the message ids, and what its
  /// tap hands the app.
  static const traxEndedId = 0x5445; // 'TE'
  static const traxEndedPayload = 'traxended';

  @visibleForTesting
  static AndroidNotificationDetails traxAndroidDetails(AppLocalizations l10n) =>
      AndroidNotificationDetails(
        traxChannelId,
        l10n.trax_title,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

  /// Switch too and Leave too on a member's TRAX message (Android). Each
  /// opens the app to ask TRAX mode's question; nothing switches from here.
  static const traxFollowAction = 'trax_follow';
  static const traxLeaveAction = 'trax_leave';

  /// The category channel messages go out on, with TRAX mode's button when
  /// [traxAction] names one.
  @visibleForTesting
  static AndroidNotificationDetails channelAndroidDetails(
    AppLocalizations l10n, {
    String? traxAction,
  }) => AndroidNotificationDetails(
    'meshtrax_channels',
    l10n.appSettings_channelMessageNotifications,
    importance: Importance.max,
    priority: Priority.high,
    groupKey: _groupKey,
    actions: traxAction == null
        ? null
        : [
            AndroidNotificationAction(
              traxAction,
              traxAction == traxFollowAction
                  ? l10n.trax_switchToo
                  : l10n.trax_leaveToo,
              showsUserInterface: true,
            ),
          ],
  );

  /// A channel message with TRAX mode's button, one per channel and clear
  /// of the other ids, so the chat after it doesn't take the button away.
  @visibleForTesting
  static int traxNotificationId(int channelIndex) => 0x5500 + channelIndex;

  /// The alarm volume an SOS alert sounds at, and its most (Android); null
  /// elsewhere, or when the phone doesn't say.
  Future<({int volume, int max})?> alarmVolume() async {
    if (!Platform.isAndroid) return null;
    final alarm = await const MethodChannel('meshtrax/system')
        .invokeMapMethod<String, int>('getAlarmVolume');
    final volume = alarm?['volume'], max = alarm?['max'];
    return volume == null || max == null ? null : (volume: volume, max: max);
  }

  /// The phone's sound settings, where the alarm volume is (Android).
  Future<void> openSoundSettings() async {
    if (!Platform.isAndroid) return;
    await const MethodChannel('meshtrax/system')
        .invokeMethod<void>('openSoundSettings');
  }

  /// Every notification the app asks for, before the platform shows it.
  @visibleForTesting
  static void Function(ShownNotification shown)? debugOnShow;

  /// An SOS, its repeat or its cancel: on its own category, shown at once
  /// (never batched behind other messages), one notification per sender
  /// and chat, replaced as the SOS updates. [where] names the chat, empty
  /// for a direct message. [payload] opens it, as a message's would:
  /// `mention:{channel}:{messageId}` lands on the card.
  Future<void> showSosNotification({
    required String chatKey,
    required String senderName,
    required String where,
    required String text,
    required String payload,
    bool cancelled = false,
  }) async {
    final l10n = _l10n;
    final title = cancelled
        ? l10n.notification_sosCancelledBy(senderName)
        : l10n.notification_sosFrom(senderName);
    final body = [
      MarkdownHelper.toPlainText(text),
      where,
    ].where((part) => part.isNotEmpty).join(' · ');
    final id = sosNotificationId(chatKey, senderName);
    // A cancelled SOS has no Got it left to wait for.
    if (cancelled) _kept.remove(id);
    // Got it answers in a channel; a direct message or a room has none.
    final gotIt = !cancelled && payload.startsWith('mention:');
    debugOnShow?.call(
      ShownNotification(
        channelId: sosChannelId,
        id: id,
        title: title,
        body: body,
        payload: payload,
        silent: cancelled,
        gotIt: gotIt,
      ),
    );
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows || Platform.isLinux) return;
    try {
      await _notifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: sosAndroidDetails(l10n, silent: cancelled, gotIt: gotIt),
          iOS: DarwinNotificationDetails(presentSound: !cancelled),
          macOS: DarwinNotificationDetails(presentSound: !cancelled),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show SOS notification: $e');
    }
  }

  /// One per sender and chat, clear of the message ids (small numbers and
  /// contact key hashes).
  @visibleForTesting
  static int sosNotificationId(String chatKey, String senderName) =>
      (('sos|$chatKey|$senderName').hashCode & 0x3FFFFFFF) | 0x40000000;

  /// The trip's end came with the radio still in TRAX mode. Shown at once,
  /// never batched behind messages; a tap asks TRAX mode's question again.
  Future<void> showTraxEndedNotification() async {
    final l10n = _l10n;
    final title = l10n.trax_endedTitle;
    final body = l10n.trax_endedText;
    debugOnShow?.call(
      ShownNotification(
        channelId: traxChannelId,
        id: traxEndedId,
        title: title,
        body: body,
        payload: traxEndedPayload,
      ),
    );
    if (Platform.isWindows || Platform.isLinux) return;
    try {
      if (!await _ensureInitialized()) return;
      await _notifications.show(
        id: traxEndedId,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: traxAndroidDetails(l10n),
          iOS: const DarwinNotificationDetails(),
          macOS: const DarwinNotificationDetails(),
        ),
        payload: traxEndedPayload,
      );
    } catch (e) {
      debugPrint('Failed to show the TRAX reminder: $e');
    }
  }

  /// The category the user's own SOS shows on while it lasts (Android):
  /// quiet and ongoing. Never [sosChannelId], which is the alarm.
  static const mySosChannelId = 'meshtrax_my_sos';

  /// Below zero, clear of every other notification's id.
  static const mySosNotificationId = -0x534F53; // 'SOS'

  @visibleForTesting
  static AndroidNotificationDetails mySosAndroidDetails(
    AppLocalizations l10n,
  ) => AndroidNotificationDetails(
    mySosChannelId,
    l10n.notification_mySosChannel,
    channelDescription: l10n.notification_mySosChannelDescription,
    importance: Importance.low,
    priority: Priority.low,
    playSound: false,
    enableVibration: false,
    ongoing: true,
    autoCancel: false,
    onlyAlertOnce: true,
    visibility: NotificationVisibility.public,
  );

  /// The user's own SOS as [showMySos] last had it, to word it again in
  /// another language.
  ({
    String Function(AppLocalizations l10n, String Function(DateTime) time)
    status,
    String chat,
    int? channelIndex,
  })?
  _mySos;

  /// What its notification says now: one that would say the same is not
  /// posted again.
  (String, String, String?)? _mySosShown;

  /// The user's own SOS in the shade while it lasts, on a quiet category of
  /// its own: [status] words it as the Chats and Map screens do, [chat] is
  /// where it went, and a tap opens channel [channelIndex]. Android only:
  /// iOS keeps no ongoing notification, and the screens show it there.
  Future<void> showMySos(
    String Function(AppLocalizations l10n, String Function(DateTime) time)
    status, {
    required String chat,
    int? channelIndex,
  }) async {
    if (defaultTargetPlatform != TargetPlatform.android) return;
    _mySos = (status: status, chat: chat, channelIndex: channelIndex);
    await _postMySos();
  }

  /// Takes the user's own SOS out of the shade: it ended.
  Future<void> cancelMySos() async {
    if (_mySos == null) return;
    _mySos = null;
    _mySosShown = null;
    await cancel(mySosNotificationId);
  }

  Future<void> _postMySos() async {
    final mine = _mySos;
    if (mine == null || !_localeKnown) return;
    final l10n = _l10n;
    final title = mine.status(l10n, (t) => DateTimeHelper.timeIn(_locale, t));
    final index = mine.channelIndex;
    final payload = index == null ? null : 'channel:$index';
    final shown = (title, mine.chat, payload);
    if (shown == _mySosShown) return;
    _mySosShown = shown;
    // Opening the app clears the other notifications, not this one.
    _kept.add(mySosNotificationId);
    debugOnShow?.call(
      ShownNotification(
        channelId: mySosChannelId,
        id: mySosNotificationId,
        title: title,
        body: mine.chat,
        payload: payload,
        silent: true,
      ),
    );
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows || Platform.isLinux) return;
    try {
      await _notifications.show(
        id: mySosNotificationId,
        title: title,
        body: mine.chat,
        notificationDetails: NotificationDetails(
          android: mySosAndroidDetails(l10n),
        ),
        payload: payload,
      );
    } catch (e) {
      debugPrint('Failed to show my SOS notification: $e');
    }
  }

  /// Format special message types for human-readable notifications.
  /// Markdown is stripped unless [formatting] is off; notifications always
  /// strip it so a spoiler never shows on the lock screen.
  static String formatNotificationText(String text, {bool formatting = true}) {
    final trimmed = text.trim();
    final reaction = ReactionHelper.parseIncomingReaction(trimmed);
    if (reaction != null) {
      return 'Reacted ${reaction.emoji}';
    }
    if (GifHelper.isGifOnly(trimmed)) {
      return 'Sent a GIF';
    }
    if (SvgMessage.isDrawing(trimmed)) {
      return 'Sent a drawing';
    }
    return MarkdownHelper.toPlainText(text, formatting: formatting);
  }

  Future<void> _showMessageNotificationImpl({
    required String contactName,
    required String message,
    String? contactId,
    int? badgeCount,
  }) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows || Platform.isLinux) return;

    final androidDetails = AndroidNotificationDetails(
      'meshtrax_messages',
      _l10n.appSettings_messageNotifications,
      importance: Importance.max,
      priority: Priority.high,
      groupKey: _groupKey,
    );
    const darwinDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final id = (contactId ?? contactName).hashCode.abs();

    await _notifications.show(
      id: id,
      title: contactName,
      body: formatNotificationText(message),
      notificationDetails: details,
      payload: contactId,
    );

    await _showGroupSummary();

    if (badgeCount != null) {
      _updateBadge(badgeCount);
    }
  }

  Future<void> _showAdvertNotificationImpl({
    required String contactName,
    required String contactType,
    String? contactId,
  }) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows || Platform.isLinux) return;

    final androidDetails = AndroidNotificationDetails(
      'meshtrax_adverts',
      _l10n.appSettings_advertisementNotifications,
      importance: Importance.low,
      priority: Priority.low,
      groupKey: _groupKey,
    );
    const darwinDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final id = (contactId ?? contactName).hashCode.abs() ^ 0x0A;

    await _notifications.show(
      id: id,
      title: contactType,
      body: contactName,
      notificationDetails: details,
    );

    await _showGroupSummary();
  }

  Future<void> _showChannelMessageNotificationImpl({
    required String channelName,
    required String message,
    int? channelIndex,
    int? badgeCount,
    String? mentionMessageId,
    String? traxAction,
  }) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows || Platform.isLinux) return;

    final androidDetails = channelAndroidDetails(_l10n, traxAction: traxAction);
    const darwinDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
      macOS: darwinDetails,
    );

    final preview = formatNotificationText(message.trim());
    final body = preview.isEmpty
        ? _l10n.notification_receivedNewMessage
        : preview;

    // A mention gets its own title, id (so a later plain message doesn't
    // replace it), and a payload that deep-links to the exact message.
    // TRAX mode's button gets its own id too.
    final isMention = mentionMessageId != null;
    final id = traxAction != null && channelIndex != null
        ? traxNotificationId(channelIndex)
        : (channelIndex ?? channelName.hashCode.abs()) ^
              (isMention ? 0x0E : 0x0C);

    await _notifications.show(
      id: id,
      title: isMention
          ? _l10n.notification_mentionIn(channelName)
          : channelName,
      body: body,
      notificationDetails: details,
      payload: isMention
          ? 'mention:$channelIndex:$mentionMessageId'
          : 'channel:$channelIndex',
    );

    await _showGroupSummary();

    if (badgeCount != null) {
      _updateBadge(badgeCount);
    }
  }

  /// Returns a privacy-safe identifier for debug logging.
  /// - advert: shows device name (body contains contactName)
  /// - message: shows "from: sender" (avoids logging message content)
  /// - channelMessage: shows "in: channel" (avoids logging message content)
  String _getNotificationIdentifier(_PendingNotification n) {
    switch (n.type) {
      case _NotificationType.advert:
        return n.body;
      case _NotificationType.message:
        return 'from: ${n.title}';
      case _NotificationType.channelMessage:
        return 'in: ${n.title}';
    }
  }

  /// A tapped notification, or one of its buttons.
  @visibleForTesting
  void handleTap(NotificationResponse response) {
    _keepGotIt(response);
    final payload = tapPayload(response);
    if (payload != null) onNotificationTap?.call(payload);
  }

  /// Notifications [cancelAll] leaves up: an SOS alert whose Got it was
  /// tapped, until Got it went ([cancelSos]), and the user's own SOS.
  final Set<int> _kept = {};

  @visibleForTesting
  bool keeps(int id) => _kept.contains(id);

  /// The app clears its notifications when it comes to the front, as a tap
  /// on Got it makes it do. That alert stays until Got it went: with the
  /// radio away, nothing went.
  void _keepGotIt(NotificationResponse response) {
    final id = response.id;
    if (response.actionId == sosGotItAction && id != null) _kept.add(id);
  }

  /// What a tap hands the app: the notification's payload, with `gotit:`
  /// in front when the tap was an SOS notification's Got it, and
  /// `traxfollow:` or `traxleave:` for TRAX mode's Switch too or Leave too.
  @visibleForTesting
  static String? tapPayload(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return null;
    return switch (response.actionId) {
      sosGotItAction => 'gotit:$payload',
      traxFollowAction => 'traxfollow:$payload',
      traxLeaveAction => 'traxleave:$payload',
      _ => payload,
    };
  }

  /// The channel a `channel:` or `mention:` payload opens.
  static int? channelIndexOf(String payload) {
    final match = RegExp(r'^(?:channel|mention):(\d+)').firstMatch(payload);
    return match == null ? null : int.parse(match.group(1)!);
  }

  static const _groupKey = 'com.meshtrax.MESSAGES';
  static const _groupSummaryId = 0x4D54; // 'MT'

  /// Android-only: a notification with [setAsGroupSummary] renders as the
  /// collapsed group header there. Other platforms have no summary concept
  /// and would show it as a plain extra notification.
  Future<void> _showGroupSummary() async {
    if (!Platform.isAndroid) return;
    final summaryDetails = AndroidNotificationDetails(
      'meshtrax_messages',
      _l10n.appSettings_messageNotifications,
      importance: Importance.max,
      priority: Priority.high,
      groupKey: _groupKey,
      setAsGroupSummary: true,
    );
    await _notifications.show(
      id: _groupSummaryId,
      title: 'MeshTrax',
      body: _l10n.notification_receivedNewMessage,
      notificationDetails: NotificationDetails(android: summaryDetails),
    );
  }

  /// Clears the app's notifications, all but the ones [_kept] holds.
  Future<void> cancelAll() async {
    if (Platform.isWindows || Platform.isLinux) return;
    if (!await _ensureInitialized()) return;
    _pendingNotifications.clear();
    if (_kept.isEmpty) {
      await _notifications.cancelAll();
    } else {
      for (final shown in await _notifications.getActiveNotifications()) {
        final id = shown.id;
        if (id != null && !_kept.contains(id)) {
          await _notifications.cancel(id: id, tag: shown.tag);
        }
      }
    }
    _updateBadge(0);
  }

  /// Stops an SOS alert, even mid-sound: [chatKey] and [senderName] as
  /// [showSosNotification] had them.
  Future<void> cancelSos(String chatKey, String senderName) =>
      cancel(sosNotificationId(chatKey, senderName));

  /// Every notification the app takes back, before the platform does.
  @visibleForTesting
  static void Function(int id)? debugOnCancel;

  Future<void> cancel(int id) async {
    debugOnCancel?.call(id);
    _kept.remove(id);
    if (Platform.isWindows || Platform.isLinux) return;
    if (!await _ensureInitialized()) return;
    await _notifications.cancel(id: id);
  }

  /// Cancel the notification for a specific contact and update the app badge.
  Future<void> clearContactNotification(
    String contactId,
    int totalUnreadCount,
  ) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows || Platform.isLinux) return;
  }

  /// Cancel the notification for a specific channel and update the app badge.
  Future<void> clearChannelNotification(
    int channelIndex,
    int totalUnreadCount,
  ) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows || Platform.isLinux) return;
  }

  /// Cancel advert notifications for the given contact public key hexes.
  Future<void> clearAdvertNotifications(List<String> contactIds) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows || Platform.isLinux) return;
  }

  Future<void> _updateBadge(int count) async {
    if (Platform.isWindows || Platform.isLinux) return;
    // Badge updates only supported on iOS/macOS
  }

  // ─────────────────────────────────────────────────────────────────
  // Public notification methods (rate limiting is enforced automatically)
  // ─────────────────────────────────────────────────────────────────

  Future<void> showMessageNotification({
    required String contactName,
    required String message,
    String? contactId,
    int? badgeCount,
  }) async {
    debugOnShow?.call(
      ShownNotification(
        channelId: 'meshtrax_messages',
        title: contactName,
        body: message,
        payload: contactId,
      ),
    );
    if (_suppressNotifications) return;

    _queueNotification(
      _PendingNotification(
        type: _NotificationType.message,
        title: contactName,
        body: message,
        id: contactId,
        badgeCount: badgeCount,
      ),
    );
  }

  /// A contact tried to use our radio's command line without permission.
  Future<void> showBlockedCliNotification({
    required String contactName,
    required String command,
    String? contactId,
  }) =>
      showMessageNotification(
        contactName: contactName,
        message: _l10n.companionCli_blockedBody(command),
        contactId: contactId,
      );

  Future<void> showAdvertNotification({
    required String contactName,
    required String contactType,
    String? contactId,
  }) async {
    if (_suppressNotifications) return;

    _queueNotification(
      _PendingNotification(
        type: _NotificationType.advert,
        title: contactType,
        body: contactName,
        id: contactId,
      ),
    );
  }

  /// [traxAction]: TRAX mode's button on a member's TRAX message
  /// ([traxFollowAction] or [traxLeaveAction]).
  Future<void> showChannelMessageNotification({
    required String channelName,
    required String senderName,
    required String message,
    int? channelIndex,
    int? badgeCount,
    String? mentionMessageId,
    String? traxAction,
  }) async {
    debugOnShow?.call(
      ShownNotification(
        channelId: 'meshtrax_channels',
        title: channelName,
        body: '$senderName: $message',
        payload: mentionMessageId != null
            ? 'mention:$channelIndex:$mentionMessageId'
            : 'channel:$channelIndex',
        action: traxAction,
      ),
    );
    if (_suppressNotifications) return;

    _queueNotification(
      _PendingNotification(
        type: _NotificationType.channelMessage,
        title: channelName,
        body: '$senderName: $message',
        id: channelIndex?.toString(),
        badgeCount: badgeCount,
        mentionMessageId: mentionMessageId,
        traxAction: traxAction,
      ),
    );
  }

  void _queueNotification(_PendingNotification notification) {
    final now = DateTime.now();

    // If we recently showed a notification, start batching
    if (_lastNotificationTime != null &&
        now.difference(_lastNotificationTime!) < _minNotificationInterval) {
      _pendingNotifications.add(notification);
      debugPrint(
        '[Notification] queued: ${notification.type.name} (${_getNotificationIdentifier(notification)})',
      );

      // Start batch timer if not already running
      if (!_isBatchingActive) {
        _isBatchingActive = true;
        Future.delayed(_batchWindow, _processBatch);
      }
      return;
    }

    // Show immediately if enough time has passed
    debugPrint(
      '[Notification] sent immediately: ${notification.type.name} (${_getNotificationIdentifier(notification)})',
    );
    _showNotificationImmediately(notification);
    _lastNotificationTime = now;
  }

  Future<void> _processBatch() async {
    _isBatchingActive = false;

    if (_pendingNotifications.isEmpty) return;

    final batch = List<_PendingNotification>.from(_pendingNotifications);
    _pendingNotifications.clear();

    // With native Android grouping, we just show each notification individually
    // and they will be stacked together under the groupKey.
    for (final notification in batch) {
      await _showNotificationImmediately(notification);
    }

    _lastNotificationTime = DateTime.now();
  }

  Future<void> _showNotificationImmediately(
    _PendingNotification notification,
  ) async {
    try {
      switch (notification.type) {
        case _NotificationType.message:
          await _showMessageNotificationImpl(
            contactName: notification.title,
            message: notification.body,
            contactId: notification.id,
            badgeCount: notification.badgeCount,
          );
          break;
        case _NotificationType.advert:
          await _showAdvertNotificationImpl(
            contactName: notification.body,
            contactType: notification.title,
            contactId: notification.id,
          );
          break;
        case _NotificationType.channelMessage:
          await _showChannelMessageNotificationImpl(
            channelName: notification.title,
            message: notification.body,
            channelIndex: int.tryParse(notification.id ?? ''),
            badgeCount: notification.badgeCount,
            mentionMessageId: notification.mentionMessageId,
            traxAction: notification.traxAction,
          );
          break;
      }
    } catch (e) {
      debugPrint('Failed to show immediate notification: $e');
    }
  }
}

/// What the SOS category may do on this phone ([NotificationService.sosAlertState]).
enum SosAlertState { unknown, blocked, silencedByDnd, throughDnd }

/// A notification the app asked for ([NotificationService.debugOnShow]).
class ShownNotification {
  final String channelId;
  final int? id;
  final String title;
  final String body;
  final String? payload;
  final bool silent;

  /// An SOS notification with a Got it button.
  final bool gotIt;

  /// TRAX mode's button on it, by action id.
  final String? action;

  const ShownNotification({
    required this.channelId,
    this.id,
    required this.title,
    required this.body,
    this.payload,
    this.silent = false,
    this.gotIt = false,
    this.action,
  });
}

// Helper class for pending notifications
enum _NotificationType { message, advert, channelMessage }

class _PendingNotification {
  final _NotificationType type;
  final String title;
  final String body;
  final String? id;
  final int? badgeCount;
  final String? mentionMessageId;
  final String? traxAction;

  _PendingNotification({
    required this.type,
    required this.title,
    required this.body,
    this.id,
    this.badgeCount,
    this.mentionMessageId,
    this.traxAction,
  });
}

