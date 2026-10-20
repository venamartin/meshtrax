import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../l10n/l10n.dart';
import '../services/map_packs_service.dart';
import '../services/ui_view_state_service.dart';
import '../widgets/app_map.dart';
import '../widgets/map_layers_sheet.dart';

/// The map without a radio, opened from the scanner: downloaded and online
/// maps and the layers sheet, but no nodes or radio actions. It opens where
/// the map was last left, else on the latest downloaded map.
class NoRadioMapScreen extends StatefulWidget {
  const NoRadioMapScreen({super.key});

  @override
  State<NoRadioMapScreen> createState() => _NoRadioMapScreenState();
}

class _NoRadioMapScreenState extends State<NoRadioMapScreen> {
  Timer? _saveCamera;

  @override
  void dispose() {
    _saveCamera?.cancel();
    super.dispose();
  }

  void _onCameraChanged(MapCamera camera) {
    _saveCamera?.cancel();
    _saveCamera = Timer(const Duration(seconds: 1), () {
      if (mounted) context.read<UiViewStateService>().setMapCamera(camera);
    });
  }

  @override
  Widget build(BuildContext context) {
    final last = context.read<UiViewStateService>().mapCamera;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.scanner_map), centerTitle: true),
      body: AppMap(
        initialCamera: last ?? const MapCamera(center: LatLng(20, 0), zoom: 1),
        initialFit: last == null
            ? context.read<MapPacksService>().latestMapFit
            : null,
        onCameraChanged: _onCameraChanged,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showMapLayersSheet(context),
        tooltip: context.l10n.mapLayers_title,
        child: const Icon(Icons.layers_outlined),
      ),
    );
  }
}
