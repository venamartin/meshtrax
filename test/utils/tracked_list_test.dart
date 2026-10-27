import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/utils/tracked_list.dart';

// What the connector builds from a TrackedList (its contact copies, the
// room-author index) is kept until the revision moves. Every way of
// changing the list must move it, and reading must not.
void main() {
  TrackedList<int> list() => TrackedList<int>()..addAll([1, 2, 3]);

  test('every write moves the revision', () {
    final writes = <String, void Function(TrackedList<int>)>{
      'add': (l) => l.add(9),
      'addAll': (l) => l.addAll([8, 9]),
      'insert': (l) => l.insert(0, 9),
      'insertAll': (l) => l.insertAll(1, [8, 9]),
      'remove': (l) => l.remove(2),
      'removeAt': (l) => l.removeAt(0),
      'removeLast': (l) => l.removeLast(),
      'removeRange': (l) => l.removeRange(0, 2),
      'removeWhere': (l) => l.removeWhere((e) => e.isOdd),
      'retainWhere': (l) => l.retainWhere((e) => e.isOdd),
      'clear': (l) => l.clear(),
      'sort': (l) => l.sort((a, b) => b - a),
      'index set': (l) => l[0] = 9,
      'setAll': (l) => l.setAll(0, [7]),
      'setRange': (l) => l.setRange(0, 1, [7]),
      'fillRange': (l) => l.fillRange(0, 1, 7),
      'replaceRange': (l) => l.replaceRange(0, 1, [7, 7]),
      'length': (l) => l.length = 1,
    };
    for (final MapEntry(key: name, value: write) in writes.entries) {
      final l = list();
      final before = l.revision;
      write(l);
      expect(l.revision, isNot(before), reason: name);
    }
  });

  test('a write that changes nothing, or a read, keeps it', () {
    final l = list();
    final before = l.revision;
    l.remove(7);
    l.removeWhere((e) => e > 5);
    l.retainWhere((e) => e < 5);
    expect(l.where((e) => e > 1).toList(), [2, 3]);
    expect(l.contains(3), isTrue);
    expect(l.revision, before);

    final empty = TrackedList<int>();
    empty.clear();
    expect(empty.revision, 0);
  });
}
