import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

const montereyBay =
    MeshId(freqKHz: 910525, bwHz: 62500, sf: 8, cr: 8);
const bench = MeshId(freqKHz: 920000, bwHz: 250000, sf: 10, cr: 5);

void main() {
  test('key and label', () {
    expect(montereyBay.key, 'm910525_62500_8_8');
    expect(montereyBay.label, '910.525 MHz · 62.5 kHz · SF8 · CR8');
    expect(bench.label, '920.000 MHz · 250 kHz · SF10 · CR5');
    expect(MeshId.fromJson(montereyBay.toJson()), montereyBay);
    expect(MeshId.fromJson({'key': 'x'}), isNull);
  });

  group('checkpoints', () {
    late PathGraph graph;
    setUp(() async {
      graph = PathGraph(NativeDatabase.memory(), mesh: montereyBay);
      await graph.init();
    });
    tearDown(() => graph.dispose());

    test('carry the mesh', () {
      expect(graph.saveSession()['mesh'], montereyBay.toJson());
      expect((graph.exportGraph()['graph'] as Map)['mesh'], montereyBay.toJson());
    });

    test('one from another mesh is refused with a plain message', () async {
      final other = PathGraph(NativeDatabase.memory(), mesh: bench);
      await other.init();
      final doc = other.saveSession();
      await other.dispose();
      expect(
          () => graph.loadSession(doc),
          throwsA(isA<FormatException>().having((e) => e.message, 'message',
              contains('920.000 MHz'))));
    });

    test('one without a mesh stamp is taken on trust', () async {
      final old = PathGraph(NativeDatabase.memory());
      await old.init();
      final doc = old.saveSession();
      await old.dispose();
      expect(doc.containsKey('mesh'), isFalse);
      await graph.loadSession(doc);
    });
  });
}
