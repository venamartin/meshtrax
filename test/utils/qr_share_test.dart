import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/utils/qr_share.dart';

void main() {
  testWidgets('the shared picture is a PNG with a white margin', (
    tester,
  ) async {
    final png = await tester.runAsync(
      () => qrPng('meshcore://channel/add?name=Test&secret=00', size: 120),
    );
    expect(png, isNotNull);
    // PNG signature, then the IHDR width and height: 120 + two 48 px margins.
    expect(png!.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    final width = (png[16] << 24) | (png[17] << 16) | (png[18] << 8) | png[19];
    final height = (png[20] << 24) | (png[21] << 16) | (png[22] << 8) | png[23];
    expect(width, 216);
    expect(height, 216);
  });
}
