import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

// The app's "a different mesh?" check asks the open graph whether it knew
// each repeater heard: by code, and by key where the graph has one, since
// a code another repeater shares on another mesh is not this one.
void main() {
  late PathGraph graph;
  const key = 'a277c0ffee' '0000000000000000000000000000000000000000000000000000';

  setUp(() async {
    graph = PathGraph(NativeDatabase.memory());
    await graph.init();
    graph.setRadioIdentity('ab' * 32, 2);
  });

  tearDown(() => graph.dispose());

  test('a repeater the graph holds is known; an unheard code is not', () {
    graph.ingestNode('A277', pubkey: key);
    expect(graph.knowsRepeater('a277', pubkey: key), isTrue);
    expect(graph.knowsRepeater('A278'), isFalse);
    expect(graph.repeaterKeys(), [key]);
  });

  test('the same code with another key is another repeater', () {
    graph.ingestNode('A277', pubkey: key);
    expect(graph.knowsRepeater('A277', pubkey: 'a277beef${'0' * 56}'),
        isFalse);
  });

  test('a key prefix, as some Discover answers carry, still matches', () {
    graph.ingestNode('A277', pubkey: key);
    expect(graph.knowsRepeater('A277', pubkey: key.substring(0, 16)), isTrue);
  });

  test('a code known without a key is known', () {
    graph.ingestNode('A277');
    expect(graph.knowsRepeater('A277', pubkey: key), isTrue);
    expect(graph.repeaterKeys(), isEmpty);
  });
}
