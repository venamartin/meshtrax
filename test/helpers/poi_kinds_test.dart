import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/helpers/poi_kinds.dart';
import 'package:meshtrax/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  test('a search names a kind by its label or an English word for it', () {
    expect(poiKindsNamed(en, 'toilet').keys, ['amenity=toilets']);
    expect(poiKindsNamed(en, 'Restrooms').keys, ['amenity=toilets']);
    expect(poiKindsNamed(en, 'gas station').keys, ['amenity=fuel']);
    expect(poiKindsNamed(en, 'campground').keys, ['tourism=camp_site']);
  });

  test('"park" also names national and state parks', () {
    expect(poiKindsNamed(en, 'national park').keys, [
      'boundary=protected_area',
    ]);
    expect(poiKindsNamed(en, 'State Parks').keys, ['boundary=protected_area']);
    expect(poiKindsNamed(en, 'park').keys, contains('boundary=protected_area'));
    expect(
      poiKindsNamed(en, 'wilderness').keys,
      contains('boundary=protected_area'),
    );
  });

  test('a label in the app\'s language names its kind', () {
    final de = lookupAppLocalizations(const Locale('de'));
    expect(poiKindsNamed(de, 'Tankstelle').keys, ['amenity=fuel']);
  });

  test('a place\'s own name names no kind', () {
    expect(poiKindsNamed(en, 'Mount Sneffels'), isEmpty);
    expect(poiKindsNamed(en, 'Camp Bird Mine'), isEmpty);
    expect(poiKindsNamed(en, 'Yosemite National Park'), isEmpty);
  });
}
