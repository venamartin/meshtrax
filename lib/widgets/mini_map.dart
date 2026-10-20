import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../screens/map_screen.dart';
import '../services/map_tile_cache_service.dart';

/// A small, non-interactive map with one pin, for cards in chat. Tapping it
/// opens the full map centred on the pin.
class MiniMap extends StatelessWidget {
  final LatLng position;
  final String? label;
  final Color markerColor;
  final double height;

  const MiniMap({
    super.key,
    required this.position,
    this.label,
    this.markerColor = Colors.blue,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: position,
                    initialZoom: 14,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: kMapTileUrlTemplate,
                      userAgentPackageName:
                          MapTileCacheService.userAgentPackageName,
                      tileProvider:
                          context.read<MapTileCacheService>().tileProvider,
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: position,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: Icon(
                            Icons.location_on,
                            color: markerColor,
                            size: 36,
                            shadows: const [
                              Shadow(color: Colors.black45, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MapScreen(
                      highlightPosition: position,
                      highlightLabel: label,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
