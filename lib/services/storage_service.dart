import 'dart:convert';
import '../models/delivery_observation.dart';
import '../models/path_history.dart';
import '../storage/prefs_manager.dart';

class StorageService {
  static const String _pathHistoryPrefix = 'path_history_';
  static const String _pendingMessagesKey = 'pending_messages';
  static const String _repeaterPasswordsKey = 'repeater_passwords';
  static const String _repeaterAutoClockSyncAfterLoginKey =
      'repeater_auto_clock_sync_after_login';
  static const String _deliveryObservationsKey = 'delivery_observations';
  static const String _roomAdminFlagsKey = 'room_admin_flags';

  Future<Map<String, bool>> _loadRepeaterAutoClockSyncAfterLogin() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_repeaterAutoClockSyncAfterLoginKey);

    if (jsonStr == null) return {};

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(key, value == true));
    } catch (e) {
      return {};
    }
  }

  Future<bool> getRepeaterAutoClockSyncAfterLoginEnabled(
    String repeaterPubKeyHex,
  ) async {
    final settings = await _loadRepeaterAutoClockSyncAfterLogin();
    return settings[repeaterPubKeyHex] ?? false;
  }

  Future<void> setRepeaterAutoClockSyncAfterLoginEnabled(
    String repeaterPubKeyHex,
    bool enabled,
  ) async {
    final prefs = PrefsManager.instance;
    final settings = await _loadRepeaterAutoClockSyncAfterLogin();
    settings[repeaterPubKeyHex] = enabled;
    final jsonStr = jsonEncode(settings);
    await prefs.setString(_repeaterAutoClockSyncAfterLoginKey, jsonStr);
  }

  Future<void> savePathHistory(
    String contactPubKeyHex,
    ContactPathHistory history,
  ) async {
    final prefs = PrefsManager.instance;
    final key = '$_pathHistoryPrefix$contactPubKeyHex';
    final jsonStr = jsonEncode(history.toJson());
    await prefs.setString(key, jsonStr);
  }

  Future<ContactPathHistory?> loadPathHistory(String contactPubKeyHex) async {
    final prefs = PrefsManager.instance;
    final key = '$_pathHistoryPrefix$contactPubKeyHex';
    final jsonStr = prefs.getString(key);

    if (jsonStr == null) return null;

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return ContactPathHistory.fromJson(contactPubKeyHex, json);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearPathHistory(String contactPubKeyHex) async {
    final prefs = PrefsManager.instance;
    final key = '$_pathHistoryPrefix$contactPubKeyHex';
    await prefs.remove(key);
  }

  Future<void> clearAllPathHistories() async {
    final prefs = PrefsManager.instance;
    final keys = prefs.getKeys();
    final pathHistoryKeys = keys.where(
      (key) => key.startsWith(_pathHistoryPrefix),
    );

    for (final key in pathHistoryKeys) {
      await prefs.remove(key);
    }
  }

  Future<Map<String, String>> loadPendingMessages() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_pendingMessagesKey);

    if (jsonStr == null) return {};

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      return {};
    }
  }

  Future<void> savePendingMessages(Map<String, String> pending) async {
    final prefs = PrefsManager.instance;
    final jsonStr = jsonEncode(pending);
    await prefs.setString(_pendingMessagesKey, jsonStr);
  }

  Future<void> clearPendingMessages() async {
    final prefs = PrefsManager.instance;
    await prefs.remove(_pendingMessagesKey);
  }

  /// Save a repeater password by public key hex
  Future<void> saveRepeaterPassword(
    String repeaterPubKeyHex,
    String password,
  ) async {
    final prefs = PrefsManager.instance;
    final passwords = await loadRepeaterPasswords();
    passwords[repeaterPubKeyHex] = password;
    final jsonStr = jsonEncode(passwords);
    await prefs.setString(_repeaterPasswordsKey, jsonStr);
  }

  /// Load all saved repeater passwords (map of pubKeyHex -> password)
  Future<Map<String, String>> loadRepeaterPasswords() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_repeaterPasswordsKey);

    if (jsonStr == null) return {};

    try {
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return json.map((key, value) => MapEntry(key, value as String));
    } catch (e) {
      return {};
    }
  }

  /// Get a specific repeater's saved password
  Future<String?> getRepeaterPassword(String repeaterPubKeyHex) async {
    final passwords = await loadRepeaterPasswords();
    return passwords[repeaterPubKeyHex];
  }

  /// Remove a saved repeater password
  Future<void> removeRepeaterPassword(String repeaterPubKeyHex) async {
    final prefs = PrefsManager.instance;
    final passwords = await loadRepeaterPasswords();
    passwords.remove(repeaterPubKeyHex);
    final jsonStr = jsonEncode(passwords);
    await prefs.setString(_repeaterPasswordsKey, jsonStr);
  }

  /// Clear all saved repeater passwords
  Future<void> clearAllRepeaterPasswords() async {
    final prefs = PrefsManager.instance;
    await prefs.remove(_repeaterPasswordsKey);
  }

  /// Rooms whose last saved-password login was as admin, by pubKeyHex.
  Future<Set<String>> _loadRoomAdminFlags() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_roomAdminFlagsKey);
    if (jsonStr == null) return {};
    try {
      return (jsonDecode(jsonStr) as List).cast<String>().toSet();
    } catch (e) {
      return {};
    }
  }

  Future<void> setRoomAdminFlag(String pubKeyHex, bool isAdmin) async {
    final prefs = PrefsManager.instance;
    final flags = await _loadRoomAdminFlags();
    if (isAdmin) {
      flags.add(pubKeyHex);
    } else {
      flags.remove(pubKeyHex);
    }
    await prefs.setString(_roomAdminFlagsKey, jsonEncode(flags.toList()));
  }

  Future<bool> isRoomAdmin(String pubKeyHex) async {
    return (await _loadRoomAdminFlags()).contains(pubKeyHex);
  }

  Future<void> saveDeliveryObservations(
    List<DeliveryObservation> observations,
  ) async {
    final prefs = PrefsManager.instance;
    final jsonStr = jsonEncode(observations.map((o) => o.toJson()).toList());
    await prefs.setString(_deliveryObservationsKey, jsonStr);
  }

  Future<List<DeliveryObservation>> loadDeliveryObservations() async {
    final prefs = PrefsManager.instance;
    final jsonStr = prefs.getString(_deliveryObservationsKey);

    if (jsonStr == null) return [];

    try {
      final list = jsonDecode(jsonStr) as List;
      return list
          .map((e) => DeliveryObservation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> clearDeliveryObservations() async {
    final prefs = PrefsManager.instance;
    await prefs.remove(_deliveryObservationsKey);
  }
}
