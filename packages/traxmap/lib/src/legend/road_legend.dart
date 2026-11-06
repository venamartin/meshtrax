import 'legend_symbol.dart';

/// The OSM styles' roads, trails, route shields and other lines, for a
/// legend: each is drawn from [samples], features as the style's layers
/// draw them, bottom first. The app supplies the words.
enum RoadLegendItem {
  freeway([
    LegendSample('road-casing', {'class': 'motorway'}),
    LegendSample('road', {'class': 'motorway'}),
  ]),
  majorRoad([
    LegendSample('road-casing', {'class': 'primary'}),
    LegendSample('road', {'class': 'primary'}),
  ]),
  road([
    LegendSample('road-casing', {'class': 'tertiary'}),
    LegendSample('road', {'class': 'tertiary'}),
  ]),
  track([
    LegendSample('track', {'class': 'track'}),
  ]),
  trail([
    LegendSample('trail-halo', {'class': 'path', 'subclass': 'path'}),
    LegendSample('trail', {'class': 'path', 'subclass': 'path'}),
  ]),
  interstate([
    LegendSample('road-shield', {
      'network': 'us-interstate',
      'route_1_network': 'US:I',
      'route_1_ref': '5',
    }, '5'),
  ]),
  usRoute([
    LegendSample('road-shield', {
      'network': 'us-highway',
      'route_1_network': 'US:US',
      'route_1_ref': '101',
    }, '101'),
  ]),
  stateRoute([
    LegendSample('road-shield', {
      'network': 'us-state',
      'route_1_network': 'US:CA',
      'route_1_ref': '1',
    }, '1'),
  ]),
  railway([
    LegendSample('rail', {'class': 'rail'}),
  ]),
  stream([
    LegendSample('waterway', {'class': 'stream'}),
  ]),
  contour([
    LegendSample('contour', {'idx': 1}),
  ]),
  park([
    LegendSample('park-outline', {'class': 'national_park'}),
  ]),
  wilderness([
    LegendSample('park-outline-minor', {'class': 'wilderness_area'}),
  ]),
  boundary([
    LegendSample('boundary', {'admin_level': 4}),
  ]);

  final List<LegendSample> samples;

  const RoadLegendItem(this.samples);
}
