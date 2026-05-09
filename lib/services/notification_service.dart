import 'dart:io' show Platform, File;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../helpers/reaction_helper.dart';
import '../l10n/app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  // Locale for localized notification strings
  Locale _locale = const Locale('en');

  /// Set the locale for notification strings (call when app locale changes)
  void setLocale(Locale locale) {
    _locale = locale;
  }

  AppLocalizations get _l10n => lookupAppLocalizations(_locale);

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

    // Skip notification initialization on Windows (plugin not available)
    if (Platform.isWindows) {
      _isInitialized = true;
      debugPrint('Notifications unavailable on Windows');
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Open');

    final initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: Platform.isLinux ? linuxSettings : null,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _isInitialized = true;
    debugPrint(Platform.isLinux ? 'Notifications initialized (Linux)' : 'Notifications initialized (mobile platform)');
  }

  static bool _isDbusSessionAvailable() {
    final addr = Platform.environment['DBUS_SESSION_BUS_ADDRESS'];
    if (addr != null && addr.isNotEmpty) return true;
    // Fallback: check the default socket for the current user.
    final uid = Platform.environment['UID'] ?? Platform.environment['EUID'];
    final path = '/run/user/${uid ?? '1000'}/bus';
    return File(path).existsSync();
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

    // Permissions are not needed on Windows
    if (Platform.isWindows) {
      return true;
    }

    // On mobile platforms, permissions are already requested during initialization
    return true;
  }

  /// Format special message types for human-readable notifications.
  static String formatNotificationText(String text) {
    final trimmed = text.trim();
    final reaction = ReactionHelper.parseReaction(trimmed);
    if (reaction != null) {
      return 'Reacted ${reaction.emoji}';
    }
    if (RegExp(r'^g:[A-Za-z0-9_-]+$').hasMatch(trimmed)) {
      return 'Sent a GIF';
    }
    return text;
  }

  Future<void> _showMessageNotificationImpl({
    required String contactName,
    required String message,
    String? contactId,
    int? badgeCount,
  }) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows) return;

    final androidDetails = AndroidNotificationDetails(
      'meshtrax_messages',
      _l10n.appSettings_messageNotifications,
      importance: Importance.max,
      priority: Priority.high,
      groupKey: _groupKey,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

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
    if (Platform.isWindows) return;

    final androidDetails = AndroidNotificationDetails(
      'meshtrax_adverts',
      _l10n.appSettings_advertisementNotifications,
      importance: Importance.low,
      priority: Priority.low,
      groupKey: _groupKey,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

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
  }) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows) return;

    final androidDetails = AndroidNotificationDetails(
      'meshtrax_channels',
      _l10n.appSettings_channelMessageNotifications,
      importance: Importance.max,
      priority: Priority.high,
      groupKey: _groupKey,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    final preview = formatNotificationText(message.trim());
    final body = preview.isEmpty
        ? _l10n.notification_receivedNewMessage
        : preview;

    final id = (channelIndex ?? channelName.hashCode.abs()) ^ 0x0C;

    await _notifications.show(
      id: id,
      title: channelName,
      body: body,
      notificationDetails: details,
      payload: 'channel:$channelIndex',
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

  void _onNotificationTapped(dynamic response) {
    // Stub for Windows
  }

  static const _groupKey = 'com.meshtrax.MESSAGES';
  static const _groupSummaryId = 0x4D54; // 'MT'

  Future<void> _showGroupSummary() async {
    if (Platform.isWindows) return;
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
  Future<void> cancelAll() async {
    if (Platform.isWindows) return;
    if (!await _ensureInitialized()) return;
    _pendingNotifications.clear();
    await _notifications.cancelAll();
    _updateBadge(0);
  }

  Future<void> cancel(int id) async {
    if (Platform.isWindows) return;
    if (!await _ensureInitialized()) return;
    await _notifications.cancel(id: id);
  }

  /// Cancel the notification for a specific contact and update the app badge.
  Future<void> clearContactNotification(
    String contactId,
    int totalUnreadCount,
  ) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows) return;
  }

  /// Cancel the notification for a specific channel and update the app badge.
  Future<void> clearChannelNotification(
    int channelIndex,
    int totalUnreadCount,
  ) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows) return;
  }

  /// Cancel advert notifications for the given contact public key hexes.
  Future<void> clearAdvertNotifications(List<String> contactIds) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows) return;
  }

  Future<void> _updateBadge(int count) async {
    if (Platform.isWindows) return;
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

  Future<void> showChannelMessageNotification({
    required String channelName,
    required String senderName,
    required String message,
    int? channelIndex,
    int? badgeCount,
  }) async {
    if (_suppressNotifications) return;

    _queueNotification(
      _PendingNotification(
        type: _NotificationType.channelMessage,
        title: channelName,
        body: '$senderName: $message',
        id: channelIndex?.toString(),
        badgeCount: badgeCount,
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
          );
          break;
      }
    } catch (e) {
      debugPrint('Failed to show immediate notification: $e');
    }
  }
}

// Helper class for pending notifications
enum _NotificationType { message, advert, channelMessage }

class _PendingNotification {
  final _NotificationType type;
  final String title;
  final String body;
  final String? id;
  final int? badgeCount;

  _PendingNotification({
    required this.type,
    required this.title,
    required this.body,
    this.id,
    this.badgeCount,
  });
}

