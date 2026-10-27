import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../helpers/quick_reactions.dart';
import '../models/app_settings.dart';

import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';

class AppSettingsService extends ChangeNotifier {
  static const String _settingsKey = 'app_settings';

  AppSettings _settings = AppSettings();

  AppSettings get settings => _settings;

  String batteryChemistryForDevice(String deviceId) {
    final stored = _settings.batteryChemistryByDeviceId[deviceId];
    if (stored == 'liion') return 'nmc';
    return stored ?? 'nmc';
  }

  String batteryChemistryForRepeater(String repeaterPubKeyHex) {
    final stored = _settings.batteryChemistryByRepeaterId[repeaterPubKeyHex];
    if (stored == 'liion') return 'nmc';
    return stored ?? 'nmc';
  }

  Future<void> loadSettings() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_settingsKey);

    if (jsonStr != null) {
      try {
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        _settings = AppSettings.fromJson(json);
        notifyListeners();
      } catch (e) {
        // If parsing fails, use defaults
        _settings = AppSettings();
      }
    }
  }

  Future<void> updateSettings(AppSettings newSettings) async {
    _settings = newSettings;
    notifyListeners();

    final prefs = PrefsManager.instance;
    final jsonStr = jsonEncode(_settings.toJson());
    await prefs.setString(_settingsKey, jsonStr);
  }

  Future<void> setMapShowRepeaters(bool value) async {
    await updateSettings(_settings.copyWith(mapShowRepeaters: value));
  }

  Future<void> setMapShowChatNodes(bool value) async {
    await updateSettings(_settings.copyWith(mapShowChatNodes: value));
  }

  Future<void> setMapShowOtherNodes(bool value) async {
    await updateSettings(_settings.copyWith(mapShowOtherNodes: value));
  }

  Future<void> setMapShowOverlaps(bool value) async {
    await updateSettings(_settings.copyWith(mapShowOverlaps: value));
  }

  Future<void> setMapTimeFilterHours(double value) async {
    await updateSettings(_settings.copyWith(mapTimeFilterHours: value));
  }

  Future<void> setMapKeyPrefixEnabled(bool value) async {
    await updateSettings(_settings.copyWith(mapKeyPrefixEnabled: value));
  }

  Future<void> setMapKeyPrefix(String value) async {
    await updateSettings(_settings.copyWith(mapKeyPrefix: value));
  }

  Future<void> setMapShowMarkers(bool value) async {
    await updateSettings(_settings.copyWith(mapShowMarkers: value));
  }

  Future<void> setMapShowGuessedLocations(bool value) async {
    await updateSettings(_settings.copyWith(mapShowGuessedLocations: value));
  }

  Future<void> setEnableMessageTracing(bool value) async {
    await updateSettings(_settings.copyWith(enableMessageTracing: value));
  }

  Future<void> setMapDownloadsWifiOnly(bool value) async {
    await updateSettings(_settings.copyWith(mapDownloadsWifiOnly: value));
  }

  Future<void> setMapType(String value) async {
    await updateSettings(_settings.copyWith(mapType: value));
  }

  Future<void> setMapContours(bool value) async {
    await updateSettings(_settings.copyWith(mapContours: value));
  }

  Future<void> setMapHillShading(bool value) async {
    await updateSettings(_settings.copyWith(mapHillShading: value));
  }

  Future<void> setMapPlaces(bool value) async {
    await updateSettings(_settings.copyWith(mapPlaces: value));
  }

  Future<void> setMapParks(bool value) async {
    await updateSettings(_settings.copyWith(mapParks: value));
  }

  Future<void> setMapDownloadedAreas(bool value) async {
    await updateSettings(_settings.copyWith(mapDownloadedAreas: value));
  }

  Future<void> setMapTheme(String value) async {
    await updateSettings(_settings.copyWith(mapTheme: value));
  }

  Future<void> setMapSource(String value) async {
    await updateSettings(_settings.copyWith(mapSource: value));
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await updateSettings(_settings.copyWith(notificationsEnabled: value));
  }

  Future<void> setNotifyOnNewMessage(bool value) async {
    await updateSettings(_settings.copyWith(notifyOnNewMessage: value));
  }

  Future<void> setNotifyOnNewChannelMessage(bool value) async {
    await updateSettings(_settings.copyWith(notifyOnNewChannelMessage: value));
  }

  Future<void> setNotifyOnMention(bool value) async {
    await updateSettings(_settings.copyWith(notifyOnMention: value));
  }

  Future<void> setNotifyOnNewAdvert(bool value) async {
    await updateSettings(_settings.copyWith(notifyOnNewAdvert: value));
  }

  Future<void> setMaxMessageRetries(int value) async {
    await updateSettings(_settings.copyWith(maxMessageRetries: value));
  }

  Future<void> setMaxChannelMessageRetries(int value) async {
    await updateSettings(_settings.copyWith(maxChannelMessageRetries: value));
  }

  Future<void> setThemeMode(String value) async {
    await updateSettings(_settings.copyWith(themeMode: value));
  }

  Future<void> setLanguageOverride(String? value) async {
    await updateSettings(_settings.copyWith(languageOverride: value));
  }

  Future<void> setPathGraphEnabled(bool value) async {
    await updateSettings(_settings.copyWith(pathGraphEnabled: value));
  }

  Future<void> setAppDebugLogEnabled(bool value) async {
    await updateSettings(_settings.copyWith(appDebugLogEnabled: value));
    // Update the global logger
    appLogger.setEnabled(value);
  }

  Future<void> setMapShowDiscoveryContacts(bool value) async {
    await updateSettings(_settings.copyWith(mapShowDiscoveryContacts: value));
  }

  Future<void> setBatteryChemistryForDevice(
    String deviceId,
    String chemistry,
  ) async {
    final updated = Map<String, String>.from(
      _settings.batteryChemistryByDeviceId,
    );
    updated[deviceId] = chemistry;
    await updateSettings(
      _settings.copyWith(batteryChemistryByDeviceId: updated),
    );
  }

  Future<void> setBatteryChemistryForRepeater(
    String repeaterPubKeyHex,
    String chemistry,
  ) async {
    final updated = Map<String, String>.from(
      _settings.batteryChemistryByRepeaterId,
    );
    updated[repeaterPubKeyHex] = chemistry;
    await updateSettings(
      _settings.copyWith(batteryChemistryByRepeaterId: updated),
    );
  }

  Future<void> setUnitSystem(UnitSystem value) async {
    await updateSettings(_settings.copyWith(unitSystem: value));
  }

  Future<void> setCoordinateFormat(String value) async {
    await updateSettings(_settings.copyWith(coordinateFormat: value));
  }

  bool isChannelMuted(String channelName) {
    return _settings.mutedChannels.contains(channelName);
  }

  Future<void> muteChannel(String channelName) async {
    final updated = Set<String>.from(_settings.mutedChannels)..add(channelName);
    await updateSettings(_settings.copyWith(mutedChannels: updated));
  }

  Future<void> unmuteChannel(String channelName) async {
    final updated = Set<String>.from(_settings.mutedChannels)
      ..remove(channelName);
    await updateSettings(_settings.copyWith(mutedChannels: updated));
  }

  bool isContactMuted(String pubKeyHex) {
    return _settings.mutedContacts.contains(pubKeyHex);
  }

  Future<void> muteContact(String pubKeyHex) async {
    final updated = Set<String>.from(_settings.mutedContacts)..add(pubKeyHex);
    await updateSettings(_settings.copyWith(mutedContacts: updated));
  }

  Future<void> unmuteContact(String pubKeyHex) async {
    final updated = Set<String>.from(_settings.mutedContacts)
      ..remove(pubKeyHex);
    await updateSettings(_settings.copyWith(mutedContacts: updated));
  }

  Future<void> setTcpServerAddress(String value) async {
    await updateSettings(_settings.copyWith(tcpServerAddress: value));
  }

  Future<void> setTcpServerPort(int value) async {
    await updateSettings(_settings.copyWith(tcpServerPort: value));
  }

  Future<void> setJumpToOldestUnread(bool value) async {
    await updateSettings(_settings.copyWith(jumpToOldestUnread: value));
  }

  Future<void> setAutoFavoriteOnChat(bool value) async {
    await updateSettings(_settings.copyWith(autoFavoriteOnChat: value));
  }

  Future<void> setAutoConnectLastDevice(bool value) async {
    await updateSettings(_settings.copyWith(autoConnectLastDevice: value));
  }

  Future<void> setIncrementalContactSync(bool value) async {
    await updateSettings(_settings.copyWith(incrementalContactSync: value));
  }

  Future<void> dismissDmIdentityWarning() async {
    await updateSettings(_settings.copyWith(dmIdentityWarningDismissed: true));
  }

  Future<void> dismissBatterySleepWarning() async {
    await updateSettings(
      _settings.copyWith(batterySleepWarningDismissed: true),
    );
  }

  Future<void> setChartsNoticeDismissed(bool value) async {
    await updateSettings(_settings.copyWith(chartsNoticeDismissed: value));
  }

  Future<void> setSenderNameColors(bool value) async {
    await updateSettings(_settings.copyWith(senderNameColors: value));
  }

  Future<void> setShowTextFormatting(bool value) async {
    await updateSettings(_settings.copyWith(showTextFormatting: value));
  }

  Future<void> rememberReaction(String emoji) async {
    await updateSettings(_settings.copyWith(
      recentReactions:
          QuickReactions.remember(_settings.recentReactions, emoji),
    ));
  }

  // --- Blocking (user-generated content moderation) -------------------------

  bool isContactBlocked(String publicKeyHex) =>
      _settings.blockedContactKeys.contains(publicKeyHex);

  bool isSenderBlocked(String senderName) =>
      _settings.blockedSenderNames.contains(senderName);

  Future<void> blockContact(String publicKeyHex) async {
    final updated = Set<String>.from(_settings.blockedContactKeys)
      ..add(publicKeyHex);
    await updateSettings(_settings.copyWith(blockedContactKeys: updated));
  }

  Future<void> unblockContact(String publicKeyHex) async {
    final updated = Set<String>.from(_settings.blockedContactKeys)
      ..remove(publicKeyHex);
    await updateSettings(_settings.copyWith(blockedContactKeys: updated));
  }

  Future<void> blockSender(String senderName) async {
    final updated = Set<String>.from(_settings.blockedSenderNames)
      ..add(senderName);
    await updateSettings(_settings.copyWith(blockedSenderNames: updated));
  }

  Future<void> unblockSender(String senderName) async {
    final updated = Set<String>.from(_settings.blockedSenderNames)
      ..remove(senderName);
    await updateSettings(_settings.copyWith(blockedSenderNames: updated));
  }
}
