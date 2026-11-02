import 'package:traxmap/traxmap.dart';

/// Map styles held in memory (`osm-light`, `osm-dark`, and the same for any
/// other [maps]): no asset bundle, so no fake-async hang in widget tests.
class MemoryStyles implements StyleSource {
  /// Map types with a style, each needing packs of the kind of that name.
  final List<String> maps;

  MemoryStyles({this.maps = const ['osm']});

  @override
  Future<List<String>> ids() async => [
    for (final map in maps) ...['$map-dark', '$map-light'],
  ];

  @override
  Future<Map<String, Object?>> load(String id) async {
    final map = id.substring(0, id.lastIndexOf('-'));
    return {
      'version': 8,
      'name': id,
      'metadata': {
        'ovm:map': map,
        'ovm:theme': id.endsWith('dark') ? 'dark' : 'light',
        'ovm:requires': [map],
        if (map == 'charts') 'ovm:disclaimer': 'Not for navigation',
      },
      'sources': {
        map: {'type': 'vector', 'url': 'pmtiles://{pack:$map}'},
      },
      'layers': [
        {'id': 'bg', 'type': 'background'},
      ],
    };
  }
}
