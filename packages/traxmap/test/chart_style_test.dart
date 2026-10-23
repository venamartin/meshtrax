import 'dart:convert';
import 'dart:io';

import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;
import 'package:flutter_test/flutter_test.dart';

/// The chart styles' layers grouped by role (tool/make_chart_layers.py),
/// evaluated by the renderer against features as traxmapmaker writes them.
void main() {
  Map<String, Object?> json(String id) =>
      jsonDecode(File('assets/styles/$id.json').readAsStringSync())
          as Map<String, Object?>;

  final warnings = <String>[];
  final light = vt.ThemeReader(logger: vt.Logger.custom(onWarn: warnings.add))
      .read(json('charts-light'));

  vt.ThemeLayer byId(String id) => light.layers.firstWhere((l) => l.id == id);

  vt.EvalContext feature(
    Map<String, Object?> properties, {
    String type = 'Point',
    double zoom = 14,
  }) => vt.EvalContext(zoom: zoom, properties: properties, geometryType: type);

  bool matches(String id, Map<String, Object?> p, {String type = 'Point'}) {
    final v = byId(id).filter(feature(p, type: type));
    return v == true;
  }

  String label(String id, Map<String, Object?> p, {double zoom = 14}) =>
      (byId(id) as vt.SymbolThemeLayer).textField.eval(feature(p, zoom: zoom));

  test('both chart styles read without a skipped layer', () {
    expect(warnings, isEmpty);
    final dark = vt.ThemeReader(logger: vt.Logger.custom(onWarn: warnings.add))
        .read(json('charts-dark'));
    expect(warnings, isEmpty);
    expect(
      [for (final l in dark.layers) l.id],
      [for (final l in light.layers) l.id],
    );
    // No light-style halo left on a dark label.
    final darkJson = json('charts-dark');
    for (final l in darkJson['layers']! as List) {
      final paint = (l as Map)['paint'] as Map? ?? const {};
      expect(paint['text-halo-color'], isNot('#ffffff'), reason: '${l['id']}');
    }
  });

  test('clearances never overstate, in feet or metres', () {
    const bridge = {'class': 'BRIDGE', 'anchor': 1};
    expect(label('clearance', {...bridge, 'clearance_m': 19.8}), 'VC 65 ft');
    // 6.4 m is NOAA's 21 ft; plain rounding would say 21, flooring 20.
    expect(label('clearance', {...bridge, 'clearance_m': 6.4}), 'VC 21 ft');
    // 1.5 m is 4.92 ft: charted 5, never rounded up past it.
    expect(label('clearance', {...bridge, 'clearance_m': 1.5}), 'VC 5 ft');
    expect(
      label('clearance', {
        ...bridge,
        'clearance_closed_m': 4.3,
        'clearance_open_m': 41.1,
        'horizontal_clearance_m': 27.4,
      }),
      'VC 14 ft closed, 135 ft open HC 90 ft',
    );
    expect(
      label('clearance', {
        ...bridge,
        'clearance_m': 30,
        'clearance_safe_m': 27.7,
      }),
      'Safe VC 91 ft',
      reason: 'the charted safe clearance wins',
    );
    expect(label('clearance-m', {...bridge, 'clearance_m': 19.8}), 'VC 19.8 m');
    expect(matches('clearance', bridge), isFalse, reason: 'no clearance');
    expect(
      matches('clearance', {
        'class': 'BRIDGE',
        'clearance_m': 19.8,
      }, type: 'Polygon'),
      isFalse,
      reason: 'areas are labelled from their anchor',
    );
  });

  test('regulated areas say exactly what they are', () {
    String area(Map<String, Object?> p) =>
        label('regulated-label', {'anchor': 1, ...p}, zoom: 12);
    expect(
      area({
        'class': 'RESARE',
        'restriction': 'entry',
        'restrictions': 'entry_restricted',
      }),
      'Entry restricted',
    );
    expect(
      area({
        'class': 'RESARE',
        'restriction': 'entry',
        'restrictions': 'fishing_prohibited,entry_prohibited',
      }),
      'Entry prohibited',
    );
    expect(
      area({
        'class': 'ACHARE',
        'categories': 'unrestricted',
        'name': 'San Juan Harbor, P.R., Temporary Anchorage Area E',
      }),
      'Anch E',
    );
    expect(
      area({
        'class': 'ACHARE',
        'categories': 'unrestricted,explosives',
        'name': 'C',
      }),
      'Explos Anch C',
    );
    expect(
      area({'class': 'DMPGRD', 'category': 'explosives', 'disused': 1}),
      'Disused explos dumping ground',
    );
    expect(
      area({'class': 'DMPGRD', 'category': 'spoil_ground'}),
      'Spoil ground',
    );
    expect(
      area({'class': 'MIPARE', 'category': 'submarine_exercise_area'}),
      'Submarine exercise area',
    );
    expect(
      area({'class': 'RESARE', 'category': 'nature_reserve', 'name': 'Area A'}),
      'Nature reserve\nArea A',
    );
    expect(
      area({
        'class': 'RESARE',
        'category': 'nature_reserve',
        'name': 'Sea Turtles Critical Habitat',
      }),
      'Nature reserve',
      reason: 'a long name would be a block of text; a tap gives it',
    );
    // A caution point says what it is warned of, or (!).
    expect(
      label('regulated-label', {'class': 'CTNARE', 'info': 'Shoal'}, zoom: 12),
      'Shoal',
    );
    expect(
      matches('regulated-label', {'class': 'SWPARE', 'anchor': 1}),
      isFalse,
    );
  });

  test('radio: R Bn only for radiobeacons; broadcast towers by call sign', () {
    expect(
      label('harbour-label', {
        'class': 'RDOSTA',
        'call_sign': 'WAEL',
        'frequency_khz': 600.0,
      }),
      'WAEL 600 kHz',
    );
    expect(
      label('harbour-label', {
        'class': 'RDOSTA',
        'category': 'aeronautical_radiobeacon',
        'call_sign': 'PNG',
      }),
      'Aero R Bn PNG',
    );
    expect(matches('radio', {'class': 'RDOSTA', 'call_sign': 'WAEL'}), isFalse);
    expect(
      label('harbour-label', {'class': 'CGUSTA', 'name': 'San Juan'}),
      'CG San Juan',
    );
  });

  test('buoy names: the number below z15, the full name from z15', () {
    const buoy = {'name': 'Army Terminal Channel Lighted Buoy 2'};
    expect(label('nav-aid-label', buoy, zoom: 13), '"2"');
    expect(label('nav-aid-label', buoy, zoom: 15), buoy['name']);
    expect(
      label('nav-aid-label', {
        'name': 'San Juan Harbor Anchorage E Buoy A',
      }, zoom: 13),
      '"A"',
    );
    expect(
      label('nav-aid-label', {'name': 'Isla Grande 16 South Light'}, zoom: 13),
      '',
      reason: 'no number to show; its light label still shows',
    );
  });

  test(
    'landmarks: lighthouses left to their light, conspicuous in capitals',
    () {
      const radioTower = {
        'class': 'LNDMRK',
        'category': 'tower',
        'function': 'radio',
        'conspicuous': 1,
      };
      expect(label('landmark-label', radioTower, zoom: 14), 'R TR');
      expect(label('landmark-label', radioTower, zoom: 13), '', reason: 'z14+');
      expect(
        matches('landmark-symbol', {
          'class': 'LNDMRK',
          'function': 'light_support',
        }),
        isFalse,
      );
      expect(
        matches('landmark-symbol', {
          'class': 'LNDMRK',
          'category': 'windmotor',
          'function': 'light_support',
        }),
        isTrue,
        reason: 'its light does not say it is a turbine',
      );
    },
  );

  String icon(String id, Map<String, Object?> p) =>
      (byId(id) as vt.SymbolThemeLayer).iconImage!.eval(feature(p));

  test('marks: shapes and colours as charted', () {
    const port = {'kind': 'beacon', 'shape': 'stake', 'side': 'port'};
    expect(icon('beacon', {...port, 'colour': 'green'}), 'day-square-green');
    expect(
      icon('beacon', {'kind': 'beacon', 'side': 'starboard', 'colour': 'red'}),
      'day-triangle-red',
    );
    // Preferred channel: the top band decides.
    expect(
      icon('beacon', {
        'kind': 'beacon',
        'category': 'lateral',
        'colour': 'red',
        'colours': 'red,green,red',
        'colour_pattern': 'horizontal_stripes',
      }),
      'day-triangle-rgr',
    );
    expect(
      icon('buoy', {
        'kind': 'buoy',
        'shape': 'pillar',
        'colour': 'red',
        'colours': 'red,white',
        'colour_pattern': 'vertical_stripes',
      }),
      'buoy-pillar-rwv',
    );
    // A combination the sheet lacks falls back to the first colour.
    expect(
      icon('buoy', {
        'kind': 'buoy',
        'shape': 'super-buoy',
        'colour': 'white',
        'colours': 'white,red,white,red,red',
        'colour_pattern': 'border_stripe',
      }),
      'buoy-pillar-white',
    );
  });

  test('hazards and areas: the INT-1 symbol for what it is', () {
    expect(icon('hazard-symbol', {'kind': 'rock'}), 'hazard-rock');
    expect(
      icon('hazard-symbol', {'kind': 'rock', 'water_level': 'awash'}),
      'hazard-rock-awash',
    );
    expect(
      icon('hazard-symbol', {'kind': 'wreck', 'dangerous': 1}),
      'hazard-wreck-dangerous',
    );
    expect(
      icon('hazard-symbol', {'kind': 'wreck', 'category': 'hull_showing'}),
      'hazard-wreck-hull',
    );
    const area = {'anchor': 1};
    expect(icon('regulated-symbol', {...area, 'class': 'ACHARE'}), 'anchor');
    // An anchorage charted as a point (Prisoners Harbor, Santa Cruz Island).
    const point = {'class': 'ACHARE', 'status': 'recommended'};
    expect(matches('regulated-symbol', point), isTrue);
    expect(icon('regulated-symbol', point), 'anchor');
    expect(
      icon('regulated-symbol', {
        ...area,
        'class': 'CBLARE',
        'restriction': 'anchoring',
      }),
      'no-anchoring',
    );
    expect(
      matches('regulated-symbol', {...area, 'class': 'DMPGRD'}),
      isFalse,
      reason: 'no symbol, so the label stays centred',
    );
    const entry = {'class': 'RESARE', 'restriction': 'entry'};
    expect(matches('restricted-limit', entry, type: 'Polygon'), isTrue);
    expect(matches('regulated-limit', entry, type: 'Polygon'), isFalse);
    // Firing and practice areas: a dashed limit, as S-52 draws them.
    const firing = {'class': 'MIPARE', 'category': 'firing_danger_area'};
    expect(matches('regulated-limit', firing, type: 'Polygon'), isTrue);
    expect(matches('restricted-limit', firing, type: 'Polygon'), isFalse);
  });

  test('area limits: lines where the pack has them, outlines otherwise', () {
    const entry = {'class': 'RESARE', 'restriction': 'entry'};
    expect(matches('restricted-limit', entry, type: 'Polygon'), isTrue);
    expect(
      matches('restricted-limit', {
        ...entry,
        'limit_lines': 1,
      }, type: 'Polygon'),
      isFalse,
      reason: 'its limit comes from area_limit, without the shore',
    );
    bool line(String id, Map<String, Object?> p) =>
        matches(id, p, type: 'LineString');
    const regulated = {'layer': 'regulated_area'};
    expect(line('restricted-limit-line', {...regulated, ...entry}), isTrue);
    expect(line('regulated-limit-line', {...regulated, ...entry}), isFalse);
    expect(
      line('regulated-limit-line', {...regulated, 'class': 'CTNARE'}),
      isTrue,
    );
    expect(
      line('precautionary-line', {'layer': 'route', 'class': 'PRCARE'}),
      isTrue,
    );
    expect(
      matches('precautionary', {
        'class': 'PRCARE',
        'limit_lines': 1,
      }, type: 'Polygon'),
      isFalse,
    );
    // Hazard areas have no class: the line says which layer it bounds.
    expect(
      line('hazard-area-line', {'layer': 'hazard', 'category': 'foul_area'}),
      isTrue,
    );
    expect(
      line('hazard-area-line', {...regulated, 'class': 'CTNARE'}),
      isFalse,
    );
  });

  test('area anchors label areas; point symbols skip them', () {
    expect(
      matches('dolphin', {
        'class': 'MORFAC',
        'category': 'dolphin',
        'anchor': 1,
      }),
      isFalse,
    );
    expect(
      matches('dolphin', {'class': 'MORFAC', 'category': 'dolphin'}),
      isTrue,
    );
    expect(
      matches('seabed-label', {
        'class': 'SBDARE',
        'label': 'R',
        'nature': 'rock',
      }, type: 'Polygon'),
      isFalse,
    );
    expect(
      matches('seabed-label', {
        'class': 'SBDARE',
        'label': 'h',
        'nature_quality': 'hard',
      }),
      isFalse,
      reason: 'a quality alone reads like a typo',
    );
    expect(
      matches('virtual-aid', {'class': 'NEWOBJ', 'virtual': 1, 'anchor': 1}),
      isFalse,
    );
  });
}
