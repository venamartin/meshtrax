import '../utils/app_logger.dart';
import 'prefs_manager.dart';

class ChannelSettingsStore {
  static const String _keyPrefix = 'channel_smaz_';

  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length > 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  /// Smaz flag for a channel identity (Channel.idKey). Keyed by identity so
  /// a channel created in a reused radio slot never inherits the previous
  /// occupant's compression setting.
  Future<bool> loadSmazEnabled(String idKey) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot load channel settings.',
      );
      return false;
    }
    return PrefsManager.instance.getBool('${keyFor}id_$idKey') ?? false;
  }

  Future<void> saveSmazEnabled(String idKey, bool enabled) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn(
        'Public key hex is not set. Cannot save channel settings.',
      );
      return;
    }
    await PrefsManager.instance.setBool('${keyFor}id_$idKey', enabled);
  }
}
