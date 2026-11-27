import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/path_helper.dart';
import 'package:meshtrax/services/photo_repeats.dart';

void main() {
  final viaA = Uint8List.fromList([0xA2, 0x77]);
  final viaAB = Uint8List.fromList([0xA2, 0x77, 0xBE, 0xEF]);
  final viaB = Uint8List.fromList([0xBE, 0xEF]);

  PhotoRepeats photo(int n, {bool hasRepair = false}) =>
      PhotoRepeats(packets: n, hasRepair: hasRepair, messageId: 'row');

  /// A repeater's copy of packet [i] of [r] through [path]; with [carOnly],
  /// every repeater in it moves with the user.
  void heard(PhotoRepeats r, int i, Uint8List path, {bool carOnly = false}) =>
      r.note(
        i,
        path,
        2,
        repeaters: carOnly
            ? const {}
            : {
                for (var at = 0; at < path.length; at += 2)
                  PathHelper.hopHex(path.sublist(at, at + 2)),
              },
      );

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

  test('a copy only car repeaters carried is shown but says nothing of the '
      'mesh', () {
    final r = photo(2);
    heard(r, 0, viaA, carOnly: true);
    expect(r.copies, 1);
    expect(r.paths, [viaA]);
    expect(r.passedOn(0), isFalse);
  });

  test('Pathfinder hears of each first repeater once per photo', () {
    final r = photo(3);
    expect(r.firstThrough(viaA, 2), isTrue);
    expect(r.firstThrough(viaAB, 2), isFalse);
    expect(r.firstThrough(viaB, 2), isTrue);
    expect(r.firstThrough(Uint8List.fromList(viaB), 2), isFalse);
  });
}
