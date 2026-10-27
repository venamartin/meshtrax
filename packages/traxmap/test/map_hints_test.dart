import 'package:flutter_test/flutter_test.dart';
import 'package:traxmap/traxmap.dart';

void main() {
  test('reads desert parks and ignores what it does not know', () {
    final hints = MapHints.parse('''
{"schema_version": 1, "build": "2026102701",
 "parks": {"desert": ["Anza-Borrego Desert State Park", "Joshua Tree National Park"]},
 "closures": [{"name": "Tioga Road"}]}
''')!;
    expect(hints.desertParks, [
      'Anza-Borrego Desert State Park',
      'Joshua Tree National Park',
    ]);
    expect(hints.styleLists['desert-parks'], hints.desertParks);
  });

  test('a newer schema is not read', () {
    expect(MapHints.parse('{"schema_version": 2, "parks": {}}'), isNull);
  });
}
