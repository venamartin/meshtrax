import 'dart:collection';

/// A list that counts its changes, so whatever is built from it (a copy, an
/// index) can be kept until the list changes instead of being rebuilt on
/// every read. Every write, however it is made, bumps [revision].
class TrackedList<E> extends ListBase<E> {
  final List<E> _items = [];
  int _revision = 0;

  int get revision => _revision;

  @override
  int get length => _items.length;

  @override
  set length(int value) {
    _items.length = value;
    _revision++;
  }

  @override
  E operator [](int index) => _items[index];

  @override
  void operator []=(int index, E value) {
    _items[index] = value;
    _revision++;
  }

  @override
  void add(E element) {
    _items.add(element);
    _revision++;
  }

  @override
  void addAll(Iterable<E> iterable) {
    _items.addAll(iterable);
    _revision++;
  }

  @override
  void insert(int index, E element) {
    _items.insert(index, element);
    _revision++;
  }

  @override
  void insertAll(int index, Iterable<E> iterable) {
    _items.insertAll(index, iterable);
    _revision++;
  }

  @override
  bool remove(Object? element) {
    final removed = _items.remove(element);
    if (removed) _revision++;
    return removed;
  }

  @override
  E removeAt(int index) {
    final removed = _items.removeAt(index);
    _revision++;
    return removed;
  }

  @override
  void removeWhere(bool Function(E element) test) {
    final before = _items.length;
    _items.removeWhere(test);
    if (_items.length != before) _revision++;
  }

  @override
  void retainWhere(bool Function(E element) test) {
    final before = _items.length;
    _items.retainWhere(test);
    if (_items.length != before) _revision++;
  }

  @override
  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    _revision++;
  }

  @override
  void sort([int Function(E a, E b)? compare]) {
    _items.sort(compare);
    _revision++;
  }
}
