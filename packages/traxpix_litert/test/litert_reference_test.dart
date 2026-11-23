@TestOn('mac-os')
library;

import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:traxpix/traxpix.dart';
import 'package:traxpix_litert/src/litert_reference.dart';
import 'package:traxpix_litert/traxpix_litert.dart';

/// The Mac's LiteRT reference for the phone test, from the same Dart code the
/// phones run. Needs, from the environment:
///   TRAXPIX_LITERT_LIB    the Mac's libCLiteRT_mac.dylib
///   TRAXPIX_LITERT_DIR    the .tflite files and aeic_cdf_ft8.bin
///   TRAXPIX_LITERT_PHOTOS the 190 photos, 512x512 .rgb
///   TRAXPIX_LITERT_REBUILD the 12 comparison photos, 512x512 .rgb
///   TRAXPIX_LITERT_OUT    where ref.txt and the rebuilt pictures go
void main() {
  final env = Platform.environment;
  final lib = env['TRAXPIX_LITERT_LIB'];
  final dir = env['TRAXPIX_LITERT_DIR'];
  final photos = env['TRAXPIX_LITERT_PHOTOS'];
  final rebuildDir = env['TRAXPIX_LITERT_REBUILD'];
  final out = env['TRAXPIX_LITERT_OUT'];
  final skip = [lib, dir, photos, rebuildDir, out].contains(null)
      ? 'set the TRAXPIX_LITERT_* variables'
      : null;

  List<File> rgbIn(String folder) =>
      Directory(folder)
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.rgb'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  String nameOf(File f) => f.uri.pathSegments.last.replaceAll('.rgb', '');

  test(
    '190 photos: each decodes to the sender\'s latent; ref.txt written',
    () async {
      final bundle = ImageCodecBundle.inDirectory(dir!, weightCache: false);
      final session = await ImageCodecSession.spawn(
        bundle,
        threads: 4,
        libraryPath: lib,
      );
      final api = LiteRtApi.open(lib);
      final environment = LiteRtEnvironment.create(api);
      final side = LiteRtModel.load(environment, bundle.sidePath, threads: 4);
      final lines = <String>[];
      var bad = 0;
      final sw = Stopwatch()..start();
      for (final f in rgbIn(photos!)) {
        final rgb = f.readAsBytesSync();
        final sent = await session.encode(rgb);
        final bitstream = sent.bitstream;
        if (bitstream == null) {
          lines.add(referenceLine(nameOf(f), null, null, sent.scores));
          continue;
        }
        final latent = await session.decodeToLatent(bitstream);
        final yHat = side.run([aeicRgbToChw(rgb, 512)])['output_6']!;
        var differ = 0;
        for (var i = 0; i < yHat.length; i++) {
          if (latent[i] != yHat[i]) differ++;
        }
        if (differ > 0) {
          bad++;
          // ignore: avoid_print
          print('${nameOf(f)}: $differ latent values differ from the sender');
        }
        lines.add(referenceLine(nameOf(f), bitstream, latent, sent.scores));
      }
      side.dispose();
      environment.dispose();
      await session.dispose();
      File('$out/ref.txt').writeAsStringSync('${lines.join('\n')}\n');
      // ignore: avoid_print
      print(
        '${lines.length} photos in ${sw.elapsed.inSeconds} s, '
        '$bad not decoded to the sender\'s latent',
      );
      expect(bad, 0);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 30)),
  );

  test(
    'the same bitstreams with 1 and 8 threads and with the weight cache',
    () async {
      final bundle = ImageCodecBundle.inDirectory(dir!, weightCache: false);
      final ref = {
        for (final line in File('$out/ref.txt').readAsLinesSync())
          if (ReferencePhoto.parse(line) case final p) p.name: p,
      };
      final files = rgbIn(photos!).take(24).toList();
      for (final (threads, cache) in [(1, false), (8, false), (4, true)]) {
        final session = await ImageCodecSession.spawn(
          bundle,
          threads: threads,
          libraryPath: lib,
          weightCacheDir: cache ? '$out/xnnpack-cache' : null,
        );
        var same = 0;
        for (final f in files) {
          final sent = await session.encode(f.readAsBytesSync());
          final mac = ref[nameOf(f)]!.bitstream;
          if (sent.bitstream != null &&
              mac != null &&
              base64.encode(sent.bitstream!) == base64.encode(mac)) {
            same++;
          }
        }
        await session.dispose();
        // ignore: avoid_print
        print('threads $threads, cache $cache: $same of ${files.length} same');
        expect(same, files.length);
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 30)),
  );

  test(
    '12 rebuilds: time, memory, PSNR; pictures saved for the phones',
    () async {
      final bundle = ImageCodecBundle.inDirectory(dir!, weightCache: false);
      // One variant per run, so the process's peak footprint is its own.
      final cache = env['TRAXPIX_LITERT_CACHE'] == '1';
      {
        final session = await ImageCodecSession.spawn(
          bundle,
          threads: 4,
          libraryPath: lib,
          weightCacheDir: cache ? '$out/xnnpack-cache' : null,
        );
        var total = 0;
        final psnrs = <double>[];
        for (final f in rgbIn(rebuildDir!)) {
          final rgb = f.readAsBytesSync();
          final sent = await session.encode(rgb);
          final sw = Stopwatch()..start();
          final rebuilt = await session.rebuild(sent.bitstream!);
          total += sw.elapsedMilliseconds;
          final pixels = rebuilt.rgb!;
          psnrs.add(psnr(rgb, pixels));
          if (!cache) {
            File('$out/${nameOf(f)}.mac.rgb').writeAsBytesSync(pixels);
          }
        }
        await session.dispose();
        final mean = psnrs.reduce((a, b) => a + b) / psnrs.length;
        // ignore: avoid_print
        print(
          'cache $cache: ${psnrs.length} rebuilds, ${total ~/ psnrs.length} '
          'ms each, mean PSNR ${mean.toStringAsFixed(2)} dB, peak footprint '
          '${(_peakFootprint() / (1 << 30)).toStringAsFixed(2)} GiB',
        );
      }
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 30)),
  );

  test(
    'a rebuilt picture enlarges 4x, passes the check and shrinks back to it',
    () async {
      final session = await ImageCodecSession.spawn(
        ImageCodecBundle.inDirectory(dir!, weightCache: false),
        threads: 4,
        libraryPath: lib,
      );
      for (final f in rgbIn(rebuildDir!).take(3)) {
        final sent = await session.encode(f.readAsBytesSync());
        final rebuilt = (await session.rebuild(sent.bitstream!)).rgb!;
        final sw = Stopwatch()..start();
        final enhanced = await session.enhance(rebuilt);
        final ms = sw.elapsedMilliseconds;
        expect(enhanced.flagged, isFalse, reason: nameOf(f));
        final big = enhanced.rgb!;
        expect(big.length, 2048 * 2048 * 3);
        final back = psnr(rebuilt, shrink4(big));
        // ignore: avoid_print
        print(
          '${nameOf(f)}: 4x in $ms ms, back at 512 '
          '${back.toStringAsFixed(1)} dB from the rebuild',
        );
        expect(back, greaterThan(22));
        // A rebuild after the enlargement still works.
        expect((await session.rebuild(sent.bitstream!)).rgb, rebuilt);
      }
      await session.dispose();
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 10)),
  );
}

/// A 2048 x 2048 picture back at 512 x 512, each pixel the mean of 4 x 4.
Uint8List shrink4(Uint8List big) {
  const side = 512, bigSide = 2048;
  final small = Uint8List(side * side * 3);
  for (var y = 0; y < side; y++) {
    for (var x = 0; x < side; x++) {
      for (var c = 0; c < 3; c++) {
        var sum = 0;
        for (var dy = 0; dy < 4; dy++) {
          final row = (y * 4 + dy) * bigSide + x * 4;
          for (var dx = 0; dx < 4; dx++) {
            sum += big[(row + dx) * 3 + c];
          }
        }
        small[(y * side + x) * 3 + c] = (sum + 8) >> 4;
      }
    }
  }
  return small;
}

double psnr(Uint8List a, Uint8List b) {
  var sum = 0.0;
  for (var i = 0; i < a.length; i++) {
    final d = a[i] - b[i];
    sum += d * d;
  }
  final mse = sum / a.length;
  return mse == 0 ? 99 : 10 * math.log(255 * 255 / mse) / math.ln10;
}

/// This process's peak footprint (`ri_lifetime_max_phys_footprint`).
int _peakFootprint() {
  final info = Uint64List(64);
  final buffer = info.buffer.asUint8List();
  final pointer = _malloc(buffer.length);
  try {
    final rc = _procPidRusage(pid, 4, pointer);
    if (rc != 0) return -1;
    final bytes = pointer.cast<Uint64>().asTypedList(info.length);
    // rusage_info_v4: ri_lifetime_max_phys_footprint is the 31st word.
    return bytes[30];
  } finally {
    _free(pointer);
  }
}

final _libc = DynamicLibrary.process();
final _procPidRusage = _libc
    .lookupFunction<
      Int32 Function(Int32, Int32, Pointer<Void>),
      int Function(int, int, Pointer<Void>)
    >('proc_pid_rusage');
final _malloc = _libc
    .lookupFunction<Pointer<Void> Function(Size), Pointer<Void> Function(int)>(
      'malloc',
    );
final _free = _libc
    .lookupFunction<Void Function(Pointer<Void>), void Function(Pointer<Void>)>(
      'free',
    );
