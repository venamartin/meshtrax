import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:traxmap/latlong2.dart';
import 'package:traxmap/traxmap.dart' hide LatLng, LatLngBounds;

import '../screens/map_screen.dart';
import '../utils/platform_info.dart';
import 'app_map.dart';

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
    // Web has no map packs service, so no map.
    if (PlatformInfo.isWeb) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ExcludeSemantics(
              child: IgnorePointer(
                child: AppMap(
                  compact: true,
                  initialCamera: MapCamera(center: position.toOvm(), zoom: 13),
                  overlays: [
                    MapMarker(
                      id: 'pin',
                      position: position.toOvm(),
                      size: const Size(40, 40),
                      anchor: Alignment.bottomCenter,
                      interactive: false,
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
