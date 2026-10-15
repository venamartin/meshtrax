import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/path_helper.dart';

// The map's Route & trace builds its trace at the graph's width. It used to
// regroup the graph's 2-byte hops at the radio's path hash size: ambiguous
// 1-byte hops (whose reply was then dropped as narrow), or 3-byte phantoms
// glued from two hops (and no trace sent at all).
void main() {
  // Graph route me → A277 → 1312 → 5CBB (B), and back 5CBB → 1312 → AD77.
  const out = [0xA2, 0x77, 0x13, 0x12, 0x5C, 0xBB];
  const back = [0x5C, 0xBB, 0x13, 0x12, 0xAD, 0x77];

  test('out then back, B once, every hop 2 bytes', () {
    expect(PathHelper.outAndBackPath(out, back, stride: 2), [
      0xA2, 0x77, 0x13, 0x12, 0x5C, 0xBB, //
      0x13, 0x12, 0xAD, 0x77,
    ]);
  });

  test('no way back known: the way out, mirrored', () {
    expect(PathHelper.outAndBackPath(out, null, stride: 2), [
      0xA2, 0x77, 0x13, 0x12, 0x5C, 0xBB, //
      0x13, 0x12, 0xA2, 0x77,
    ]);
  });
}
