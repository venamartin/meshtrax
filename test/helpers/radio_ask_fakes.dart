import 'dart:async';
import 'dart:typed_data';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';

/// A radio that answers SENT with a new tag for every telemetry request,
/// then does what [reply] says.
class AskRadio extends MeshCoreConnector {
  final frames = StreamController<Uint8List>.broadcast();
  final tags = <List<int>>[];
  final askedOf = <String>[];
  bool? floodOnly;
  void Function(int index, List<int> tag) reply = (_, _) {};

  @override
  bool get isConnected => true;
  @override
  Stream<Uint8List> get receivedFrames => frames.stream;
  @override
  List<PathSelection> planRequestAttempts(
    Contact contact,
    int attempts, {
    bool floodOnly = false,
  }) {
    this.floodOnly = floodOnly;
    return List.filled(attempts, const PathSelection.flood(1));
  }

  @override
  int calculateRoundTripTimeout({
    required int pathLength,
    int messageBytes = 100,
    Contact? contact,
  }) => 1000;
  @override
  Future<void> sendOnRoute(
    Contact contact,
    PathSelection selection,
    Future<void> Function() send,
  ) => send();
  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    if (data[0] != cmdSendTelemetryReq) return;
    final tag = [tags.length + 1, 0xA0, 0, 0];
    final index = tags.length;
    tags.add(tag);
    askedOf.add(pubKeyToHex(Uint8List.fromList(data.sublist(4, 10))));
    scheduleMicrotask(() {
      frames.add(Uint8List.fromList([respCodeSent, 1, ...tag, 0, 0, 0, 0]));
      reply(index, tag);
    });
  }

  void telemetry(List<int> lpp, {Uint8List? key}) => frames.add(
    Uint8List.fromList([
      pushCodeTelemetryResponse,
      0,
      ...(key ?? gwqKey).sublist(0, 6),
      ...lpp,
    ]),
  );

  void binary(List<int> tag, List<int> lpp) => frames.add(
    Uint8List.fromList([pushCodeBinaryResponse, 0, ...tag, ...lpp]),
  );
}

Uint8List keyOf(int seed) =>
    Uint8List.fromList(List.generate(32, (i) => seed + i));
final gwqKey = keyOf(0x47);

Contact person(String name, Uint8List key) => Contact(
  publicKey: key,
  name: name,
  type: advTypeChat,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 1,
  lastSeen: DateTime(2026, 11, 18),
);

final gwq = person('GWQ', gwqKey);

List<int> _s24(int v) {
  final u = v & 0xFFFFFF;
  return [(u >> 16) & 0xFF, (u >> 8) & 0xFF, u & 0xFF];
}

List<int> lppGps(double lat, double lon, double alt) => [
  1,
  136,
  ..._s24((lat * 10000).round()),
  ..._s24((lon * 10000).round()),
  ..._s24((alt * 100).round()),
];

// 4.15 V, 40 °C.
const lppBattery = [1, 116, 0x01, 0x9F];
const lppTemperature = [1, 103, 0x01, 0x90];
