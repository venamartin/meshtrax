import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../services/phone_location_service.dart';

/// The map's buttons, bottom right: zoom (desktop only; phones pinch), My
/// location, and the layers button. My location uses the phone's GPS where
/// the user allows it, else the radio's own position; it's hidden where
/// there's neither.
class MapControls extends StatelessWidget {
  final OfflineMapController controller;

  /// The radio's own position, when it reports one.
  final LatLng? radioPosition;
  final VoidCallback onLayers;

  /// The room the buttons take at the map's right edge
  /// ([AppMap.controlsWidth]).
  static const width = 80.0;

  /// How close My location zooms in, unless already closer.
  static const locateZoom = 14.0;

  const MapControls({
    super.key,
    required this.controller,
    required this.onLayers,
    this.radioPosition,
  });

  static bool get _desktop =>
      !kIsWeb &&
      switch (defaultTargetPlatform) {
        TargetPlatform.linux ||
        TargetPlatform.windows ||
        TargetPlatform.macOS => true,
        _ => false,
      };

  void _zoom(double by) {
    final camera = controller.camera;
    if (camera != null) controller.move(camera.center, zoom: camera.zoom + by);
  }

  Future<void> _locate(BuildContext context) async {
    final l10n = context.l10n;
    final phone = context.read<PhoneLocationService>();
    final here = await phone.locate() ?? radioPosition;
    if (!context.mounted) return;
    if (here != null) {
      controller.move(
        here,
        zoom: math.max(controller.camera?.zoom ?? 0, locateZoom),
      );
      return;
    }
    final denied = switch (phone.state) {
      PhoneLocationState.denied || PhoneLocationState.deniedForever => true,
      _ => false,
    };
    showDismissibleSnackBar(
      context,
      content: Text(
        denied
            ? l10n.map_locationDenied
            : phone.state == PhoneLocationState.serviceOff
            ? l10n.map_locationServiceOff
            : l10n.map_positionUnknown,
      ),
      action: denied
          ? SnackBarAction(
              label: l10n.common_settings,
              onPressed: () => unawaited(phone.openSettings()),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // Linux has no GPS: there My location needs the radio's position.
    final canLocate =
        radioPosition != null ||
        context.select<PhoneLocationService, bool>(
          (s) => s.state != PhoneLocationState.unsupported,
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        if (_desktop)
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: l10n.map_zoomIn,
                  onPressed: () => _zoom(1),
                  icon: const Icon(Icons.add),
                ),
                const SizedBox(width: 40, child: Divider(height: 1)),
                IconButton(
                  tooltip: l10n.map_zoomOut,
                  onPressed: () => _zoom(-1),
                  icon: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        if (canLocate)
          FloatingActionButton.small(
            heroTag: null,
            tooltip: l10n.map_myLocation,
            onPressed: () => unawaited(_locate(context)),
            child: const Icon(Icons.my_location),
          ),
        FloatingActionButton(
          onPressed: onLayers,
          tooltip: l10n.mapLayers_title,
          child: const Icon(Icons.layers_outlined),
        ),
      ],
    );
  }
}
