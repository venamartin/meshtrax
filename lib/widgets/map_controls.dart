import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traxmap/traxmap.dart';

import '../l10n/l10n.dart';
import 'speed_card.dart';

/// The map's buttons, bottom right: search, full screen, zoom (desktop only;
/// phones pinch), My location, and the layers button; bottom left, the TRAX
/// group, with the speed card above it. Search, full screen, My location,
/// the TRAX group and the speed card show only when the screen handles them.
class MapControls extends StatelessWidget {
  final OfflineMapController controller;
  final VoidCallback onLayers;

  final VoidCallback? onSearch;

  /// Full screen on or off; [fullScreen] says which way a tap goes.
  final VoidCallback? onFullScreen;
  final bool fullScreen;

  /// The buttons, all but full screen's own, faded to [fadedOpacity]: in
  /// full screen, while the map is left alone. The way out never fades.
  final bool faded;
  static const fadedOpacity = 0.4;

  /// A touch on the buttons, or a mouse over them: they wake up.
  final VoidCallback? onTouch;

  /// My location: the screen decides what a tap does (the radio's GPS).
  final VoidCallback? onMyLocation;

  /// The radio's GPS is off: My location shows it crossed out.
  final bool gpsOff;

  /// The map keeps you in the middle: My location shows filled.
  final bool following;

  /// The TRAX group's list, from a button at the map's bottom left.
  final VoidCallback? onTraxGroup;

  /// Your speed while the map follows you ([SpeedCard]), at the bottom left
  /// above the TRAX group. It doesn't fade: it is no button.
  final Widget? speedCard;

  /// Where the map starts, from the screen's left edge: a sheet at the side
  /// takes the room before it.
  final double mapLeft;

  /// The room the buttons take at the map's right edge
  /// ([AppMap.controlsWidth]), and the TRAX group's at its left
  /// ([AppMap.leftControlsWidth]).
  static const width = 80.0;

  /// The room the speed card takes at the map's left edge.
  static const speedWidth = kFloatingActionButtonMargin + SpeedCard.width + 8;

  /// How close My location zooms in, unless already closer.
  static const locateZoom = 14.0;

  /// Where a screen with a bottom sheet docks the buttons: above the sheet,
  /// not across its top edge, where they covered the route sheet's X.
  static const FloatingActionButtonLocation aboveSheet = _AboveSheet();

  const MapControls({
    super.key,
    required this.controller,
    required this.onLayers,
    this.onSearch,
    this.onFullScreen,
    this.fullScreen = false,
    this.faded = false,
    this.onTouch,
    this.onMyLocation,
    this.gpsOff = false,
    this.following = false,
    this.onTraxGroup,
    this.speedCard,
    this.mapLeft = 0,
  });

  /// Centres [controller] on [here], zoomed in to at least [locateZoom].
  static void centerOn(OfflineMapController controller, LatLng here) =>
      controller.move(
        here,
        zoom: math.max(controller.camera?.zoom ?? 0, locateZoom),
      );

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget fade(Widget button) => AnimatedOpacity(
      opacity: faded ? fadedOpacity : 1,
      duration: const Duration(milliseconds: 300),
      child: button,
    );
    final buttons = Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        if (onSearch != null)
          fade(
            FloatingActionButton.small(
              heroTag: null,
              tooltip: l10n.map_search,
              onPressed: onSearch,
              child: const Icon(Icons.search),
            ),
          ),
        if (onFullScreen != null)
          FloatingActionButton.small(
            heroTag: null,
            tooltip: fullScreen
                ? l10n.map_leaveFullScreen
                : l10n.map_fullScreen,
            onPressed: onFullScreen,
            child: Icon(fullScreen ? Icons.fullscreen_exit : Icons.fullscreen),
          ),
        if (_desktop)
          fade(
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
          ),
        if (onMyLocation != null)
          fade(
            FloatingActionButton.small(
              heroTag: null,
              tooltip: l10n.map_myLocation,
              onPressed: onMyLocation,
              backgroundColor: following ? scheme.primary : null,
              foregroundColor: following ? scheme.onPrimary : null,
              child: Icon(gpsOff ? Icons.location_disabled : Icons.my_location),
            ),
          ),
        fade(
          FloatingActionButton(
            onPressed: onLayers,
            tooltip: l10n.mapLayers_title,
            child: const Icon(Icons.layers_outlined),
          ),
        ),
      ],
    );
    // One row across the map's bottom, so the group button and the speed
    // card rise above a sheet with the others. Its empty middle lets taps
    // through to the map.
    final group = onTraxGroup;
    final speed = speedCard;
    final all = group == null && speed == null
        ? buttons
        : LayoutBuilder(
            builder: (context, constraints) {
              // The screen's own insets: the scaffold took them from this
              // button's MediaQuery.
              final insets = MediaQueryData.fromView(View.of(context)).padding;
              final left = math.max(mapLeft, insets.left);
              return SizedBox(
                width: math.max(
                  0,
                  constraints.maxWidth -
                      left -
                      insets.right -
                      2 * kFloatingActionButtonMargin,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        ?speed,
                        if (group != null)
                          fade(
                            FloatingActionButton(
                              heroTag: null,
                              tooltip: l10n.trax_group,
                              onPressed: group,
                              child: const Icon(Icons.groups, size: 32),
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    buttons,
                  ],
                ),
              );
            },
          );
    final touch = onTouch;
    if (touch == null) return all;
    return Listener(
      onPointerDown: (_) => touch(),
      onPointerHover: (_) => touch(),
      child: all,
    );
  }
}

/// [FloatingActionButtonLocation.endFloat], lifted clear of a bottom sheet.
class _AboveSheet extends FloatingActionButtonLocation {
  const _AboveSheet();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry geometry) {
    final offset = FloatingActionButtonLocation.endFloat.getOffset(geometry);
    final sheet = geometry.bottomSheetSize.height;
    if (sheet == 0) return offset;
    final above =
        geometry.contentBottom -
        sheet -
        geometry.floatingActionButtonSize.height -
        kFloatingActionButtonMargin;
    // No room above the sheet: off the screen, not over the sheet's buttons.
    if (above < geometry.contentTop) {
      return Offset(offset.dx, geometry.scaffoldSize.height);
    }
    return Offset(offset.dx, math.min(offset.dy, above));
  }
}
