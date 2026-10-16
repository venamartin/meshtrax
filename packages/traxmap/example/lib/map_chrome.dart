import 'package:flutter/material.dart';
import 'package:traxmap/traxmap.dart';

/// The chrome an app draws around `OfflineMapView`, from the
/// [MapStyleState] it reports. The package draws none of this itself; this
/// is the pattern MeshTrax copies (credits are required by the OSM licence,
/// and the disclaimer matters for chart styles).
class MapChrome extends StatelessWidget {
  final MapStyleState? state;
  final Widget map;

  const MapChrome({super.key, required this.state, required this.map});

  @override
  Widget build(BuildContext context) {
    final s = state;
    return Stack(
      children: [
        map,
        if (s?.disclaimer != null)
          Positioned(
            top: 8,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(child: _Disclaimer(s!.disclaimer!)),
            ),
          ),
        if (s != null && s.credits.isNotEmpty)
          Positioned(
            right: 4,
            bottom: 4,
            child: AttributionChip(credits: s.credits, dark: s.info.isDark),
          ),
      ],
    );
  }
}

class _Disclaimer extends StatelessWidget {
  final String text;

  const _Disclaimer(this.text);

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xE6B00020),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    ),
  );
}
