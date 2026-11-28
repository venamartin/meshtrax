import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;

import '../connector/meshcore_connector.dart';
import '../models/channel.dart';
import '../models/channel_datagram.dart';
import '../models/channel_request.dart';
import '../utils/app_build.dart';
import '../utils/app_logger.dart';

/// Requests MeshTrax nodes make of each other on a channel
/// ([dataTypeChannelRequest]): sends them through the chat, and hands each
/// one asked of this radio to whoever registered for its kind, and each one
/// asked of another node to whoever overhears it. It knows no kind itself.
/// One per app run.
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
  final Map<int, void Function(Channel channel, ChannelRequest request)>
  _overhearers = {};
  int _nextId = math.Random().nextInt(256);

  /// This app's build, which every request carries
  /// ([ChannelRequest.build]).
  final Future<int> _build = appBuild();

  ChannelRequests._(this.connector) {
    _datagrams = connector.channelDatagrams.listen(_onDatagram);
  }

  /// [handler] takes the requests of [kind] asked of this radio, with the
  /// channel they came on.
  void register(
    int kind,
    void Function(Channel channel, ChannelRequest request) handler,
  ) => _handlers[kind] = handler;

  /// [handler] takes the requests of [kind] that others asked of another
  /// node, with the channel they came on: what someone else already asked
  /// for needn't be asked for again.
  void overhear(
    int kind,
    void Function(Channel channel, ChannelRequest request) handler,
  ) => _overhearers[kind] = handler;

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
    if (request == null || self == null || request.asker == self) return;
    final mine = request.isFor(self);
    final handler = (mine ? _handlers : _overhearers)[request.kind];
    if (handler == null) return;
    appLogger.info(
      '${mine ? 'Asked' : 'Overheard'}: $request',
      tag: 'Requests',
    );
    handler(d.channel, request);
  }
}
