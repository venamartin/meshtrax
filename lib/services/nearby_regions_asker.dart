import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import '../models/path_selection.dart';
import '../models/repeater_regions.dart';
import '../utils/app_logger.dart';
import 'region_service.dart';

/// After a Discover the user started, asks each repeater that answered for
/// the regions it carries (ANON_REQ_TYPE_REGIONS), one at a time.
///
/// Firmware limits (simple_repeater/MyMesh.cpp, companion MyMesh.cpp):
/// - the question must arrive DIRECT, so it goes on the repeater's route,
///   or on a zero-hop route when the radio has none (it just answered a
///   zero-hop Discover);
/// - a repeater not saved on the radio is skipped: asking one would make
///   the radio add a nameless contact for it;
/// - each repeater answers 4 such questions every 3 minutes, from anyone,
///   so a repeater is asked at most once a day;
/// - the radio tracks one pending request, so these go one after another.
class NearbyRegionsAsker {
  NearbyRegionsAsker(this._connector, this._regions);

  final MeshCoreConnector _connector;
  final RegionService _regions;

  /// How long to wait for a repeater's answer.
  @visibleForTesting
  static Duration answerWait = const Duration(seconds: 12);

  bool _busy = false;

  Future<void> askAll(List<Uint8List> answered) async {
    if (_busy || !_connector.supportsRegions) return;
    _busy = true;
    try {
      for (final key in answered) {
        if (!_connector.isConnected) break;
        await _ask(key);
      }
    } finally {
      _busy = false;
    }
  }

  Future<void> _ask(Uint8List key) async {
    final keyHex = pubKeyToHex(key);
    if (_regions.askedLately(keyHex)) return;
    final repeater = _connector.contacts
        .where((c) => c.publicKeyHex == keyHex && c.type == advTypeRepeater)
        .firstOrNull;
    if (repeater == null) return;

    final answer = await _request(repeater);
    if (answer == null) return;
    final names = RepeaterRegions.parseNameList(answer);
    appLogger.info(
      'Regions of ${repeater.name}: ${names.isEmpty ? 'none' : names.join(', ')}',
      tag: 'Regions',
    );
    await _regions.saveReport(keyHex, names);
  }

  /// The repeater's comma list, or null when no answer came.
  Future<String?> _request(Contact repeater) async {
    final route = repeater.pathLength >= 0
        ? PathSelection(
            pathBytes: repeater.path,
            hopCount: repeater.pathLength,
            hashSize: repeater.pathHashSize,
            useFlood: false,
            source: RouteSource.firmware,
          )
        : PathSelection(
            pathBytes: const [],
            hopCount: 0,
            hashSize: _connector.pathHashByteWidth,
            useFlood: false,
            source: RouteSource.custom,
          );
    final done = Completer<String?>();
    Uint8List? tag;
    // The radio answers commands in order, so the first SENT after the
    // write is this request's.
    final sub = _connector.receivedFrames.listen((frame) {
      if (frame.isEmpty || done.isCompleted) return;
      if (frame[0] == respCodeSent && frame.length >= 6 && tag == null) {
        // Flooded: the repeater only answers a DIRECT question.
        if (frame[1] == 1) return done.complete(null);
        tag = Uint8List.fromList(frame.sublist(2, 6));
      } else if (frame[0] == pushCodeBinaryResponse &&
          frame.length >= 10 &&
          tag != null &&
          listEquals(frame.sublist(2, 6), tag)) {
        // [code][reserved][tag x4][repeater clock x4][names]
        done.complete(utf8.decode(frame.sublist(10), allowMalformed: true));
      }
    });
    try {
      await _connector.sendOnRoute(
        repeater,
        route,
        () => _connector.sendFrame(buildRegionsRequestFrame(repeater.publicKey)),
      );
      return await done.future.timeout(answerWait, onTimeout: () => null);
    } catch (e) {
      appLogger.warn('Asking ${repeater.name} for regions: $e', tag: 'Regions');
      return null;
    } finally {
      await sub.cancel();
    }
  }
}
