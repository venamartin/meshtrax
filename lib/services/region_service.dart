import 'package:flutter/foundation.dart';

import '../helpers/region_helper.dart';
import '../storage/prefs_manager.dart';

/// The user's regions and each channel's region. App-wide: a channel's
/// region belongs to the channel (its key), so it is the same on every radio.
/// Kept under 'regions_' prefs keys, which the app backup includes.
class RegionService extends ChangeNotifier {
  static const String _listKey = 'regions_list';
  static const String _channelPrefix = 'regions_channel_';
  static const String _inQrKey = 'regions_in_qr';

  List<String> _regions = [];
  final Map<String, String> _channelRegions = {};
  bool _inQr = false;

  List<String> get regions => List.unmodifiable(_regions);

  /// Channel QR codes carry the region, and scanned ones set it. Off by
  /// default.
  bool get regionsInQr => _inQr;

  Future<void> load() async {
    final prefs = PrefsManager.instance;
    _regions = prefs.getStringList(_listKey) ?? [];
    _channelRegions.clear();
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_channelPrefix)) continue;
      final value = prefs.getString(key);
      if (value != null) {
        _channelRegions[key.substring(_channelPrefix.length)] = value;
      }
    }
    _inQr = prefs.getBool(_inQrKey) ?? false;
    notifyListeners();
  }

  /// The channel's own region: a name, [RegionHelper.everywhere],
  /// [RegionHelper.nearbyOnly], or null.
  String? regionOf(String idKey) => _channelRegions[idKey.toLowerCase()];

  bool get anyChannelHasRegion => _channelRegions.isNotEmpty;

  int channelsUsing(String name) =>
      _channelRegions.values.where((r) => r == name).length;

  /// Adds [name] as typed (case matters). False when the firmware wouldn't
  /// take it or it is already listed.
  Future<bool> add(String name) async {
    final region = RegionHelper.normalize(name);
    if (RegionHelper.check(region) != null || _regions.contains(region)) {
      return false;
    }
    _regions = [..._regions, region]
      ..sort((a, b) {
        final byLetters = a.toLowerCase().compareTo(b.toLowerCase());
        return byLetters != 0 ? byLetters : a.compareTo(b);
      });
    await PrefsManager.instance.setStringList(_listKey, _regions);
    notifyListeners();
    return true;
  }

  /// Removes [name] and takes it off every channel that used it.
  Future<void> remove(String name) async {
    final prefs = PrefsManager.instance;
    _regions = _regions.where((r) => r != name).toList();
    await prefs.setStringList(_listKey, _regions);
    final users = _channelRegions.entries
        .where((e) => e.value == name)
        .map((e) => e.key)
        .toList();
    for (final idKey in users) {
      _channelRegions.remove(idKey);
      await prefs.remove('$_channelPrefix$idKey');
    }
    notifyListeners();
  }

  /// Sets the channel's region; null takes it off. A name not yet listed is
  /// added to the list.
  Future<void> setChannelRegion(String idKey, String? region) async {
    final key = idKey.toLowerCase();
    final prefs = PrefsManager.instance;
    if (region == null) {
      _channelRegions.remove(key);
      await prefs.remove('$_channelPrefix$key');
    } else {
      final value = RegionHelper.isRegionName(region)
          ? RegionHelper.normalize(region)
          : region;
      if (RegionHelper.isRegionName(value) && !_regions.contains(value)) {
        if (!await add(value)) return;
      }
      _channelRegions[key] = value;
      await prefs.setString('$_channelPrefix$key', value);
    }
    notifyListeners();
  }

  Future<void> setRegionsInQr(bool on) async {
    _inQr = on;
    await PrefsManager.instance.setBool(_inQrKey, on);
    notifyListeners();
  }
}
