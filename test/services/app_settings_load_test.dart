import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// New defaults are for new installs. Settings are saved only on a change, so
// an install that never changed one has nothing saved, just like a new one.
void main() {
  Future<AppSettingsService> load(Map<String, Object> saved) async {
    SharedPreferences.setMockInitialValues(saved);
    PrefsManager.reset();
    await PrefsManager.initialize();
    return AppSettingsService();
  }

  void expectOldValues(AppSettingsService service) {
    final s = service.settings;
    expect(s.pathGraphEnabled, isFalse);
    expect(s.incrementalContactSync, isFalse);
    expect(s.maxMessageRetries, 3);
    expect(s.mapShowGuessedLocations, isTrue);
    expect(s.mapShowRepeaters, isTrue);
    expect(s.mapShowOtherNodes, isTrue);
    expect(s.mapShowMarkers, isTrue);
    expect(s.mapContours, isTrue);
    expect(s.mapHillShading, isTrue);
    expect(s.mutedChannels, isEmpty);
    expect(s.enableMessageTracing, isTrue);
    expect(s.jumpToOldestUnread, isTrue);
  }

  test('a new install gets the new defaults and keeps them', () async {
    final service = await load({});
    await service.loadSettings();
    expect(service.settings.pathGraphEnabled, isTrue);
    expect(service.settings.mutedChannels, {Channel.publicChannelPsk});
    expect(service.settings.mapShowRepeaters, isFalse);
    expect(service.settings.mapContours, isFalse);

    // The next launch, after the terms were accepted, still reads the same.
    await PrefsManager.instance.setBool('terms_accepted_v1', true);
    final later = AppSettingsService();
    await later.loadSettings();
    expect(later.settings.pathGraphEnabled, isTrue);
    expect(later.settings.mutedChannels, {Channel.publicChannelPsk});
  });

  for (final marker in <String, Object>{
    'terms_accepted_v1': true,
    'last_ble_device_id': 'radio',
  }.entries) {
    test('an older install with ${marker.key} keeps what it ran on', () async {
      final service = await load({marker.key: marker.value});
      await service.loadSettings();
      expectOldValues(service);

      final later = AppSettingsService();
      await later.loadSettings();
      expectOldValues(later);
    });
  }

  test('an older install differs from a new one only by the new defaults', () {
    final older = AppSettings.olderInstall().toJson();
    final fresh = AppSettings().toJson();
    expect(older.keys, fresh.keys);
    final differs = {
      for (final key in fresh.keys)
        if (jsonEncode(older[key]) != jsonEncode(fresh[key])) key,
    };
    expect(differs, {
      'map_show_repeaters',
      'map_show_other_nodes',
      'map_show_markers',
      'map_show_guessed_locations',
      'map_contours',
      'map_hill_shading',
      'max_message_retries',
      'path_graph_enabled',
      'muted_channels',
      'incremental_contact_sync',
    });
  });

  test('saved settings missing a key keep that key\'s old fallback', () async {
    final service = await load({
      'app_settings': jsonEncode({'theme_mode': 'dark'}),
    });
    await service.loadSettings();
    final s = service.settings;
    expect(s.pathGraphEnabled, isFalse);
    expect(s.incrementalContactSync, isFalse);
    expect(s.maxMessageRetries, 3);
    expect(s.mapShowGuessedLocations, isTrue);
    expect(s.mutedChannels, isEmpty);
    expect(s.enableMessageTracing, isFalse, reason: 'it ran on the fallback');
    expect(s.jumpToOldestUnread, isFalse);
  });

  test('unreadable saved settings keep the old values', () async {
    final service = await load({'app_settings': 'not json'});
    await service.loadSettings();
    expectOldValues(service);
  });

  test('a saved choice wins', () async {
    final service = await load({
      'app_settings': jsonEncode({
        'path_graph_enabled': true,
        'max_message_retries': 5,
      }),
    });
    await service.loadSettings();
    expect(service.settings.pathGraphEnabled, isTrue);
    expect(service.settings.maxMessageRetries, 5);
  });
}
