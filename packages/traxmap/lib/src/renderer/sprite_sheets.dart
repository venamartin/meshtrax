import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart' as vt;

// Sheets are shared by every map and legend and kept for the app's
// lifetime, so a style switch reuses them and no layer is left holding a
// disposed image.
final _atlases = <String, Future<vt.SpriteAtlas?>>{};

/// The sprite sheet a style's `sprite` names, once [bundledSprites] has
/// replaced its placeholder (`asset:sprites/light`). Null for other URLs.
Future<vt.SpriteAtlas?> loadSpriteSheet(Object? base) {
  if (base is! String || !base.startsWith('asset:')) return Future.value();
  return _atlases[base] ??= _loadAtlas(base.substring('asset:'.length));
}

/// Apps see package assets under `packages/traxmap/`; the package's own
/// tests see them at the bare path. Without a sheet, maps draw no icons.
Future<vt.SpriteAtlas?> _loadAtlas(String path) async {
  for (final dir in ['packages/traxmap/assets/', 'assets/']) {
    try {
      final index = await rootBundle.loadString('$dir$path@2x.json');
      final bytes = await rootBundle.load('$dir$path@2x.png');
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      final frame = await codec.getNextFrame();
      codec.dispose();
      return vt.SpriteAtlas(
        image: frame.image,
        sprites: vt.SpriteAtlas.parseIndex(
          jsonDecode(index) as Map<String, Object?>,
        ),
        pixelRatio: 2,
        cacheKey: 'asset:$path',
      );
    } catch (_) {
      continue;
    }
  }
  return null;
}
