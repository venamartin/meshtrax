import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:traxpoi/traxpoi.dart';

/// The vectors are the contract with traxmapmaker's build, which runs the
/// same file against its own normalization.
void main() {
  final vectors =
      jsonDecode(File('test/normalize_vectors.json').readAsStringSync())
          as Map<String, dynamic>;

  for (final (key, rules) in [
    ('places', NameRules.places),
    ('addresses', NameRules.addresses),
  ]) {
    test('$key vectors', () {
      for (final pair in (vectors[key] as List).cast<List>()) {
        expect(
          normalizeName(pair[0] as String, rules),
          pair[1],
          reason: pair[0] as String,
        );
      }
    });
  }
}
