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
  });

  final Channel channel;
  final int dataType;
  final Uint8List payload;

  /// When this app read it from the radio.
  final DateTime receivedAt;

  /// The radio heard it while this app was away, some time before
  /// [receivedAt].
  final bool fromBacklog;
}
