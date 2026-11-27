import 'dart:typed_data';

import 'channel.dart';

/// Binary data the radio read on one of its channels, from any app, by its
/// data type (RESP_CODE_CHANNEL_DATA_RECV). It carries no sender and no
/// time of its own.
class ChannelDatagram {
  const ChannelDatagram({
    required this.channel,
    required this.dataType,
    required this.payload,
    required this.receivedAt,
    required this.fromBacklog,
    this.pathLen = 0xFF,
  });

  final Channel channel;
  final int dataType;
  final Uint8List payload;

  /// The packed path length the radio gave with it: how many repeaters it
  /// came through and their code width (`PathHelper.pathLenHops`); 0xFF when
  /// it came direct.
  final int pathLen;

  /// When this app read it from the radio.
  final DateTime receivedAt;

  /// The radio heard it while this app was away, some time before
  /// [receivedAt].
  final bool fromBacklog;
}

/// What a packet of a group of channel datagrams I send is doing
/// (MeshCoreConnector.sendChannelPackets).
enum ChannelPacketStep {
  /// It goes the first time.
  sending,

  /// It goes again.
  again,

  /// One repeater passed it on: it waits for a second, or for the observers.
  waiting,

  /// It is done with; the next packet may go.
  done,
}

/// The radio didn't take a packet of a group of channel datagrams I send: the
/// rest don't go.
class ChannelPacketsFailed implements Exception {
  const ChannelPacketsFailed({this.errorCode, this.connected = true});

  /// The radio's error code when it refused the packet; null when it didn't
  /// answer.
  final int? errorCode;

  /// False when the link to the radio was gone.
  final bool connected;

  @override
  String toString() =>
      'ChannelPacketsFailed(${errorCode != null ? 'error $errorCode' : connected ? 'no answer' : 'not connected'})';
}
