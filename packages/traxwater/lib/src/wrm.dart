import 'dart:convert';
import 'dart:typed_data';

/// Tiles are the 0.25° cells of a global grid (Valhalla's level 2): tile
/// (ix, iy) spans longitude ix × 0.25 − 180 and latitude iy × 0.25 − 90,
/// each 0.25° more, and is named `<iy>_<ix>.wrm`.
const tileDeg = 0.25;
const tileColumns = 1440;
const tileRows = 720;

/// Coordinates are int32 in 1e-7°, so a tile is this many units across.
const tileUnits = 2500000;

/// Where rings 1 to 6 start, in nm off land: ring 0 is under 0.25 nm from
/// land, ring 6 over 5 nm.
const ringsNm = [0.25, 0.5, 1.0, 2.0, 3.0, 5.0];

// The attribute flags the router reads, by bit.
const flagNoEntry = 1 << 0;
const flagKelp = 1 << 7;
const flagTrafficLane = 1 << 8;
const flagSeparationZone = 1 << 9;
const flagSecurityZone = 1 << 15;

const _overheadClasses = {'BRIDGE', 'CBLOHD', 'PIPOHD', 'CONVYR', 'GATCON'};
const _openingKinds = {
  'opening',
  'swing',
  'lift',
  'bascule',
  'pontoon',
  'draw',
  'transporter',
};

/// The name of tile (ix, iy) in a bundle.
String tileName(int ix, int iy) => '${iy}_$ix.wrm';

/// An area or overhead object a tile lists, with the chart's own text and
/// clearances. Its [id] is the same in every tile.
class WaterArea {
  WaterArea._(Map<String, Object?> j)
    : id = j['id'] as String,
      chartClass = j['class'] as String,
      name = j['name'] as String?,
      info = j['info'] as String?,
      restrictions = j['restrictions'] as String?,
      categories = j['categories'] as String?,
      clearanceSafeM = (j['clearance_safe_m'] as num?)?.toDouble(),
      clearanceM = (j['clearance_m'] as num?)?.toDouble(),
      clearanceClosedM = (j['clearance_closed_m'] as num?)?.toDouble(),
      clearanceOpenM = (j['clearance_open_m'] as num?)?.toDouble(),
      horizontalClearanceM = (j['horizontal_clearance_m'] as num?)?.toDouble();

  final String id;

  /// The S-57 class: RESARE (a restricted area), CTNARE (caution), ACHARE
  /// (anchorage), BRIDGE, CBLOHD (an overhead cable) and so on.
  final String chartClass;
  final String? name;
  final String? info;

  /// Comma-separated, as `entry_restricted`.
  final String? restrictions;

  /// Comma-separated, as `fixed` or `lift`.
  final String? categories;
  final double? clearanceSafeM;
  final double? clearanceM;
  final double? clearanceClosedM;
  final double? clearanceOpenM;
  final double? horizontalClearanceM;

  /// A bridge, overhead cable, pipe, conveyor or gate.
  bool get isOverhead => _overheadClasses.contains(chartClass);

  bool get isGate => chartClass == 'GATCON';

  /// A bridge that opens: a lift, swing, bascule and so on, or any with a
  /// closed or open clearance.
  bool get opens =>
      clearanceClosedM != null ||
      clearanceOpenM != null ||
      (categories?.split(',').any(_openingKinds.contains) ?? false);

  /// The first charted of the safe clearance (given under some power lines),
  /// the clearance and the closed clearance.
  double? get charted => clearanceSafeM ?? clearanceM ?? clearanceClosedM;
}

/// One WRM2 tile (FINDINGS 1.11): the triangles of the charted water in a
/// tile, each with one attribute row.
class WaterTile {
  WaterTile._(
    this.ix,
    this.iy,
    this.build,
    this.vertices,
    this.triangles,
    this.neighbours,
    this.rows,
    this.depth,
    this.flags,
    this.ring,
    this.zoc,
    this.hazardInner,
    this.hazardOuter,
    this.areaSet,
    this.areas,
    this.sets,
    this.buildInfo,
  );

  /// Reads a tile, checking every index in it. Throws a [FormatException]
  /// for anything that isn't a whole WRM2 tile.
  factory WaterTile.parse(Uint8List bytes) {
    const header = 42, rowBytes = 28, le = Endian.little;
    if (bytes.length < header || String.fromCharCodes(bytes, 0, 4) != 'WRM2') {
      throw const FormatException('not a WRM2 tile');
    }
    final b = ByteData.sublistView(bytes);
    final version = b.getUint16(4, le);
    if (version != 2) throw FormatException('WRM2 version $version');
    final ix = b.getInt32(6, le), iy = b.getInt32(10, le);
    if (ix < 0 || ix >= tileColumns || iy < 0 || iy >= tileRows) {
      throw FormatException('no tile ${iy}_$ix');
    }
    final nv = b.getUint32(14, le);
    final nt = b.getUint32(18, le);
    final na = b.getUint32(22, le);
    final id = bytes.sublist(26, header).takeWhile((c) => c != 0).toList();
    final build = ascii.decode(id);
    var o = header;
    if (o + nv * 8 + nt * 26 + na * rowBytes + 4 > bytes.length) {
      throw const FormatException('WRM2 tile cut short');
    }
    final vertices = Int32List(nv * 2);
    for (var i = 0; i < vertices.length; i++, o += 4) {
      vertices[i] = b.getInt32(o, le);
    }
    final triangles = Int32List(nt * 3);
    for (var i = 0; i < triangles.length; i++, o += 4) {
      final v = b.getUint32(o, le);
      if (v >= nv) throw const FormatException('WRM2: no such vertex');
      triangles[i] = v;
    }
    final neighbours = Int32List(nt * 3);
    for (var i = 0; i < neighbours.length; i++, o += 4) {
      final t = b.getInt32(o, le);
      if (t < -1 || t >= nt) {
        throw const FormatException('WRM2: no such triangle');
      }
      neighbours[i] = t;
    }
    final rows = Uint16List(nt);
    for (var i = 0; i < nt; i++, o += 2) {
      final r = b.getUint16(o, le);
      if (r >= na) throw const FormatException('WRM2: no such row');
      rows[i] = r;
    }
    final depth = Float32List(na), hazardInner = Float32List(na);
    final hazardOuter = Float32List(na);
    final flags = Uint16List(na), areaSet = Uint16List(na);
    final ring = Uint8List(na), zoc = Uint8List(na);
    for (var i = 0; i < na; i++, o += rowBytes) {
      depth[i] = b.getFloat32(o, le);
      flags[i] = b.getUint16(o + 4, le);
      ring[i] = b.getUint8(o + 8);
      zoc[i] = b.getUint8(o + 9);
      hazardInner[i] = b.getFloat32(o + 10, le);
      hazardOuter[i] = b.getFloat32(o + 14, le);
      areaSet[i] = b.getUint16(o + 26, le);
    }
    final size = b.getUint32(o, le);
    if (o + 4 + size != bytes.length) {
      throw const FormatException('WRM2: the areas JSON is not the end');
    }
    final meta =
        jsonDecode(utf8.decode(Uint8List.sublistView(bytes, o + 4)))
            as Map<String, Object?>;
    final areas = [
      for (final a in meta['areas'] as List)
        WaterArea._(a as Map<String, Object?>),
    ];
    final sets = [
      for (final s in meta['sets'] as List)
        [for (final i in s as List) i as int],
    ];
    if (sets.any((s) => s.any((i) => i < 0 || i >= areas.length)) ||
        areaSet.any((s) => s >= sets.length)) {
      throw const FormatException('WRM2: no such area');
    }
    return WaterTile._(
      ix,
      iy,
      build,
      vertices,
      triangles,
      neighbours,
      rows,
      depth,
      flags,
      ring,
      zoc,
      hazardInner,
      hazardOuter,
      areaSet,
      areas,
      sets,
      meta['build'] as Map<String, Object?>,
    );
  }

  final int ix;
  final int iy;

  /// The build's id (`YYYYMMDDNN`), the same in every tile of a build.
  final String build;

  /// Longitude, latitude pairs in 1e-7°.
  final Int32List vertices;

  /// Three vertex indices per triangle, counter-clockwise.
  final Int32List triangles;

  /// Three per triangle: the triangle across the edge from vertex k to
  /// vertex k + 1, or −1 for the coast, uncharted water or the tile's edge.
  final Int32List neighbours;

  /// Each triangle's attribute row.
  final Uint16List rows;

  // The attribute table, a list per field.

  /// DRVAL1, the least depth in metres; NaN for none.
  final Float32List depth;
  final Uint16List flags;

  /// The distance off land, as a ring of [ringsNm].
  final Uint8List ring;

  /// CATZOC, the survey's zone of confidence (1 A1 ... 6 unassessed); 0 for
  /// none.
  final Uint8List zoc;

  /// The least depth of a hazard within 15 m (−99: dries, awash or
  /// unknown); NaN for none.
  final Float32List hazardInner;

  /// The same within 100 m.
  final Float32List hazardOuter;

  /// Each row's set of [sets].
  final Uint16List areaSet;
  final List<WaterArea> areas;

  /// Indices into [areas].
  final List<List<int>> sets;

  /// The build, from the areas JSON: `build`, `cells_sha1`, `cells`,
  /// `extractors` and `extracted`.
  final Map<String, Object?> buildInfo;

  int get triangleCount => rows.length;
}
