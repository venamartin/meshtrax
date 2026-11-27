import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:package_info_plus/package_info_plus.dart';

import '../connector/meshcore_connector.dart';
import '../models/channel.dart';
import '../models/channel_datagram.dart';
import '../models/channel_request.dart';
import '../utils/app_logger.dart';
import '../utils/platform_info.dart';

/// Requests MeshTrax nodes make of each other on a channel
/// ([dataTypeChannelRequest]): sends them through the chat, and hands each
/// one asked of this radio to whoever registered for its kind. It knows no
/// kind itself. One per app run.
class ChannelRequests {
  static ChannelRequests? _instance;

  static ChannelRequests of(MeshCoreConnector connector) =>
      _instance ??= ChannelRequests._(connector);

  /// A fresh one for the next [of], for tests with a connector of their own.
  @visibleForTesting
  static void resetForTest() {
    _instance?._datagrams.cancel();
    _instance = null;
  }

  final MeshCoreConnector connector;
  late final StreamSubscription<ChannelDatagram> _datagrams;
  final Map<int, void Function(Channel channel, ChannelRequest request)>
  _handlers = {};
  int _nextId = math.Random().nextInt(256);

  /// This app's build, which every request carries
  /// ([ChannelRequest.build]).
  final Future<int> _build = _appBuild();

  ChannelRequests._(this.connector) {
    _datagrams = connector.channelDatagrams.listen(_onDatagram);
  }

  /// The number after the + in this app's version; 0 when the platform
  /// doesn't say.
  static Future<int> _appBuild() async {
    try {
      final code = int.tryParse((await PackageInfo.fromPlatform()).buildNumber);
      if (code == null) return 0;
      // A split APK's versionCode is the build plus 1000 times its ABI
      // (Flutter's --split-per-abi): arm64's 2252 is build 252.
      return PlatformInfo.isAndroid ? code % 1000 : code;
    } on Object catch (_) {
      return 0;
    }
  }

  /// [handler] takes the requests of [kind] asked of this radio, with the
  /// channel they came on.
  void register(
    int kind,
    void Function(Channel channel, ChannelRequest request) handler,
  ) => _handlers[kind] = handler;

  /// The first 2 bytes of this radio's public key, which requests name it
  /// by; null while it isn't known.
  int? get selfPrefix {
    final key = connector.selfPublicKey;
    if (key == null || key.length < 2) return null;
    return (key[0] << 8) | key[1];
  }

  /// Asks [asked] (or anyone) on [channel] for a [kind] with [body], through
  /// the chat: once and at once, as a flood like a message, or zero hop on a
  /// Nearby only channel. Returns the request, or null when this radio's key
  /// isn't known yet. Throws [ChannelPacketsFailed] when the radio didn't
  /// take it.
  Future<ChannelRequest?> send(
    Channel channel, {
    required int kind,
    required Uint8List body,
    int asked = ChannelRequest.anyone,
  }) async {
    final build = await _build;
    final asker = selfPrefix;
    if (asker == null) return null;
    final request = ChannelRequest(
      kind: kind,
      id: _nextId,
      asker: asker,
      asked: asked,
      build: build,
      body: body,
    );
    _nextId = (_nextId + 1) & 0xFF;
    appLogger.info('Asking: $request', tag: 'Requests');
    await connector.sendChannelPackets(
      channel: channel,
      groupId: 'request-${request.id}',
      dataType: dataTypeChannelRequest,
      packets: [request.encode()],
      once: true,
      ahead: true,
    );
    return request;
  }

  void _onDatagram(ChannelDatagram d) {
    if (d.dataType != dataTypeChannelRequest) return;
    final request = ChannelRequest.decode(d.payload);
    final self = selfPrefix;
    if (request == null || self == null) return;
    if (request.asker == self || !request.isFor(self)) return;
    final handler = _handlers[request.kind];
    if (handler == null) return;
    appLogger.info('Asked: $request', tag: 'Requests');
    handler(d.channel, request);
  }
}
