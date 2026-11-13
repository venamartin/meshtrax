import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:traxroute/traxroute.dart';

import '../helpers/geo_format.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import 'elevation_profile.dart';
import 'route_options.dart';

/// The colour a route is drawn in on the map and in its profile.
Color routeColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFFF8A50)
    : const Color(0xFFD84315);

/// The colour of a route's start, on the map and in its sheet.
const routeStartColor = Color(0xFF2E7D32);

IconData pathTypeIcon(PathType type) => switch (type) {
  PathType.paved => Symbols.road,
  PathType.dirt => Symbols.unpaved_road,
  PathType.hiking => Symbols.hiking,
};

String pathTypeLabel(BuildContext context, PathType type) => switch (type) {
  PathType.paved => context.l10n.route_pathPaved,
  PathType.dirt => context.l10n.route_pathDirt,
  PathType.hiking => context.l10n.route_pathHiking,
};

String routeDuration(BuildContext context, double seconds) {
  final minutes = (seconds / 60).round();
  if (minutes < 60) return context.l10n.route_minutes(minutes);
  return context.l10n.route_hoursMinutes(minutes ~/ 60, minutes % 60);
}

/// The route to [destination], in a sheet over the bottom of the map that
/// slides between three heights: a bar (where to, the distance, time and
/// climb), open (adds the height profile, the path type and its options) and
/// the whole map (adds the start and the directions). On a wide screen it is
/// a panel at the [side] of the map instead.
class RouteSheet extends StatefulWidget {
  final String destination;

  /// A start picked on the map; null starts from your position.
  final String? start;
  final VoidCallback onUseMyPosition;
  final PathType pathType;
  final ValueChanged<PathType> onPathType;
  final RouteOptions options;
  final ValueChanged<RouteOptions> onOptions;
  final RouteResult? result;
  final bool loading;
  final String? error;
  final UnitSystem units;
  final VoidCallback onClose;

  /// Docked at the side of a wide screen: no handle, nothing to slide.
  final bool side;

  /// The system's strip along the bottom of a screen whose map has no bar
  /// under it: the sheet reaches the screen's edge there, and keeps what it
  /// shows above the strip.
  final double bottomInset;

  /// How wide the panel at the side of a wide screen is.
  static const sideWidth = 360.0;

  const RouteSheet({
    super.key,
    required this.destination,
    required this.start,
    required this.onUseMyPosition,
    required this.pathType,
    required this.onPathType,
    required this.options,
    required this.onOptions,
    required this.result,
    required this.loading,
    required this.error,
    required this.units,
    required this.onClose,
    this.side = false,
    this.bottomInset = 0,
  });

  @override
  State<RouteSheet> createState() => RouteSheetState();
}

/// Where the sheet stops below the whole map. It comes to [rest] for a new
/// destination: [open], or the [bar] on a screen too short for both the map
/// and the open sheet.
enum _Stop { rest, bar, open }

class RouteSheetState extends State<RouteSheet> {
  final _sheet = DraggableScrollableController();
  final _headerKey = GlobalKey();
  final _topKey = GlobalKey();
  ScrollController? _scroll;

  /// The height of the bar, and of the sheet open down to the Directions
  /// row: measured after each layout, as both follow the text size and what
  /// the route has.
  double _bar = 88, _open = 260;

  /// The height the sheet slides in: the map's, above
  /// [RouteSheet.bottomInset].
  double room = 0;

  /// Whether the sheet in the tree has its stops at [_bar] and [_open]: it
  /// can't go to a stop it wasn't built with.
  bool _stopsBuilt = false;
  List<double> _snaps = const [];
  bool _optionsOpen = false;

  /// Where the next layout takes the sheet, if anywhere.
  _Stop? _to = _Stop.rest;

  @override
  void didUpdateWidget(RouteSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.destination != widget.destination) _to = _Stop.rest;
  }

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  double get _low => (_bar / room).clamp(0.0, 1.0);
  double get _mid => (_open / room).clamp(_low, 1.0);

  double _sizeAt(_Stop stop) => switch (stop) {
    _Stop.bar => _low,
    _Stop.open => _mid,
    _Stop.rest => _mid > 0.6 ? _low : _mid,
  };

  /// The stop the sheet is at, if any.
  _Stop? get _stop {
    if (!_sheet.isAttached || room == 0) return null;
    if ((_sheet.size - _mid).abs() < 0.005) return _Stop.open;
    if ((_sheet.size - _low).abs() < 0.005) return _Stop.bar;
    return null;
  }

  bool get _raised =>
      _sheet.isAttached && room > 0 && _sheet.size > _mid + 0.02;

  double _heightOf(GlobalKey key) =>
      (key.currentContext?.findRenderObject() as RenderBox?)?.size.height ?? 0;

  void _measure() {
    if (!mounted) return;
    final bar = _heightOf(_headerKey);
    if (bar == 0) return;
    final open = bar + _heightOf(_topKey);
    if (bar != _bar || open != _open) {
      // A sheet at a stop that moves goes with it.
      final stop = _stop;
      setState(() {
        _bar = bar;
        _open = open;
        _to ??= stop;
        _stopsBuilt = false;
      });
    } else if (_stopsBuilt && _to != null && _sheet.isAttached && room > 0) {
      final size = _sizeAt(_to!);
      _to = null;
      _showTopBelow(size);
      _sheet.jumpTo(size);
    }
  }

  /// Only at its full height does the sheet stay scrolled.
  void _showTopBelow(double size) {
    if (size < 1 && (_scroll?.hasClients ?? false)) _scroll!.jumpTo(0);
  }

  void _slideTo(double size) {
    _showTopBelow(size);
    _sheet.animateTo(
      size,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  /// How much of the map the sheet covers at rest, for fitting a route above
  /// it: measured now, as a new route changes what the sheet holds.
  double restHeight() {
    _measure();
    final stop = _to ?? _stop;
    final height = !_sheet.isAttached
        ? _open
        : stop != null
        ? _sizeAt(stop) * room
        : math.min(_sheet.pixels, _open);
    return height + widget.bottomInset;
  }

  /// Brings a raised sheet back down; false when it wasn't raised.
  bool lower() {
    if (!_raised) return false;
    _slideTo(_mid);
    return true;
  }

  void _toggle() {
    if (!_sheet.isAttached || room == 0) return;
    if (!lower()) _slideTo(_sheet.size > _low + 0.02 ? _low : _mid);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.side) return _content(null);
    return Padding(
      padding: EdgeInsets.only(bottom: widget.bottomInset),
      child: LayoutBuilder(
        builder: (context, box) {
          if (box.maxHeight != room) {
            _to ??= _stop;
            room = box.maxHeight;
          }
          _stopsBuilt = true;
          WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
          final hasSteps = widget.result?.maneuvers.isNotEmpty ?? false;
          final low = _low, mid = _mid;
          final top = hasSteps ? 1.0 : mid;
          final snaps = [if (mid - low > 0.02 && top - mid > 0.02) mid];
          if (!listEquals(snaps, _snaps)) _snaps = snaps;
          return NotificationListener<DraggableScrollableNotification>(
            // Scaffold dims the map and shrinks its buttons under a tall bottom
            // sheet, and resets one that comes back down: not this sheet.
            onNotification: (_) => true,
            child: DraggableScrollableSheet(
              controller: _sheet,
              expand: false,
              shouldCloseOnMinExtent: false,
              snap: true,
              snapSizes: _snaps,
              minChildSize: low,
              initialChildSize: _sizeAt(_Stop.rest),
              maxChildSize: top,
              builder: (context, scroll) {
                _scroll = scroll;
                return ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  // A mouse drags the sheet as a finger does.
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(
                      context,
                    ).copyWith(dragDevices: PointerDeviceKind.values.toSet()),
                    child: _content(scroll),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _content(ScrollController? scroll) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final RouteSheet(
      :destination,
      :start,
      :pathType,
      :options,
      :result,
      :loading,
      :error,
      :units,
      :side,
    ) = widget;
    final r = result;
    final changed = !options.isDefaultFor(pathType);
    final hasSteps = r != null && r.maneuvers.isNotEmpty;

    // Its own surface: the rest scrolls under it.
    final header = Material(
      color: scheme.surfaceContainerLow,
      child: InkWell(
        onTap: side ? null : _toggle,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (side)
                const SizedBox(height: 8)
              else
                SizedBox(
                  height: 16,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.route_to(destination),
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    isSelected: _optionsOpen,
                    icon: Badge(
                      isLabelVisible: changed,
                      smallSize: 8,
                      child: const Icon(Icons.tune),
                    ),
                    tooltip: l10n.route_options,
                    onPressed: () => setState(() {
                      _optionsOpen = !_optionsOpen;
                      _to = _Stop.open;
                    }),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close),
                    tooltip: l10n.route_clear,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: loading
                    ? Text(
                        l10n.route_finding,
                        style: theme.textTheme.titleSmall,
                      )
                    : error != null || r == null
                    ? Text(
                        error ?? l10n.route_none,
                        style: theme.textTheme.bodyMedium,
                      )
                    : Row(
                        children: [
                          Icon(
                            pathTypeIcon(r.pathType),
                            size: 18,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              [
                                GeoFormat.distanceText(r.km * 1000, units),
                                routeDuration(context, r.seconds),
                                if (r.elevations.isNotEmpty)
                                  '↑ ${GeoFormat.heightText(r.climb.up, units)}',
                              ].join(' · '),
                              style: theme.textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 12, bottom: 6),
                child: SizedBox(
                  height: 2,
                  child: loading
                      ? const LinearProgressIndicator(minHeight: 2)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final top = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The last result stays, dimmed, while the next one is found, so
          // the sheet keeps its height.
          Opacity(
            opacity: loading ? 0.35 : 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Routing data built without heights (FINDINGS §1.5).
                if (r != null && r.elevations.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      r.pathType == PathType.hiking
                          ? l10n.route_noHeightsHiking
                          : l10n.route_noHeights,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                if (r != null && !r.reachesDestination) ...[
                  _EndsShort(result: r, destination: destination, units: units),
                  const SizedBox(height: 12),
                ],
                if (r != null && r.elevations.length > 1)
                  SizedBox(
                    height: 64,
                    child: ElevationProfile(
                      elevations: r.elevations,
                      units: units,
                      color: routeColor(context),
                    ),
                  )
                else if (loading && r == null)
                  const SizedBox(height: 64),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<PathType>(
            showSelectedIcon: false,
            segments: [
              for (final t in PathType.values)
                ButtonSegment(
                  value: t,
                  icon: Icon(pathTypeIcon(t)),
                  label: Text(pathTypeLabel(context, t)),
                ),
            ],
            selected: {pathType},
            onSelectionChanged: (s) => widget.onPathType(s.single),
          ),
          if (_optionsOpen) ...[
            RouteOptionsSection(
              pathType: pathType,
              options: options,
              onChanged: widget.onOptions,
            ),
            if (changed)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => widget.onOptions(options.resetFor(pathType)),
                  child: Text(l10n.route_optionsReset),
                ),
              ),
          ],
          // Raises the sheet over the whole map, and brings it back. At the
          // side the directions are listed under it.
          if (hasSteps || (loading && r == null))
            InkWell(
              onTap: side || !hasSteps
                  ? null
                  : () {
                      if (!lower()) _slideTo(1);
                    },
              child: Opacity(
                opacity: hasSteps ? 1 : 0.35,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.format_list_numbered,
                        size: 20,
                        color: scheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.route_directions,
                          style: theme.textTheme.labelLarge!.copyWith(
                            color: scheme.primary,
                          ),
                        ),
                      ),
                      if (!side)
                        ListenableBuilder(
                          listenable: _sheet,
                          builder: (context, _) => Icon(
                            _raised
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            )
          else
            const SizedBox(height: 12),
        ],
      ),
    );

    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        right: false,
        // The app bar changes colour over what scrolls, and keeps it once
        // the sheet is gone. This scrolls under its own header.
        child: NotificationListener<ViewportNotificationMixin>(
          onNotification: (_) => true,
          child: CustomScrollView(
            controller: scroll,
            slivers: [
              PinnedHeaderSliver(
                child: KeyedSubtree(key: _headerKey, child: header),
              ),
              SliverToBoxAdapter(
                child: KeyedSubtree(key: _topKey, child: top),
              ),
              if (hasSteps)
                SliverOpacity(
                  opacity: loading ? 0.35 : 1,
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: ListTile(
                          leading: const Icon(
                            Icons.circle,
                            size: 14,
                            color: routeStartColor,
                          ),
                          minLeadingWidth: 14,
                          title: Text(
                            start == null
                                ? l10n.route_fromYou
                                : l10n.route_from(start),
                          ),
                          trailing: start == null
                              ? null
                              : TextButton(
                                  onPressed: widget.onUseMyPosition,
                                  child: Text(l10n.route_useMyPosition),
                                ),
                        ),
                      ),
                      SliverList.builder(
                        itemCount: r.maneuvers.length,
                        itemBuilder: (context, i) {
                          final m = r.maneuvers[i];
                          return ListTile(
                            title: Text(m.instruction),
                            trailing: m.km > 0
                                ? Text(
                                    GeoFormat.distanceText(m.km * 1000, units),
                                  )
                                : null,
                          );
                        },
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 8)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EndsShort extends StatelessWidget {
  final RouteResult result;
  final String destination;
  final UnitSystem units;

  const _EndsShort({
    required this.result,
    required this.destination,
    required this.units,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final distance = GeoFormat.distanceText(
      result.kmShortOfDestination * 1000,
      units,
    );
    final text = switch (result.pathType) {
      PathType.paved => l10n.route_endsShortPaved(distance, destination),
      PathType.dirt => l10n.route_endsShortDirt(distance, destination),
      PathType.hiking => l10n.route_endsShortHiking(distance, destination),
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.flag_outlined, color: scheme.onTertiaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onTertiaryContainer),
            ),
          ),
        ],
      ),
    );
  }
}
