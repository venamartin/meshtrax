import 'dart:io';

import 'package:test/test.dart';

void main() {
  test('works offline: no runtime dependencies, no network code', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(
      RegExp(r'^dependencies:', multiLine: true).hasMatch(pubspec),
      isFalse,
    );
    final sources = Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>();
    expect(sources, isNotEmpty);
    for (final f in sources) {
      final src = f.readAsStringSync();
      for (final word in ['package:http', 'HttpClient', 'Socket', 'Uri.']) {
        expect(src, isNot(contains(word)), reason: '${f.path}: $word');
      }
    }
  });
}
