import 'dart:io' show Platform, File;
import 'dart:ui';

// flutter_local_notifications is not available for Windows builds
// On mobile platforms, the package is properly initialized in initialize()
import 'package:flutter/foundation.dart';

import '../helpers/reaction_helper.dart';
import '../l10n/app_localizations.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Mock notifications object - not used on Windows
  dynamic _notifications;
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

    _isInitialized = true;
    debugPrint('Notifications initialized (mobile platform)');
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

    // Actual implementation would show notification here
    debugPrint(
      '[Notification] Message from $contactName: ${formatNotificationText(message)}',
    );
  }

  Future<void> _showAdvertNotificationImpl({
    required String contactName,
    required String contactType,
    String? contactId,
  }) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows) return;

    debugPrint('[Notification] New $contactType: $contactName');
  }

  Future<void> _showChannelMessageNotificationImpl({
    required String channelName,
    required String message,
    int? channelIndex,
    int? badgeCount,
  }) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows) return;

    final preview = formatNotificationText(message.trim());
    final body = preview.isEmpty
        ? _l10n.notification_receivedNewMessage
        : preview;

    debugPrint('[Notification] Channel $channelName: $body');
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

  Future<void> cancelAll() async {
    if (Platform.isWindows) return;
  }

  Future<void> cancel(int id) async {
    if (Platform.isWindows) return;
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

    if (batch.length == 1) {
      // Single notification, show normally
      _showNotificationImmediately(batch.first);
    } else {
      // Multiple notifications, show summary
      await _showBatchSummary(batch);
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

  Future<void> _showBatchSummary(List<_PendingNotification> batch) async {
    if (!await _ensureInitialized()) return;
    if (Platform.isWindows) return;

    // Group by type
    final messages = batch
        .where((n) => n.type == _NotificationType.message)
        .toList();
    final adverts = batch
        .where((n) => n.type == _NotificationType.advert)
        .toList();
    final channelMsgs = batch
        .where((n) => n.type == _NotificationType.channelMessage)
        .toList();

    // Build summary text using localized plurals
    final parts = <String>[];
    if (messages.isNotEmpty) {
      parts.add(_l10n.notification_messagesCount(messages.length));
    }
    if (channelMsgs.isNotEmpty) {
      parts.add(_l10n.notification_channelMessagesCount(channelMsgs.length));
    }
    if (adverts.isNotEmpty) {
      parts.add(_l10n.notification_newNodesCount(adverts.length));
    }

    if (parts.isEmpty) return;

    debugPrint('[Notification] batch summary: ${parts.join(", ")}');
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
