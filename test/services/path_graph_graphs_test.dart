import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/services/path_graph/graph_book.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Graphs are kept per preset, and a preset can have several (owner,
// 2026-10-26: "what happens if I go to Washington state, how do I choose a
// different pathfinder graph?"). Washington runs the same US preset as
// Monterey Bay, so the preset alone cannot tell them apart; the repeaters
// heard can.
class _Connector extends MeshCoreConnector {
  @override
  String get selfPublicKeyHex => 'ab' * 32;
  @override
  int get pathHashByteWidth => 2;
  @override
  int? get currentFreqHz => 910525000;
  @override
  int? get currentBwHz => 62500;
  @override
  int? get currentSf => 7;
  @override
  int? get currentCr => 5;
}

const _preset = 'm910525000_62500_7_5';

/// A repeater key: [n] picks it, [area] keeps Monterey's and Washington's
/// apart, and its first two bytes are the repeater's code.
String _key(String area, int n) =>
    '${n.toRadixString(16).padLeft(2, '0')}$area'.padRight(64, '7');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<String> opened;
  QueryExecutor open(String name) {
    opened.add(name);
    return NativeDatabase.memory();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    opened = [];
  });

  /// Gives the open graph [count] repeaters of [area], as adverts would.
  void establish(PathGraphService service, String area, {int count = 25}) {
    for (var i = 0; i < count; i++) {
      final key = _key(area, i);
      service.graph!.ingestNode(key.substring(0, 4), pubkey: key);
    }
  }

  /// [count] repeaters of [area] heard on the air, each checked against
  /// the open graph before it is taken in, as the adapter does.
  void hear(PathGraphService service, String area, {int count = 6}) {
    for (var i = 0; i < count; i++) {
      final key = _key(area, i);
      service.adapter!.onRepeaterKeyHeard!(
          key, service.graph!.knowsRepeater(key.substring(0, 4), pubkey: key));
    }
  }

  test('a second graph for the preset gets its own file and stays picked',
      () async {
    final service = PathGraphService();
    await service.start(_Connector(), openDatabase: open);
    expect(opened, ['path_graph_$_preset']);
    expect(service.graphEntry!.isDefault, isTrue);

    final washington = await service.createGraph('Washington');
    expect(washington!.id, '${_preset}_g2');
    expect(opened.last, 'path_graph_${_preset}_g2');
    expect(service.graphEntry!.label, 'Washington');
    await service.stop();

    final later = PathGraphService();
    await later.start(_Connector(), openDatabase: open);
    expect(opened.last, 'path_graph_${_preset}_g2',
        reason: 'the graph picked last is the one the preset opens');
    expect(GraphBook.graphsFor(later.mesh!).map((g) => g.label),
        ['910.525 MHz · 62.5 kHz · SF7 · CR5', 'Washington']);

    await later.switchGraph(GraphBook.graphsFor(later.mesh!).first);
    expect(opened.last, 'path_graph_$_preset');
    await later.renameGraph(later.graphEntry!, 'Monterey Bay');
    expect(GraphBook.graphsFor(later.mesh!).map((g) => g.label),
        ['Monterey Bay', 'Washington']);
    expect(await later.deleteGraph(later.graphEntry!), isFalse,
        reason: 'the open graph cannot be deleted');
    await later.stop();
  });

  test('mostly new repeaters on an established graph suggest a new one',
      () async {
    final service = PathGraphService();
    await service.start(_Connector(), openDatabase: open);
    establish(service, 'aaaa');

    hear(service, 'aaaa');
    expect(service.meshSuggestion, isNull, reason: 'home: all known');
    await service.stop();

    await service.start(_Connector(), openDatabase: open);
    establish(service, 'aaaa');
    hear(service, 'bbbb');
    final suggestion = service.meshSuggestion!;
    expect(suggestion.other, isNull);
    expect((suggestion.heard, suggestion.unknown), (6, 6));

    await service.acceptMeshSuggestion(name: 'Washington');
    expect(service.graphEntry!.label, 'Washington');
    expect(opened.last, 'path_graph_${_preset}_g2');
    expect(service.meshSuggestion, isNull);
    await service.stop();
  });

  test('a fresh graph never asks', () async {
    final service = PathGraphService();
    await service.start(_Connector(), openDatabase: open);
    hear(service, 'bbbb');
    expect(service.meshSuggestion, isNull);
    await service.stop();
  });

  test('"keep this one" quiets the question for that graph', () async {
    final service = PathGraphService();
    await service.start(_Connector(), openDatabase: open);
    establish(service, 'aaaa');
    hear(service, 'bbbb');
    await service.dismissMeshSuggestion();
    expect(service.meshSuggestion, isNull);
    await service.stop();

    await service.start(_Connector(), openDatabase: open);
    establish(service, 'aaaa');
    hear(service, 'bbbb');
    expect(service.meshSuggestion, isNull);
    await service.stop();
  });

  test('the graph that knows the repeaters is the way back', () async {
    final service = PathGraphService();
    await service.start(_Connector(), openDatabase: open);
    establish(service, 'aaaa'); // Monterey Bay
    await service.createGraph('Washington'); // saves Monterey's keys
    establish(service, 'bbbb');

    hear(service, 'aaaa'); // back home
    final suggestion = service.meshSuggestion!;
    expect(suggestion.current.label, 'Washington');
    expect(suggestion.other!.isDefault, isTrue);

    await service.acceptMeshSuggestion();
    expect(opened.last, 'path_graph_$_preset');
    await service.stop();
  });
}
