import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/channel.dart';
import '../utils/app_logger.dart';
import 'app_database.dart';
import 'prefs_manager.dart';

/// Cached mirror of the radio's channel slot table, one row per slot (v5).
/// The RADIO is the source of truth here — whole-list replacement on sync
/// is the correct write for a mirror. (Message history is different: it is
/// user data with no backstop, and its stores never delete.)
class ChannelStore {
  static const String _keyPrefix = 'channels';
  String publicKeyHex = '';
  set setPublicKeyHex(String value) =>
      publicKeyHex = value.length >= 10 ? value.substring(0, 10) : '';

  String get keyFor => '$_keyPrefix$publicKeyHex';

  AppDatabase get _db => AppDatabase.instance;

  Future<List<Channel>> loadChannels() async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot load channels.');
      return [];
    }
    await _importLegacyBlobs();
    final rows =
        await (_db.select(_db.cachedChannelRows)
              ..where((r) => r.nodeScope.equals(publicKeyHex))
              ..orderBy([(r) => OrderingTerm.asc(r.slotIndex)]))
            .get();
    final channels = <Channel>[];
    for (final row in rows) {
      try {
        channels.add(
          _fromJson(jsonDecode(row.payload) as Map<String, dynamic>),
        );
      } catch (e) {
        appLogger.warn('Skipping unreadable cached channel row: $e');
      }
    }
    return channels;
  }

  Future<void> saveChannels(List<Channel> channels) async {
    if (publicKeyHex.isEmpty) {
      appLogger.warn('Public key hex is not set. Cannot save channels.');
      return;
    }
    await _db.transaction(() async {
      await (_db.delete(_db.cachedChannelRows)
            ..where((r) => r.nodeScope.equals(publicKeyHex)))
          .go();
      await _db.batch((b) {
        b.insertAll(
          _db.cachedChannelRows,
          [
            for (final channel in channels)
              CachedChannelRowsCompanion.insert(
                nodeScope: publicKeyHex,
                slotIndex: channel.index,
                payload: jsonEncode(_toJson(channel)),
              ),
          ],
          mode: InsertMode.insertOrReplace,
        );
      });
    });
  }

  /// One-time import of the prefs JSON blobs (scoped first, then the
  /// ancient unscoped key); the keys are removed either way.
  Future<void> _importLegacyBlobs() async {
    final prefs = PrefsManager.instance;
    for (final key in [keyFor, _keyPrefix]) {
      final jsonString = prefs.getString(key);
      if (jsonString != null && jsonString.isNotEmpty) {
        final existing =
            await (_db.select(_db.cachedChannelRows)
                  ..where((r) => r.nodeScope.equals(publicKeyHex))
                  ..limit(1))
                .getSingleOrNull();
        if (existing == null) {
          try {
            final jsonList = jsonDecode(jsonString) as List<dynamic>;
            await _db.batch((b) {
              b.insertAll(
                _db.cachedChannelRows,
                [
                  for (final entry in jsonList)
                    CachedChannelRowsCompanion.insert(
                      nodeScope: publicKeyHex,
                      slotIndex:
                          (entry as Map<String, dynamic>)['index'] as int,
                      payload: jsonEncode(entry),
                    ),
                ],
                mode: InsertMode.insertOrIgnore,
              );
            });
            appLogger.info('Imported channel cache from legacy key $key');
          } catch (e) {
            appLogger.warn('Failed channel cache import from $key: $e');
          }
        }
      }
      await prefs.remove(key);
    }
  }

  Map<String, dynamic> _toJson(Channel channel) {
    return {
      'index': channel.index,
      'name': channel.name,
      'psk': base64Encode(channel.psk),
      'unreadCount': channel.unreadCount,
    };
  }

  Channel _fromJson(Map<String, dynamic> json) {
    return Channel(
      index: json['index'] as int,
      name: json['name'] as String? ?? '',
      psk: json['psk'] != null
          ? Uint8List.fromList(base64Decode(json['psk'] as String))
          : Uint8List(16),
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }
}
