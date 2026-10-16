import 'dart:convert';

import 'package:flutter/services.dart';

import 'style_info.dart';
import 'style_registry.dart';

/// The styles bundled with this package (`assets/styles/`), read from the
/// Flutter asset bundle.
class AssetStyleSource implements StyleSource {
  static const String _localDir = 'assets/styles/';
  static const String _packageDir = 'packages/traxmap/$_localDir';

  final AssetBundle bundle;
  Future<(String, List<String>)>? _manifest;

  AssetStyleSource({AssetBundle? bundle}) : bundle = bundle ?? rootBundle;

  @override
  Future<List<String>> ids() async => (await _load()).$2;

  @override
  Future<Map<String, Object?>> load(String id) async {
    final (dir, _) = await _load();
    return jsonDecode(await bundle.loadString('$dir$id.json'))
        as Map<String, Object?>;
  }

  /// Apps see package assets under `packages/<name>/`; the package's own
  /// tests see them at the bare path.
  Future<(String, List<String>)> _load() => _manifest ??= () async {
    final assets = (await AssetManifest.loadFromAssetBundle(bundle))
        .listAssets();
    final dir = assets.any((a) => a.startsWith(_packageDir))
        ? _packageDir
        : _localDir;
    final ids = [
      for (final a in assets)
        if (a.startsWith(dir) && a.endsWith('.json'))
          a.substring(dir.length, a.length - '.json'.length),
    ]..sort();
    return (dir, ids);
  }();
}

/// The style registry for the bundled styles.
StyleRegistry bundledStyles({AssetBundle? bundle}) =>
    StyleRegistry(AssetStyleSource(bundle: bundle));

extension StyleRegistryBrightness on StyleRegistry {
  /// The style for [type] matching the app's [brightness]; see
  /// [StyleRegistry.styleFor].
  Future<String?> styleForBrightness(
    MapType type,
    Brightness brightness, {
    String family = StyleFamily.standard,
  }) => styleFor(type, dark: brightness == Brightness.dark, family: family);
}
