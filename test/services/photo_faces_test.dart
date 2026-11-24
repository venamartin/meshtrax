import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/services/photo_store.dart';
import 'package:traxpix_litert/traxpix_litert.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sending gets the face models, copied out of the app once', () async {
    final tmp = Directory.systemTemp.createTempSync('photo-faces');
    addTearDown(() => tmp.deleteSync(recursive: true));
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tmp.path,
        );
    final bundle = await PhotoStore.instance.sendingBundle();
    for (final (path, name) in [
      (bundle.faceShortPath!, kFaceShortRangeFile),
      (bundle.faceFullPath!, kFaceFullRangeFile),
    ]) {
      final asset = await rootBundle.load('assets/models/$name');
      expect(File(path).lengthSync(), asset.lengthInBytes);
    }
    final copied = File(bundle.faceShortPath!).lastModifiedSync();
    await PhotoStore.instance.sendingBundle();
    expect(File(bundle.faceShortPath!).lastModifiedSync(), copied);
    expect(PhotoStore.instance.bundle.faceShortPath, isNull);
  });
}
