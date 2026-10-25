import 'package:drift/drift.dart' show QueryExecutor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:path_graph/path_graph.dart';
import 'package:shared_preferences/shared_preferences.dart';

// One graph database per mesh (owner, 2026-10-13): the file follows the
// connected radio's preset, and the graph learned before meshes were kept
// apart belongs to the first mesh that connects.
class _Connector extends MeshCoreConnector {
  int? freq, bw, sf, cr;

  @override
  String get selfPublicKeyHex => 'ab' * 32;
  @override
  int get pathHashByteWidth => 2;
  @override
  int? get currentFreqHz => freq;
  @override
  int? get currentBwHz => bw;
  @override
  int? get currentSf => sf;
  @override
  int? get currentCr => cr;

  void tune(int freqHz, int bwHz, int sf_, int cr_) {
    freq = freqHz;
    bw = bwHz;
    sf = sf_;
    cr = cr_;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  // The connector batches change notices (50 ms); the reopen then runs on
  // the service's queue, which the next start() joins and waits for.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 150));

  test('the file follows the connected mesh and the last mesh is remembered',
      () async {
    final c = _Connector();
    final service = PathGraphService();
    final opened = <String>[];
    QueryExecutor open(String name) {
      opened.add(name);
      return NativeDatabase.memory();
    }

    await service.start(c, openDatabase: open);
    expect(opened, ['path_graph'], reason: 'no mesh was ever seen');
    expect(service.mesh, isNull);

    final before = service.graph;
    c.tune(910525000, 62500, 8, 8);
    await settle();
    await service.start(c, openDatabase: open); // joins the queue: waits
    expect(opened, ['path_graph', 'path_graph_m910525000_62500_8_8']);
    expect(service.mesh?.label, '910.525 MHz · 62.5 kHz · SF8 · CR8');
    expect(service.graph, isNot(same(before)));
    expect(service.graph!.mesh, service.mesh);

    c.tune(920000000, 250000, 10, 5);
    await settle();
    await service.start(c, openDatabase: open);
    expect(opened.last, 'path_graph_m920000000_250000_10_5');

    // Same preset again: nothing reopens.
    c.tune(920000000, 250000, 10, 5);
    await settle();
    expect(opened, hasLength(3));
    await service.stop();

    // A fresh service before any radio connects opens the last mesh.
    final later = PathGraphService();
    final d = _Connector();
    await later.start(d, openDatabase: open);
    expect(opened.last, 'path_graph_m920000000_250000_10_5');
    expect(later.mesh?.key, 'm920000000_250000_10_5');
    await later.stop();
  });

  test('a database handed in by the caller is never swapped', () async {
    final c = _Connector()..tune(910525000, 62500, 8, 8);
    final service = PathGraphService();
    await service.start(c, database: NativeDatabase.memory());
    final graph = service.graph;
    expect(service.mesh?.key, 'm910525000_62500_8_8');

    c.tune(920000000, 250000, 10, 5);
    await settle();
    await service.start(c, database: NativeDatabase.memory());
    expect(service.graph, same(graph), reason: 'the bench retunes mid-run');
    await service.stop();
  });

  test('file names', () {
    expect(PathGraphService.databaseNameFor(null), 'path_graph');
    expect(
        PathGraphService.databaseNameFor(
            const MeshId(freqHz: 910525000, bwHz: 62500, sf: 8, cr: 8)),
        'path_graph_m910525000_62500_8_8');
  });
}
