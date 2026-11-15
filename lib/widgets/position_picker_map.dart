import 'package:material_ui/material_ui.dart';
import 'package:traxmap/traxmap.dart';

import 'app_map.dart';

/// A small map for choosing a position: a tap places the pin. The caller
/// holds the position, so numbers typed beside the map move the pin too.
class PositionPickerMap extends StatefulWidget {
  final LatLng? position;
  final ValueChanged<LatLng> onPicked;
  final double height;

  /// Where to look while there is no position to show.
  final MapCamera? emptyCamera;

  const PositionPickerMap({
    super.key,
    required this.position,
    required this.onPicked,
    this.height = 200,
    this.emptyCamera,
  });

  @override
  State<PositionPickerMap> createState() => _PositionPickerMapState();
}

class _PositionPickerMapState extends State<PositionPickerMap> {
  final _controller = OfflineMapController();

  @override
  void didUpdateWidget(PositionPickerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final position = widget.position;
    if (position != null && position != oldWidget.position) {
      _controller.move(position);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = widget.position;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: widget.height,
        child: ExcludeSemantics(
          child: AppMap(
            compact: true,
            controller: _controller,
            initialCamera: position != null
                ? MapCamera(center: position, zoom: 13)
                : widget.emptyCamera ??
                      const MapCamera(center: LatLng(0, 0), zoom: 2),
            onTap: widget.onPicked,
            overlays: [
              if (position != null)
                MapMarker(
                  id: 'pin',
                  position: position,
                  size: const Size(40, 40),
                  anchor: Alignment.bottomCenter,
                  interactive: false,
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 36,
                    shadows: [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
