@TestOn('mac-os')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxpix/traxpix.dart';
import 'package:traxpix_litert/src/image_codec_bundle.dart';
import 'package:traxpix_litert/src/image_safety.dart';
import 'package:traxpix_litert/src/litert_api.dart';
import 'package:traxpix_litert/src/litert_codec_backend.dart';

/// Faces against the Python tests that chose the settings: on every crop,
/// as many faces as Python found, and the same blurred and dark covers.
/// Needs, besides TRAXPIX_LITERT_LIB and TRAXPIX_LITERT_DIR:
///   TRAXPIX_FACES_DIR  the two BlazeFace models
///   TRAXPIX_FACES_REF  crops/*.rgb, all-faces3.tsv (name, faces found),
///                      and Python's covers in blurred3/ and dark/
void main() {
  final env = Platform.environment;
  final lib = env['TRAXPIX_LITERT_LIB'];
  final dir = env['TRAXPIX_LITERT_DIR'];
  final faces = env['TRAXPIX_FACES_DIR'];
  final ref = env['TRAXPIX_FACES_REF'];
  final skip = [lib, dir, faces, ref].contains(null)
      ? 'set TRAXPIX_LITERT_LIB, TRAXPIX_LITERT_DIR, TRAXPIX_FACES_DIR and '
            'TRAXPIX_FACES_REF'
      : null;

  test(
    'finds the faces Python found, and covers them the same',
    () async {
      final bundle = ImageCodecBundle.inDirectory(
        dir!,
        weightCache: false,
        facesDir: faces,
      );
      final backend = LiteRtImageCodecBackend(
        bundle,
        AeicRansCoders(
          EntropyTables.parse(await File(bundle.tablesPath).readAsBytes()),
        ),
        api: LiteRtApi.open(lib),
        threads: 4,
      );
      addTearDown(backend.dispose);
      final counts = {
        for (final line in File('$ref/all-faces3.tsv').readAsLinesSync())
          if (line.isNotEmpty)
            line.split('\t')[0]: int.parse(line.split('\t')[1]),
      };
      final wrongCount = <String>[];
      var pictures = 0;
      var bytesOff = 0;
      var worst = 0;
      final sw = Stopwatch()..start();
      for (final MapEntry(key: name, value: want) in counts.entries) {
        final rgb = File('$ref/crops/$name.rgb').readAsBytesSync();
        for (final (cover, folder) in [
          (FaceCover.blur, 'blurred3'),
          (FaceCover.dark, 'dark'),
        ]) {
          final (covered, found) = backend.coverFaces(rgb, cover);
          if (cover == FaceCover.blur && found != want) {
            wrongCount.add('$name: $found, Python $want');
          }
          final python = File('$ref/$folder/$name-oval.rgb');
          if (!python.existsSync()) continue;
          final expected = python.readAsBytesSync();
          pictures++;
          for (var i = 0; i < expected.length; i++) {
            final d = (expected[i] - covered[i]).abs();
            if (d > 0) bytesOff++;
            if (d > worst) worst = d;
          }
        }
        expect(
          backend.coverFaces(rgb, FaceCover.none).$1,
          same(rgb),
          reason: 'no cover, no change',
        );
      }
      final perPhoto = sw.elapsedMilliseconds / (counts.length * 2);
      // ignore: avoid_print
      print(
        '${counts.length} crops; face counts off on ${wrongCount.length} '
        '$wrongCount; $pictures covers compared, $bytesOff bytes differ, '
        'by $worst at most; ${perPhoto.toStringAsFixed(0)} ms a cover',
      );
      // The same faces everywhere. The covers can differ at a few edge
      // pixels: this runtime and Python's give the detector's numbers in
      // slightly different last bits (with set boxes, the covers match
      // Python's exactly: packages/traxpix/test/face_cover_test.dart).
      expect(wrongCount, isEmpty);
      expect(bytesOff, lessThan(pictures * 100));
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
