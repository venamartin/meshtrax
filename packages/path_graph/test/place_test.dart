import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

// The place is an opaque cell key with its neighbours, held in memory
// only; it belongs to one radio.
void main() {
  late PathGraph graph;

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity('ab' * 3, 2);
  });

  tearDown(() => graph.dispose());

  test('set, widened to the block, cleared', () {
    graph.setPlace('c1_2', {'c0_1', 'c2_3'});
    expect(graph.currentCell, 'c1_2');
    expect(graph.nearCells, {'c1_2', 'c0_1', 'c2_3'});

    graph.setPlace(null, const {});
    expect(graph.currentCell, isNull);
    expect(graph.nearCells, isEmpty);
  });

  test('another radio starts with no place', () {
    graph.setPlace('c1_2', const {});
    graph.setRadioIdentity('cd' * 3, 2);
    expect(graph.currentCell, isNull);
  });

  test('never in a checkpoint', () {
    graph.setPlace('c1_2', const {});
    expect(graph.saveSession().toString(), isNot(contains('c1_2')));
    expect(graph.exportGraph().toString(), isNot(contains('c1_2')));
  });
}
