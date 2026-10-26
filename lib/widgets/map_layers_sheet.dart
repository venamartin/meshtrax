import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';

import '../l10n/l10n.dart';
import '../screens/offline_maps_screen.dart';
import '../services/app_settings_service.dart';
import '../services/map_packs_service.dart';
import 'app_map.dart';

/// Opens the map layers sheet, laid out like Google Maps': which map, its
/// details (contours, hill shading, dark, downloaded areas), any [extra]
/// section a screen adds (the Node Map's node types), [onMoreFilters], and
/// Offline maps.
///
/// Online, the map is the standard online look, so the other map types,
/// contours, hill shading and dark show "Offline only"; tapping one switches
/// to Offline and applies it.
///
/// [extra] builds inside the sheet, so it rebuilds as settings change.
/// [places]: the map draws Points of interest, so it offers their switch.
Future<void> showMapLayersSheet(
  BuildContext context, {
  WidgetBuilder? extra,
  VoidCallback? onMoreFilters,
  bool places = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => MapLayersSheet(
    extra: extra,
    onMoreFilters: onMoreFilters,
    places: places,
  ),
);

class MapLayersSheet extends StatelessWidget {
  final WidgetBuilder? extra;
  final VoidCallback? onMoreFilters;
  final bool places;

  const MapLayersSheet({
    super.key,
    this.extra,
    this.onMoreFilters,
    this.places = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maps = context.watch<MapPacksService>();
    final settingsService = context.watch<AppSettingsService>();
    final settings = settingsService.settings;
    final online = mapIsOnline(settings, maps);
    final current = online
        ? MapType.osm
        : MapType.parse(settings.mapType) ?? MapType.osm;
    final dark = settings.mapTheme == 'dark';
    final contours = settings.mapContours;
    final hillShading = settings.mapHillShading;
    final downloadedAreas = settings.mapDownloadedAreas;

    // An Offline-only choice made while Online: go Offline, then apply it.
    void offline(Future<void> Function() apply) {
      if (online) settingsService.setMapSource('offline');
      apply();
    }

    void openOfflineMaps({OfflineMapsTab? tab}) => Navigator.of(context)
      ..pop()
      ..push(
        MaterialPageRoute<void>(
          builder: (_) => OfflineMapsScreen(initialTab: tab),
        ),
      );

    Widget mapTile(MapType type, String picture, String label) {
      final available = maps.hasMap(type);
      final offlineOnly = online && type != MapType.osm;
      return MapLayerTile(
        picture: _picture(picture),
        label: label,
        note: !available
            ? l10n.mapLayers_notDownloaded
            : offlineOnly
            ? l10n.mapLayers_offlineOnly
            : null,
        selected: available && type == current,
        enabled: available && !offlineOnly,
        onTap: !available
            ? () => openOfflineMaps(
                tab: type == MapType.charts ? OfflineMapsTab.charts : null,
              )
            : offlineOnly
            ? () => offline(() => settingsService.setMapType(type.name))
            : () => settingsService.setMapType(type.name),
      );
    }

    final badge = maps.badgeCount;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MapLayerSection(
              title: l10n.mapLayers_mapType,
              trailing: IconButton(
                icon: const Icon(Icons.close),
                tooltip: l10n.common_close,
                onPressed: () => Navigator.pop(context),
              ),
              children: [
                mapTile(MapType.osm, 'standard', l10n.mapLayers_standard),
                mapTile(MapType.usgs, 'usgs', l10n.mapLayers_usgs),
                mapTile(MapType.charts, 'charts', l10n.mapLayers_charts),
              ],
            ),
            const Divider(height: 24),
            MapLayerSection(
              title: l10n.mapLayers_details,
              children: [
                MapLayerTile(
                  picture: _picture('contours'),
                  label: l10n.mapLayers_contours,
                  note: online ? l10n.mapLayers_offlineOnly : null,
                  selected: !online && contours,
                  enabled: !online,
                  onTap: () => offline(
                    () => settingsService.setMapContours(online || !contours),
                  ),
                ),
                MapLayerTile(
                  picture: _picture('hill_shading'),
                  label: l10n.mapLayers_hillShading,
                  note: online ? l10n.mapLayers_offlineOnly : null,
                  selected: !online && hillShading,
                  enabled: !online,
                  onTap: () => offline(
                    () => settingsService.setMapHillShading(
                      online || !hillShading,
                    ),
                  ),
                ),
                if (places)
                  MapLayerTile(
                    picture: _picture('places'),
                    label: l10n.mapLayers_places,
                    selected: settings.mapPlaces,
                    onTap: () =>
                        settingsService.setMapPlaces(!settings.mapPlaces),
                  ),
                MapLayerTile(
                  picture: _picture('dark'),
                  label: l10n.mapLayers_dark,
                  note: online ? l10n.mapLayers_offlineOnly : null,
                  selected: !online && dark,
                  enabled: !online,
                  onTap: () => offline(
                    () => settingsService.setMapTheme(
                      online || !dark ? 'dark' : 'light',
                    ),
                  ),
                ),
                MapLayerTile(
                  picture: const _DownloadedAreasPicture(),
                  label: l10n.mapLayers_downloadedAreas,
                  selected: downloadedAreas,
                  onTap: () =>
                      settingsService.setMapDownloadedAreas(!downloadedAreas),
                ),
              ],
            ),
            if (extra case final extra?) ...[
              const Divider(height: 24),
              extra(context),
            ],
            const Divider(height: 24),
            if (onMoreFilters case final onMoreFilters?)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.filter_list),
                title: Text(l10n.mapLayers_moreFilters),
                subtitle: Text(l10n.mapLayers_moreFiltersDetail),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  onMoreFilters();
                },
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.download_for_offline_outlined),
              title: Text(l10n.offlineMaps_title),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (badge > 0) Badge(label: Text('$badge')),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => openOfflineMaps(),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _picture(String name) =>
      Image.asset('assets/map_layers/$name.webp', fit: BoxFit.cover);
}

/// The standard map's thumbnail with a downloaded area outlined on it, the
/// way [AppMap] draws one Online.
class _DownloadedAreasPicture extends StatelessWidget {
  const _DownloadedAreasPicture();

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      MapLayersSheet._picture('standard'),
      const CustomPaint(painter: _AreaPainter()),
    ],
  );
}

class _AreaPainter extends CustomPainter {
  const _AreaPainter();

  static const _shape = [
    (0.22, 0.14),
    (0.58, 0.14),
    (0.58, 0.46),
    (0.86, 0.74),
    (0.80, 0.88),
    (0.56, 0.88),
    (0.30, 0.62),
    (0.16, 0.34),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addPolygon([
        for (final (x, y) in _shape) Offset(x * size.width, y * size.height),
      ], true);
    canvas
      ..drawPath(path, Paint()..color = AppMap.areaFill)
      ..drawPath(
        path,
        Paint()
          ..color = AppMap.areaColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_AreaPainter oldDelegate) => false;
}

/// A titled row of [MapLayerTile]s.
class MapLayerSection extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final List<Widget> children;

  const MapLayerSection({
    super.key,
    required this.title,
    this.trailing,
    required this.children,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          ?trailing,
        ],
      ),
      const SizedBox(height: 8),
      Wrap(spacing: 4, runSpacing: 8, children: children),
    ],
  );
}

/// A square picture with a caption, outlined when [selected]: one map type
/// or one layer that toggles.
class MapLayerTile extends StatelessWidget {
  final Widget picture;
  final String label;
  final bool selected;
  final bool enabled;

  /// A second, smaller caption line, e.g. "Not downloaded".
  final String? note;
  final VoidCallback onTap;

  const MapLayerTile({
    super.key,
    required this.picture,
    required this.label,
    required this.selected,
    this.enabled = true,
    this.note,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 84,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selected ? scheme.primary : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: enabled
                        ? picture
                        : Opacity(opacity: 0.4, child: picture),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? scheme.primary : null,
                  ),
                ),
                if (note case final note?)
                  Text(
                    note,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.outline,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
