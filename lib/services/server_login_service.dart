import 'dart:async';

import 'package:flutter/foundation.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import '../models/path_selection.dart';
import '../utils/app_logger.dart';
import 'storage_service.dart';

/// Outcome of a login ladder. [success] null means every attempt timed out.
/// [isAdmin] is the server's response byte; null when the success was only
/// implied (a post arrived) or nothing came back.
typedef LoginOutcome = ({bool? success, bool? isAdmin});

/// The one login ladder for rooms and repeaters. The login dialogs, the
/// silent login when a room chat opens and the route relearn after a flooded
/// post all send through here.
///
/// A login is also how a server teaches the radio a route: a login sent by
/// flood is answered with a PATH return, a login sent direct is not. On
/// Automatic the first attempt goes by Pathfinder's best route when it can
/// route (else the radio's own), and once that times out the ladder resets
/// the route and floods the rest. A user's Custom or Flood choice is kept
/// for every attempt. Each attempt's route is written and its login sent
/// with no other route write in between.
class ServerLoginService {
  final MeshCoreConnector _connector;
  final StorageService _storage;

  ServerLoginService(this._connector, {StorageService? storage})
      : _storage = storage ?? StorageService();

  /// [forceFlood]: every attempt floods, whatever Pathfinder or the radio
  /// holds. The relearn after a flooded post needs this: its whole point is
  /// the PATH reply only a flooded login earns, and Pathfinder's best route
  /// (or the route the keeper just wrote) would send it direct — field
  /// 2026-10-24: "login by flood" went out on F5EE and timed out.
  Future<LoginOutcome> login(
    Contact server,
    String password, {
    int maxAttempts = 5,
    void Function(int attempt)? onAttempt,
    String tag = 'Login',
    bool forceFlood = false,
  }) async {
    final flood = PathSelection.flood(_connector.pathHashByteWidth);
    final selection =
        forceFlood ? flood : _connector.planRequestAttempts(server, 1).first;
    final frame = buildSendLoginFrame(server.publicKey, password);
    final responseBytes =
        frame.length > maxFrameSize ? frame.length : maxFrameSize;
    Duration timeoutFor(int pathLength) => Duration(
          milliseconds: _connector.calculateTimeout(
                pathLength: pathLength,
                messageBytes: responseBytes,
              ) +
              2000,
        );
    var flooding = selection.useFlood;
    var timeout = timeoutFor(flooding ? -1 : selection.hopCount);
    appLogger.info(
      'Login routing: ${flooding ? forceFlood ? 'flood (forced)' : 'flood' : '${selection.hopCount} hops'}',
      tag: tag,
    );

    final isRoom = server.type == advTypeRoom;
    final startedAt = DateTime.now();
    bool? result;
    bool? isAdmin;
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      onAttempt?.call(attempt + 1);

      if (isRoom) {
        // A response (or a post proving the session) that landed between
        // attempts, outside our subscription window.
        final recorded = _connector.lastRoomLoginEvent(server.publicKeyHex);
        if (recorded != null && recorded.at.isAfter(startedAt)) {
          result = recorded.success;
          isAdmin = recorded.isAdmin;
          appLogger.info(
            'Login already ${result == true ? 'confirmed' : 'refused'} for '
            '${server.name}${recorded.implied ? ' (post arrived)' : ''}',
            tag: tag,
          );
          break;
        }
      }

      appLogger.info(
        'Sending login attempt ${attempt + 1}/$maxAttempts',
        tag: tag,
      );
      await _connector.sendOnRoute(server, flooding ? flood : selection,
          () => _connector.sendFrame(frame));
      (result, isAdmin) = await _awaitResponse(server, timeout, isRoom: isRoom);
      if (result != null) {
        appLogger.info(
          'Login ${result ? 'succeeded' : 'failed'} for ${server.name}',
          tag: tag,
        );
        break;
      }
      appLogger.warn(
        'Login attempt ${attempt + 1} timed out after '
        '${(timeout.inMilliseconds / 1000).ceil()}s',
        tag: tag,
      );

      if (!flooding && server.pathOverride == null && attempt + 1 < maxAttempts) {
        flooding = true;
        timeout = timeoutFor(-1);
        appLogger.info('Login routing: flood (route reset)', tag: tag);
      }
    }
    if (result == null) {
      appLogger.warn('Login timed out for ${server.name}', tag: tag);
    }
    return (success: result, isAdmin: isAdmin);
  }

  /// Rooms remember the password that last worked: every successful room
  /// login stores it with the admin outcome and the role byte, and opens the
  /// connection's admin session when the server said admin. Returns isAdmin.
  Future<bool> rememberRoomLogin(
    Contact room,
    String password,
    LoginOutcome outcome,
  ) async {
    final keyHex = room.publicKeyHex;
    // An implied success says nothing about permissions; keep the stored
    // outcome.
    final isAdmin = outcome.isAdmin ?? await _storage.isRoomAdmin(keyHex);
    final event = _connector.lastRoomLoginEvent(keyHex);
    if (event != null && !event.implied && event.permissions != null) {
      await _storage.setRoomPermissions(keyHex, event.permissions);
    }
    await _storage.saveRepeaterPassword(keyHex, password);
    await _storage.setRoomAdminFlag(keyHex, isAdmin);
    _connector.recordRoomLogin(keyHex, password, isAdmin);
    return isAdmin;
  }

  Future<(bool?, bool?)> _awaitResponse(
    Contact server,
    Duration timeout, {
    required bool isRoom,
  }) async {
    final completer = Completer<bool?>();
    final targetPrefix = server.publicKey.sublist(0, 6);
    bool? isAdmin;

    final frames = _connector.receivedFrames.listen((frame) {
      if (frame.length < 8) return;
      final code = frame[0];
      if (code != pushCodeLoginSuccess && code != pushCodeLoginFail) return;
      if (!listEquals(frame.sublist(2, 8), targetPrefix)) return;
      // The repeater firmware sends 1 or 0 here, not the client permissions.
      isAdmin = frame[1] == 1;
      if (!completer.isCompleted) {
        completer.complete(code == pushCodeLoginSuccess);
      }
    });

    // The connector also records room outcomes implied by a post arriving:
    // the server only pushes to logged-in clients, so a login must not sit
    // on retries while posts flow in behind it.
    StreamSubscription<RoomLoginEvent>? events;
    if (isRoom) {
      events = _connector.roomLoginEvents
          .where((e) => e.roomKeyHex == server.publicKeyHex)
          .listen((event) {
        if (completer.isCompleted) return;
        isAdmin = event.isAdmin;
        completer.complete(event.success);
      });
    }

    final timer = Timer(timeout, () {
      if (!completer.isCompleted) completer.complete(null);
    });
    try {
      final result = await completer.future;
      return (result, isAdmin);
    } finally {
      timer.cancel();
      // Not awaited: a broadcast subscription's cancel is already done, and
      // its shared completed future belongs to the root zone, which would
      // hop the ladder off a fake clock in tests.
      unawaited(frames.cancel());
      unawaited(events?.cancel());
    }
  }
}
