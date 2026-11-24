import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

// The companion protocol, as the firmware's examples/companion_radio has it.
const cmdAppStart = 1;
const cmdSyncNextMessage = 10;
const cmdSetRadioParams = 11;
const cmdDeviceQuery = 22;
const cmdGetChannel = 31;
const cmdSetChannel = 32;
const cmdSendChannelData = 62;

const respOk = 0;
const respSelfInfo = 5;
const respNoMoreMessages = 10;
const respDeviceInfo = 13;
const respChannelInfo = 18;
const respChannelDataRecv = 27;
const pushMsgWaiting = 0x83;

/// Channel datagrams came with companion firmware 1.15.
const channelDataVerCode = 11;

/// The longest frame the firmware sends.
const _maxFrame = 250;

/// A frame for the radio over serial: '<', its length (little-endian), the
/// frame.
Uint8List frameForRadio(List<int> frame) => Uint8List.fromList([
  0x3C,
  frame.length & 0xFF,
  frame.length >> 8,
  ...frame,
]);

/// Splits what the radio writes into frames: '>', the length, the frame.
/// Anything else, such as a board's boot log, is skipped.
class FrameSplitter {
  final _buffer = <int>[];

  List<Uint8List> add(List<int> bytes) {
    _buffer.addAll(bytes);
    final frames = <Uint8List>[];
    while (true) {
      final start = _buffer.indexOf(0x3E);
      if (start < 0) {
        _buffer.clear();
        break;
      }
      _buffer.removeRange(0, start);
      if (_buffer.length < 3) break;
      final length = _buffer[1] | _buffer[2] << 8;
      if (length == 0 || length > _maxFrame) {
        _buffer.removeAt(0);
        continue;
      }
      if (_buffer.length < 3 + length) break;
      frames.add(Uint8List.fromList(_buffer.sublist(3, 3 + length)));
      _buffer.removeRange(0, 3 + length);
    }
    return frames;
  }
}

/// What the radio says about itself at the start.
class SelfInfo {
  const SelfInfo({
    required this.publicKey,
    required this.name,
    required this.lat,
    required this.lon,
    required this.freqKhz,
    required this.bwHz,
    required this.sf,
    required this.cr,
  });

  final Uint8List publicKey;
  final String name;
  final double lat;
  final double lon;
  final int freqKhz;
  final int bwHz;
  final int sf;
  final int cr;

  static SelfInfo? parse(Uint8List f) {
    if (f.length < 58 || f[0] != respSelfInfo) return null;
    final d = ByteData.sublistView(f);
    return SelfInfo(
      publicKey: Uint8List.fromList(f.sublist(4, 36)),
      lat: d.getInt32(36, Endian.little) / 1e6,
      lon: d.getInt32(40, Endian.little) / 1e6,
      freqKhz: d.getUint32(48, Endian.little),
      bwHz: d.getUint32(52, Endian.little),
      sf: f[56],
      cr: f[57],
      name: utf8.decode(f.sublist(58), allowMalformed: true),
    );
  }
}

typedef ChannelInfo = ({String name, Uint8List secret});

/// One companion radio: a command at a time, each answered by the next
/// frame that isn't a push.
class Companion {
  /// Over serial, with each frame wrapped by [frameForRadio] on the way out
  /// and split out by a [FrameSplitter] on the way in.
  Companion(void Function(Uint8List) write, Stream<List<int>> input)
    : this.frames((f) => write(frameForRadio(f)), _split(input));

  /// Over a link that carries whole frames, such as Bluetooth.
  Companion.frames(this._send, Stream<Uint8List> frames) {
    frames.listen(_onFrame);
  }

  static Stream<Uint8List> _split(Stream<List<int>> input) {
    final splitter = FrameSplitter();
    return input.expand(splitter.add);
  }

  final void Function(Uint8List) _send;
  final _pushes = StreamController<Uint8List>.broadcast();
  Completer<Uint8List>? _waiting;
  Future<void> _last = Future.value();

  /// Frames the radio sends on its own, such as "a message is waiting".
  Stream<Uint8List> get pushes => _pushes.stream;

  void _onFrame(Uint8List f) {
    if (f.isEmpty) return;
    if (f[0] >= 0x80) {
      _pushes.add(f);
    } else {
      final waiting = _waiting;
      _waiting = null;
      waiting?.complete(f);
    }
  }

  /// Sends [frame] once the commands before it are answered, and waits for
  /// its answer.
  Future<Uint8List> ask(
    List<int> frame, {
    Duration timeout = const Duration(seconds: 5),
  }) {
    final answer = _last.then((_) {
      final waiting = _waiting = Completer<Uint8List>();
      _send(Uint8List.fromList(frame));
      return waiting.future.timeout(
        timeout,
        onTimeout: () {
          _waiting = null;
          throw TimeoutException('no answer to command ${frame[0]}');
        },
      );
    });
    _last = answer.then((_) {}, onError: (_) {});
    return answer;
  }

  /// The firmware's version code, how many channels it holds and whether
  /// Off-Grid Repeat is on.
  Future<({int verCode, int channels, bool repeat})> deviceInfo() async {
    final f = await ask([cmdDeviceQuery, 3]);
    if (f[0] != respDeviceInfo || f.length < 4) {
      throw StateError('not a companion radio (answer ${f[0]})');
    }
    return (verCode: f[1], channels: f[3], repeat: f.length > 80 && f[80] != 0);
  }

  Future<SelfInfo> appStart() async {
    final f = await ask([
      cmdAppStart,
      1,
      ...List.filled(6, 0),
      ...ascii.encode('trax_sim'),
      0,
    ]);
    return SelfInfo.parse(f) ?? (throw StateError('no self info'));
  }

  /// The channel in [index], or null for an empty or missing slot.
  Future<ChannelInfo?> channel(int index) async {
    final f = await ask([cmdGetChannel, index]);
    if (f[0] != respChannelInfo || f.length < 50) return null;
    final nameBytes = f.sublist(2, 34);
    final end = nameBytes.indexOf(0);
    final name = utf8.decode(
      nameBytes.sublist(0, end < 0 ? 32 : end),
      allowMalformed: true,
    );
    final secret = Uint8List.fromList(f.sublist(34, 50));
    if (name.isEmpty && secret.every((b) => b == 0)) return null;
    return (name: name, secret: secret);
  }

  Future<bool> setChannel(int index, String name, Uint8List secret) async {
    final nameBytes = Uint8List(32);
    final encoded = utf8.encode(name);
    nameBytes.setRange(0, min(31, encoded.length), encoded);
    final f = await ask([cmdSetChannel, index, ...nameBytes, ...secret]);
    return f[0] == respOk;
  }

  /// Off-Grid Repeat goes off unless [repeat]: the firmware reads a
  /// missing repeat byte as off.
  Future<bool> setRadio({
    required int freqKhz,
    required int bwHz,
    required int sf,
    required int cr,
    bool repeat = false,
  }) async {
    final b = ByteData(8)
      ..setUint32(0, freqKhz, Endian.little)
      ..setUint32(4, bwHz, Endian.little);
    final f = await ask([
      cmdSetRadioParams,
      ...b.buffer.asUint8List(),
      sf,
      cr,
      if (repeat) 1,
    ]);
    return f[0] == respOk;
  }

  /// Floods [payload] on channel [index]; false when the radio refuses.
  Future<bool> sendChannelData(
    int index,
    int dataType,
    Uint8List payload,
  ) async {
    final f = await ask([
      cmdSendChannelData,
      index,
      0xFF,
      dataType & 0xFF,
      dataType >> 8,
      ...payload,
    ]);
    return f[0] == respOk;
  }

  /// The next message the radio holds, or null when it holds none.
  Future<Uint8List?> nextMessage() async {
    final f = await ask([cmdSyncNextMessage]);
    return f[0] == respNoMoreMessages ? null : f;
  }
}

/// A received channel datagram: [27][snr][0][0][index][path][type][len][data].
({int channel, int dataType, Uint8List data})? parseChannelData(Uint8List f) {
  if (f.length < 9 || f[0] != respChannelDataRecv) return null;
  final length = f[8];
  if (f.length < 9 + length) return null;
  return (
    channel: f[4],
    dataType: f[6] | f[7] << 8,
    data: Uint8List.fromList(f.sublist(9, 9 + length)),
  );
}

/// The firmware's airtime for a [bytes]-byte packet: its preamble (32
/// symbols up to SF8, else 16) and RadioLib's automatic low data rate
/// optimisation, as MeshTrax works it out.
int airtimeMs({
  required int bytes,
  required int bwHz,
  required int sf,
  required int cr,
}) {
  final symbolMs = (1 << sf) / (bwHz / 1000);
  final preamble = (sf <= 8 ? 32 : 16) + 4.25;
  final de = symbolMs > 16 ? 1 : 0;
  final inner = ((8 * bytes - 4 * sf + 28 + 16) / (4 * (sf - 2 * de))).ceil();
  final payloadSymbols = 8 + max(0, inner * cr);
  return ((preamble + payloadSymbols) * symbolMs).ceil();
}
