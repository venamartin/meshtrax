import 'package:flutter_test/flutter_test.dart';
import 'package:traxpix_litert/traxpix_litert.dart';

void main() {
  final all = [...kImageCodecFiles, ...kImageCodecLicences];

  test('the model files add up to the hosted bundle', () {
    expect(kImageCodecFiles.fold<int>(0, (s, f) => s + f.bytes), 1165717164);
  });

  test('every URL is the version folder, then the sha256, then the name', () {
    for (final f in all) {
      expect(f.sha256, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect(f.url, '${f.base}/${f.sha256}/${f.name}');
      expect(f.base, kImageCodecBaseUrl);
    }
  });

  test('the bundle names every model file, and nothing else', () {
    final bundle = ImageCodecBundle.inDirectory('/m');
    expect(
      {for (final p in bundle.allPaths) p.split('/').last},
      {for (final f in kImageCodecFiles) f.name},
    );
    expect(bundle.weightCacheDir, '/m/xnnpack');
    expect(
      ImageCodecBundle.inDirectory('/m', weightCache: false).weightCacheDir,
      isNull,
    );
  });
}
