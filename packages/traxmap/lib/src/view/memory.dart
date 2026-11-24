import 'package:flutter/painting.dart';
import 'package:flutter_map_vector_tiles/flutter_map_vector_tiles.dart';

/// Frees the decoded map tiles, shaped labels and cached images held in
/// memory. Maps on screen keep what they show; the rest is read again from
/// disk when needed.
void releaseMapMemory() {
  VectorTileLayer.clearMemoryCache();
  PaintingBinding.instance.imageCache
    ..clear()
    ..clearLiveImages();
}
