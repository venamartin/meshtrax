import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxpix_litert/traxpix_litert.dart';

void main() {
  test('the tap model takes the colours from 0 to 1 and a dot at the tap', () {
    const side = kTapSegmenterSize;
    final rgb = Uint8List(side * side * 3);
    rgb[(10 * side + 20) * 3 + 1] = 255;
    // A tap on the middle of pixel (100, 200).
    final input = tapModelInput(rgb, 100.5 / side, 200.5 / side);
    expect(input.length, side * side * 4);
    expect(input[(10 * side + 20) * 4 + 1], 1.0, reason: 'green, from 0 to 1');
    expect(input[(200 * side + 100) * 4 + 3], 1.0, reason: 'the pixel tapped');
    expect(input[(200 * side + 101) * 4 + 3], closeTo(0.5, 1e-6));
    expect(input[(200 * side + 102) * 4 + 3], 0.0);
    var dot = 0.0;
    for (var i = 3; i < input.length; i += 4) {
      dot += input[i];
    }
    expect(dot, closeTo(1 + 4 * 0.5 + 4 * (1.5 - 1.41421356), 1e-4));
  });
}
