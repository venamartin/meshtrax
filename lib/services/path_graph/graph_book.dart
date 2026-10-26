import 'dart:convert';

import 'package:path_graph/path_graph.dart';

import '../../storage/prefs_manager.dart';

/// One Pathfinder graph on this device, in a file of its own.
class GraphEntry {
  const GraphEntry({required this.id, required this.mesh, this.name});

  /// File-name safe: the preset's key for its default graph (the file every
  /// graph had before they had names), `<key>_g<n>` for one added later.
  final String id;
  final MeshId mesh;

  /// What the user called it; null for a default nobody renamed.
  final String? name;

  bool get isDefault => id == mesh.key;
  String get label => name ?? mesh.label;
  String get databaseName => 'path_graph_$id';

  Map<String, dynamic> toJson() => {
        'id': id,
        'mesh': mesh.toJson(),
        if (name != null) 'name': name,
      };

  static GraphEntry? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final mesh = MeshId.fromJson(raw['mesh']);
    final name = raw['name'];
    if (id is! String || mesh == null) return null;
    return GraphEntry(id: id, mesh: mesh, name: name is String ? name : null);
  }

  @override
  bool operator ==(Object other) => other is GraphEntry && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The graphs kept on this device, and which one each preset uses. Every
/// preset has its default graph; more can be added for another mesh on the
/// same preset (owner, 2026-10-26: "what happens if I go to Washington
/// state?"). Each graph's repeater keys are kept as well, so the "a
/// different mesh?" check can tell which graph knows the repeaters heard
/// without opening the others.
class GraphBook {
  GraphBook._();

  static const _graphsPref = 'path_graph_graphs';
  static const _activePref = 'path_graph_active';
  static const _keysPref = 'path_graph_keys_';
  static const _quietPref = 'path_graph_quiet';

  static Object? _read(String key) {
    final json = PrefsManager.instance.getString(key);
    if (json == null) return null;
    try {
      return jsonDecode(json);
    } catch (_) {
      return null;
    }
  }

  static Future<void> _write(String key, Object value) =>
      PrefsManager.instance.setString(key, jsonEncode(value));

  static List<GraphEntry> _all() => [
        if (_read(_graphsPref) case final List list)
          for (final raw in list) ?GraphEntry.fromJson(raw),
      ];

  static Future<void> _save(List<GraphEntry> all) =>
      _write(_graphsPref, [for (final g in all) g.toJson()]);

  static Map<String, dynamic> _map(String key) => switch (_read(key)) {
        final Map map => Map<String, dynamic>.from(map),
        _ => {},
      };

  /// The graphs for [mesh], its default first.
  static List<GraphEntry> graphsFor(MeshId mesh) {
    final mine = _all().where((g) => g.mesh == mesh).toList();
    final def = mine.where((g) => g.isDefault).firstOrNull ??
        GraphEntry(id: mesh.key, mesh: mesh);
    return [def, ...mine.where((g) => !g.isDefault)];
  }

  /// The graph [mesh] uses: the one last picked, else its default.
  static GraphEntry activeFor(MeshId mesh) {
    final id = _map(_activePref)[mesh.key];
    final graphs = graphsFor(mesh);
    return graphs.where((g) => g.id == id).firstOrNull ?? graphs.first;
  }

  static Future<void> setActive(GraphEntry entry) =>
      _write(_activePref, _map(_activePref)..[entry.mesh.key] = entry.id);

  /// A new, empty graph for [mesh] called [name].
  static Future<GraphEntry> add(MeshId mesh, String name) async {
    final taken = graphsFor(mesh).map((g) => g.id).toSet();
    var n = 2;
    while (taken.contains('${mesh.key}_g$n')) {
      n++;
    }
    final entry = GraphEntry(id: '${mesh.key}_g$n', mesh: mesh, name: name);
    await _save([..._all(), entry]);
    return entry;
  }

  static Future<GraphEntry> rename(GraphEntry entry, String name) async {
    final renamed = GraphEntry(id: entry.id, mesh: entry.mesh, name: name);
    await _save([
      for (final g in _all())
        if (g.id != entry.id) g,
      renamed,
    ]);
    return renamed;
  }

  static Future<void> remove(GraphEntry entry) async {
    await _save([
      for (final g in _all())
        if (g.id != entry.id) g,
    ]);
    await PrefsManager.instance.remove('$_keysPref${entry.id}');
    await _write(_quietPref, _map(_quietPref)..remove(entry.id));
  }

  /// Repeater keys are kept to their first 8 bytes: enough to tell them
  /// apart, a quarter of the room.
  static String keyPrefix(String pubkey) {
    final key = pubkey.toLowerCase();
    return key.length > 16 ? key.substring(0, 16) : key;
  }

  static Set<String> keysOf(GraphEntry entry) => {
        if (_read('$_keysPref${entry.id}') case final List keys)
          for (final key in keys)
            if (key is String) key,
      };

  static Future<void> saveKeys(GraphEntry entry, Iterable<String> keys) =>
      _write('$_keysPref${entry.id}', {for (final k in keys) keyPrefix(k)}.toList());

  /// "A different mesh?" was answered "keep this one" for [entry]: it is
  /// not asked again before [until].
  static Future<void> quiet(GraphEntry entry, DateTime until) => _write(
      _quietPref, _map(_quietPref)..[entry.id] = until.millisecondsSinceEpoch);

  static bool isQuiet(GraphEntry entry, DateTime now) {
    final until = _map(_quietPref)[entry.id];
    return until is int && now.millisecondsSinceEpoch < until;
  }
}
