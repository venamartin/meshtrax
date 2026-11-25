import 'dart:io';

import 'package:traxwater/traxwater.dart';

/// Times a trip over a folder of WRM2 tiles, three times:
///
///     dart compile exe tool/bench.dart -o build/bench
///     build/bench <tiles> <from lon,lat> <to lon,lat> [nm off land]
void main(List<String> args) {
  LatLon at(String s) {
    final [lon, lat] = s.split(',').map(double.parse).toList();
    return (lat: lat, lon: lon);
  }

  final from = at(args[1]), to = at(args[2]);
  final options = WaterRouteOptions(
    offLandNm: args.length > 3 ? double.parse(args[3]) : 1,
  );
  for (var run = 1; run <= 3; run++) {
    final read = Stopwatch();
    final trip = routeOnWater(from, to, (ix, iy) {
      final f = File('${args[0]}/${tileName(ix, iy)}');
      if (!f.existsSync()) return null;
      read.start();
      final tile = WaterTile.parse(f.readAsBytesSync());
      read.stop();
      return tile;
    }, options: options);
    final s = trip.stats;
    print(
      'run $run: ${(trip.distanceM / 1852).toStringAsFixed(2)} nm, '
      '${trip.legs.length} legs, ${trip.endsShort?.reason.name ?? 'reaches'}; '
      '${s.tiles} tiles, ${s.triangles} triangles, ${s.expanded} expanded; '
      'read ${read.elapsedMilliseconds} ms, load ${s.loadMs} ms, '
      'search ${s.searchMs} ms, straighten ${s.straightenMs} ms, '
      'total ${s.totalMs} ms',
    );
  }
}
