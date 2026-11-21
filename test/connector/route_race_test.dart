import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/path_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/path_selection.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mesh simulator, 2026-11-21: the ladder's route was written, the DM
// waited a few seconds for a quiet radio, and the PATH the contact's radio
// sent in that time replaced the route on the radio
// (BaseChatMesh::onContactPathRecv). The DM went out on the route just
// learned while the route chosen before got the delivery: a home doorstep
// was credited with reaching someone 30 km away.

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join().toUpperCase();

Uint8List _u32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

Uint8List _contactFrame(Uint8List pubKey, String name, List<int> path) {
  final w = BytesBuilder();
  w.addByte(respCodeContact);
  w.add(pubKey);
  w.addByte(advTypeChat);
  w.addByte(0);
  w.addByte(
      path.isEmpty ? 0xFF : PathHelper.encodePathLen(path.length ~/ 2, 2));
  w.add(Uint8List(maxPathSize)..setRange(0, path.length, path));
  final nameBytes = Uint8List(maxNameSize);
  nameBytes.setRange(0, name.length, name.codeUnits);
  w.add(nameBytes);
  w.add(Uint8List.fromList([1, 0, 0, 0]));
  w.add(Uint8List(8));
  return w.toBytes();
}

/// A radio that keeps each contact's stored route as the firmware does:
/// written by the app, cleared, or learned from the contact, and read back
/// on request. It notes the route each DM went out on.
class _Radio extends MeshCoreConnector {
  final frames = <Uint8List>[];
  final stored = <String, List<int>>{};
  final dmRoutes = <String>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    frames.add(data);
    switch (data[0]) {
      case cmdAddUpdateContact:
        stored[_hex(data.sublist(1, 33))] =
            data.sublist(36, 36 + PathHelper.pathLenBytes(data[35]));
      case cmdResetPath:
        stored[_hex(data.sublist(1, 33))] = const [];
      case cmdGetContactByKey:
        final key = Uint8List.fromList(data.sublist(1, 33));
        scheduleMicrotask(() => handleFrameForTest(
            _contactFrame(key, 'Bob', stored[_hex(key)] ?? const [])));
      case cmdSendTxtMsg:
        final prefix = _hex(data.sublist(7, 13));
        final route = stored.entries
            .where((e) => e.key.startsWith(prefix))
            .firstOrNull
            ?.value ??
            const <int>[];
        dmRoutes.add(route.isEmpty ? 'flood' : _hex(route));
    }
  }

  List<Uint8List> get dms =>
      frames.where((f) => f[0] == cmdSendTxtMsg).toList();

  /// The radio learns [path] from [key]'s PATH reply, and says so.
  void learn(Uint8List key, List<int> path) {
    stored[_hex(key)] = path;
    handleFrameForTest(Uint8List.fromList([pushCodePathUpdated, ...key]));
  }
}

PathSelection _route(List<int> bytes) => PathSelection(
      pathBytes: bytes,
      hopCount: bytes.length ~/ 2,
      hashSize: 2,
      useFlood: false,
      source: RouteSource.graph,
      estDelivery: 0.5,
    );

// Planned: home doorstep. Learned: the route his PATH named.
final _planned = _route([0xA2, 0x77, 0xAA, 0x77]);
final _learned = _route([0xA4, 0x77, 0x10, 0x00, 0x40, 0x00]);

Uint8List _selfInfo(Uint8List pubKey) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(pubKey);
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(_u32(910525000));
  w.add(_u32(62500));
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

Uint8List _dm(Uint8List from, String text) => Uint8List.fromList([
      respCodeContactMsgRecvV3, 0x14, 0, 0,
      ...from.sublist(0, 6),
      5, // flooded over five repeaters
      txtTypePlain,
      ..._u32(1795283000),
      ...utf8.encode(text),
    ]);

Uint8List _sent(int ackHash) =>
    Uint8List.fromList([respCodeSent, 0, ..._u32(ackHash), ..._u32(5000)]);

Uint8List _confirmed(int ackHash) => Uint8List.fromList(
    [pushCodeSendConfirmed, ..._u32(ackHash), ..._u32(2500)]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final selfKey = Uint8List.fromList(List.generate(32, (i) => 0xAB + i));
  final bobKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));

  late _Radio c;
  late MessageRetryService retry;
  late Contact bob;
  late List<({String route, bool delivered})> credited;

  int ackOf(Uint8List frame) => MessageRetryService.computeExpectedAckHash(
        ByteData.sublistView(frame, 3, 7).getUint32(0, Endian.little),
        frame[2],
        utf8.decode(frame.sublist(13, frame.length - 1)),
        selfKey,
      );

  Future<void> until(bool Function() done) async {
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (!done() && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
  }

  Future<void> deliver() async {
    final ack = ackOf(c.dms.last);
    c.handleFrameForTest(_sent(ack));
    c.handleFrameForTest(_confirmed(ack));
    await Future<void>.delayed(const Duration(milliseconds: 50));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    retry = MessageRetryService();
    c = _Radio()..initialize(retryService: retry);
    c.handleFrameForTest(_selfInfo(selfKey));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    await c.getContacts();
    c.handleFrameForTest(Uint8List.fromList([respCodeContactsStart, 1, 0, 0, 0]));
    c.handleFrameForTest(_contactFrame(bobKey, 'Bob', const []));
    c.handleFrameForTest(Uint8List.fromList([respCodeEndOfContacts, 0, 0, 0, 0]));
    bob = c.contacts.firstWhere((x) => x.name == 'Bob');
    credited = [];
    c.onSendAttemptResult = (_, selection, delivered, _) => credited.add((
          route: selection.useFlood ? 'flood' : _hex(selection.pathBytes),
          delivered: delivered,
        ));
  });

  tearDown(() => retry.dispose());

  test('a route his radio names while the reply waits carries it, and gets '
      'the delivery', () async {
    var routes = [_planned];
    c.graphRouteCandidates = (_) => routes;
    // His DM just came in: the reply waits for the air to clear.
    c.handleFrameForTest(_dm(bobKey, 'hello'));
    unawaited(c.sendMessage(bob, 're: test'));
    await until(() => c.stored[_hex(bobKey)]?.isNotEmpty ?? false);
    expect(_hex(c.stored[_hex(bobKey)]!), _hex(_planned.pathBytes),
        reason: "the ladder's route is written first");

    // His PATH: the radio stores the route it names, and Pathfinder ranks
    // that route first while it is live.
    routes = [_learned, _planned];
    c.learn(bobKey, _learned.pathBytes);
    await until(() => c.dms.isNotEmpty);

    expect(c.dmRoutes, [_hex(_learned.pathBytes)]);
    await deliver();
    expect(credited, [(route: _hex(_learned.pathBytes), delivered: true)],
        reason: 'the delivery belongs to the route that carried it');
  });

  test('without Pathfinder, the route the radio learned is the one credited',
      () async {
    c.graphRouteCandidates = null;
    final known = _route([0xA2, 0x77, 0xF5, 0xEE]).pathBytes;
    c.stored[_hex(bobKey)] = known;
    c.handleFrameForTest(_contactFrame(bobKey, 'Bob', known));
    bob = c.contacts.firstWhere((x) => x.name == 'Bob');

    c.handleFrameForTest(_dm(bobKey, 'hello'));
    unawaited(c.sendMessage(bob, 're: test'));
    await Future<void>.delayed(const Duration(milliseconds: 500));
    c.learn(bobKey, _learned.pathBytes);
    await until(() => c.dms.isNotEmpty);

    expect(c.dmRoutes, [_hex(_learned.pathBytes)]);
    expect(c.frames.where((f) => f[0] == cmdAddUpdateContact), isEmpty,
        reason: "the radio's own route is never written over");
    await deliver();
    expect(credited, [(route: _hex(_learned.pathBytes), delivered: true)]);
  });

  test('with no route learned in the wait, the ladder\'s route goes and is '
      'credited, written once', () async {
    c.graphRouteCandidates = (_) => [_planned];
    unawaited(c.sendMessage(bob, 're: test'));
    await until(() => c.dms.isNotEmpty);

    expect(c.dmRoutes, [_hex(_planned.pathBytes)]);
    expect(c.frames.where((f) => f[0] == cmdAddUpdateContact), hasLength(1));
    await deliver();
    expect(credited, [(route: _hex(_planned.pathBytes), delivered: true)]);
  });
}
