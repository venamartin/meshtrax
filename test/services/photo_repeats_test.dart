import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/services/photo_repeats.dart';

void main() {
  final viaA = Uint8List.fromList([0xA2, 0x77]);
  final viaAB = Uint8List.fromList([0xA2, 0x77, 0xBE, 0xEF]);
  final viaB = Uint8List.fromList([0xBE, 0xEF]);

  /// [n] packets of 4 bytes each, packet i all i.
  List<Uint8List> blobs(int n) =>
      [for (var i = 0; i < n; i++) Uint8List.fromList(List.filled(4, i))];

  PhotoRepeats photo(int n, {bool hasRepair = false}) =>
      PhotoRepeats(blobs: blobs(n), hasRepair: hasRepair);

  /// A repeater's exact copy of packet [i] of [r] through [path].
  bool heard(PhotoRepeats r, int i, Uint8List path, {bool carOnly = false}) =>
      r.note(i, r.blobs[i], path, 2, carOnly: carOnly);

  group('a photo is complete', () {
    test('once every data packet was passed on', () {
      final r = photo(3);
      heard(r, 0, viaA);
      heard(r, 2, viaA);
      expect(r.complete, isFalse);
      heard(r, 1, viaA);
      expect(r.complete, isTrue);
    });

    test('or all but one, with the repair packet', () {
      final r = photo(4, hasRepair: true);
      heard(r, 0, viaA);
      heard(r, 2, viaA);
      expect(r.complete, isFalse);
      heard(r, 3, viaA);
      expect(r.complete, isTrue);
      expect(r.passedOnCount, 3);
    });

    test('but not on the repair packet alone', () {
      final r = photo(4, hasRepair: true);
      heard(r, 0, viaA);
      heard(r, 3, viaA);
      expect(r.complete, isFalse);
    });
  });

  test('counts every copy, and each path once', () {
    final r = photo(2);
    heard(r, 0, viaA);
    heard(r, 0, viaAB);
    heard(r, 1, Uint8List.fromList(viaA));
    expect(r.copies, 3);
    expect(r.paths, [viaA, viaAB]);
    expect(r.pathHashSize, 2);
    expect(r.passedOnCount, 2);
  });

  test('only a copy of the packet as sent counts: not another sender\'s '
      'with the same prefix and image id, nor one with no repeater', () {
    final r = photo(2);
    expect(r.note(0, Uint8List.fromList([9, 9, 9, 9]), viaA, 2), isFalse);
    expect(r.note(0, r.blobs[0], Uint8List(0), 2), isFalse);
    expect(r.note(5, r.blobs[1], viaA, 2), isFalse);
    expect(r.copies, 0);
    expect(r.passedOnCount, 0);
    expect(r.paths, isEmpty);
  });

  test('a copy only car repeaters carried is shown but says nothing of the '
      'mesh', () {
    final r = photo(2);
    expect(heard(r, 0, viaA, carOnly: true), isTrue);
    expect(r.copies, 1);
    expect(r.paths, [viaA]);
    expect(r.passedOn(0), isFalse);
    expect(r.sendAgain(0), isTrue);
  });

  test('Pathfinder hears of each first repeater once per photo', () {
    final r = photo(3);
    expect(r.firstThrough(viaA, 2), isTrue);
    expect(r.firstThrough(viaAB, 2), isFalse);
    expect(r.firstThrough(viaB, 2), isTrue);
    expect(r.firstThrough(Uint8List.fromList(viaB), 2), isFalse);
  });

  group('a packet goes once more', () {
    test('when no repeater was heard passing it on', () {
      final r = photo(3);
      heard(r, 0, viaA);
      expect(r.sendAgain(0), isFalse);
      expect(r.sendAgain(1), isTrue);
    });

    test('and keeps going while copies are heard', () {
      final r = photo(3);
      expect(r.sendAgain(0), isTrue);
      heard(r, 0, viaA);
      expect(r.sendAgain(1), isTrue);
    });

    test('but waits after one sent again while nothing is heard', () {
      final r = photo(4);
      expect(r.sendAgain(0), isTrue);
      expect(r.sendAgain(1), isFalse);
      expect(r.sendAgain(2), isFalse);
      // Any copy heard again, even of another packet, ends the wait: a
      // repeater hears this radio.
      heard(r, 2, viaA);
      expect(r.sendAgain(3), isTrue);
    });

    test('and a car repeater\'s copy doesn\'t end the wait', () {
      final r = photo(3);
      expect(r.sendAgain(0), isTrue);
      heard(r, 0, viaA, carOnly: true);
      expect(r.sendAgain(1), isFalse);
    });
  });
}
