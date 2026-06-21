import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/screens/path_trace_map.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../services/map_tile_cache_service.dart';
import '../services/app_settings_service.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/channel_message.dart';
import '../models/app_settings.dart';
import '../models/contact.dart';
import '../models/resolved_hop.dart';
import '../helpers/path_helper.dart';
import '../helpers/path_resolver.dart';
import '../widgets/adaptive_app_bar_title.dart';

class ChannelMessagePathScreen extends StatelessWidget {
  final ChannelMessage message;
  final bool channelMessage;
  const ChannelMessagePathScreen({
    super.key,
    required this.message,
    this.channelMessage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final l10n = context.l10n;
        final primaryPathTmp = PathResolver.selectPrimaryPath(
          message.pathBytes,
          message.pathVariants,
        );

        final pathHashSize = message.pathHashSize;
        final primaryPath = !channelMessage && !message.isOutgoing
            ? Uint8List.fromList(PathHelper.getHops(primaryPathTmp, stride: pathHashSize).reversed.expand((h) => h).toList())
            : primaryPathTmp;
        
        final startLocation = (connector.selfLatitude != null && connector.selfLongitude != null)
            ? LatLng(connector.selfLatitude!, connector.selfLongitude!)
            : null;
        
        final hops = PathResolver.buildPathHops(
          primaryPath, 
          connector.allContacts, 
          startLocation: startLocation, 
          stride: pathHashSize,
        );
        final hasHopDetails = primaryPath.isNotEmpty;
        final observedLabel = _formatObservedHops(
          PathHelper.getHopCount(primaryPath, stride: pathHashSize),
          message.pathLength,
          l10n,
        );
        final extraPaths = PathResolver.otherPaths(primaryPath, message.pathVariants);
        return Scaffold(
          appBar: AppBar(
            title: AdaptiveAppBarTitle(l10n.channelPath_title),
            actions: [
              IconButton(
                icon: const Icon(Icons.radar_outlined),
                tooltip: l10n.channelPath_viewMap,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PathTraceMapScreen(
                      title: context.l10n.contacts_repeaterPathTrace,
                      path: primaryPath,
                      flipPathAround: true,
                      reversePathAround:
                          !(!channelMessage && !message.isOutgoing),
                      pathHashByteWidth: message.pathHashSize,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.map_outlined),
                tooltip: l10n.channelPath_viewMap,
                onPressed: hasHopDetails
                    ? () {
                        _openPathMap(context, channelMessage: channelMessage);
                      }
                    : null,
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(context, observedLabel: observedLabel),
                const SizedBox(height: 16),
                if (extraPaths.isNotEmpty) ...[
                  Text(
                    l10n.channelPath_otherObservedPaths,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _buildPathVariants(context, extraPaths),
                  const SizedBox(height: 16),
                ],
                Text(
                  l10n.channelPath_repeaterHops,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                if (!hasHopDetails)
                  Text(
                    l10n.channelPath_noHopDetails,
                    style: const TextStyle(color: Colors.grey),
                  )
                else
                  ..._buildHopTiles(context, hops),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context, {String? observedLabel}) {
    final l10n = context.l10n;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.channelPath_messageDetails,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _buildDetailRow(l10n.channelPath_senderLabel, message.senderName),
            _buildDetailRow(
              l10n.channelPath_timeLabel,
              _formatTime(message.timestamp, l10n),
            ),
            if (message.repeatCount > 0)
              _buildDetailRow(
                l10n.channelPath_repeatsLabel,
                message.repeatCount.toString(),
              ),
            _buildDetailRow(
              l10n.channelPath_pathLabelTitle,
              _formatPathLabel(
                message.pathLength,
                l10n,
              ),
            ),
            if (observedLabel != null)
              _buildDetailRow(l10n.channelPath_observedLabel, observedLabel),
          ],
        ),
      ),
    );
  }

  Widget _buildPathVariants(BuildContext context, List<Uint8List> variants) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < variants.length; i++)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              dense: true,
              title: Text(
                l10n.channelPath_observedPathTitle(
                  i + 1,
                  _formatHopCount(PathHelper.getHopCount(variants[i], stride: message.pathHashSize), l10n),
                ),
              ),
              subtitle: Text(message.displayPathVariants[i]),
              trailing: const Icon(Icons.map_outlined, size: 20),
              onTap: () => _openPathMap(
                context,
                initialPath: variants[i],
                channelMessage: channelMessage,
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildHopTiles(BuildContext context, List<ResolvedHop> hops) {
    final l10n = context.l10n;
    return [
      for (final hop in hops)
        Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 14,
              child: Text(
                hop.index.toString(),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            title: Text('(${hop.fullPrefixLabel}) ${_resolveName(hop.contact, l10n)}'),
            subtitle: Text(
              hop.hasLocation
                  ? '${hop.effectivePosition!.latitude.toStringAsFixed(5)}, '
                        '${hop.effectivePosition!.longitude.toStringAsFixed(5)}'
                  : l10n.channelPath_noLocationData,
            ),
          ),
        ),
    ];
  }

  String _formatTime(DateTime time, AppLocalizations l10n) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) {
      final timeLabel =
          '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
      return l10n.channelPath_timeWithDate(time.day, time.month, timeLabel);
    }
    return l10n.channelPath_timeOnly(
      '${time.hour}:${time.minute.toString().padLeft(2, '0')}',
    );
  }

  String _formatPathLabel(int? pathLength, AppLocalizations l10n) {
    if (pathLength == null) return l10n.channelPath_unknownPath;
    if (pathLength < 0) return l10n.channelPath_floodPath;
    if (pathLength == 0) return l10n.channelPath_directPath;
    return l10n.chat_hopsCount(pathLength);
  }

  String? _formatObservedHops(
    int observedCount,
    int? pathLength,
    AppLocalizations l10n,
  ) {
    if (observedCount <= 0 && (pathLength == null || pathLength <= 0)) {
      return null;
    }
    if (pathLength == null || pathLength < 0) {
      return observedCount > 0 ? l10n.chat_hopsCount(observedCount) : null;
    }
    if (observedCount == 0) {
      return l10n.channelPath_observedZeroOf(pathLength);
    }
    if (observedCount == pathLength) {
      return l10n.chat_hopsCount(observedCount);
    }
    return l10n.channelPath_observedSomeOf(observedCount, pathLength);
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _openPathMap(
    BuildContext context, {
    Uint8List? initialPath,
    bool channelMessage = false,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelMessagePathMapScreen(
          message: message,
          initialPath: initialPath,
          channelMessage: channelMessage,
        ),
      ),
    );
  }
}

class ChannelMessagePathMapScreen extends StatefulWidget {
  final ChannelMessage message;
  final Uint8List? initialPath;
  final bool channelMessage;

  const ChannelMessagePathMapScreen({
    super.key,
    required this.message,
    this.initialPath,
    this.channelMessage = false,
  });

  @override
  State<ChannelMessagePathMapScreen> createState() =>
      _ChannelMessagePathMapScreenState();
}

class _ChannelMessagePathMapScreenState
    extends State<ChannelMessagePathMapScreen> {
  static const double _labelZoomThreshold = 8.5;

  final MapController _mapController = MapController();
  Uint8List? _selectedPath;
  double _pathDistance = 0.0;
  bool _showNodeLabels = true;
  bool _didReceivePositionUpdate = false;
  int? _focusedHopIndex;

  @override
  void initState() {
    super.initState();
    _selectedPath = widget.initialPath;
  }

  @override
  void didUpdateWidget(ChannelMessagePathMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message ||
        !PathResolver.pathsEqual(
          oldWidget.initialPath ?? Uint8List(0),
          widget.initialPath ?? Uint8List(0),
        )) {
      _selectedPath = widget.initialPath;
    }
  }

  double _getPathDistance(List<LatLng> points) {
    double totalDistance = 0.0;
    final distanceCalculator = Distance();

    for (int i = 0; i < points.length - 1; i++) {
      totalDistance += distanceCalculator(points[i], points[i + 1]);
    }

    return totalDistance;
  }

  void _focusHop(ResolvedHop hop) {
    if (!hop.hasLocation) return;
    final targetZoom = _didReceivePositionUpdate
        ? max(_mapController.camera.zoom, 10.0)
        : 12.0;
    _mapController.move(hop.effectivePosition!, targetZoom);
  }

  void _onHopTapped(ResolvedHop hop) {
    _focusHop(hop);
    if (!mounted) return;
    setState(() {
      _focusedHopIndex = hop.index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final settings = context.watch<AppSettingsService>().settings;
        final isImperial = settings.unitSystem == UnitSystem.imperial;
        final tileCache = context.read<MapTileCacheService>();
        final primaryPath = PathResolver.selectPrimaryPath(
          widget.message.pathBytes,
          widget.message.pathVariants,
        );
        final observedPaths = PathResolver.buildObservedPaths(
          primaryPath,
          widget.message.pathVariants,
        );
        final selectedPathTmp = PathResolver.resolveSelectedPath(
          _selectedPath,
          observedPaths,
          primaryPath,
        );

        final selectedPath =
            ((!widget.message.isOutgoing && !widget.channelMessage) ||
                (widget.message.isOutgoing && widget.channelMessage))
            ? Uint8List.fromList(PathHelper.getHops(selectedPathTmp, stride: widget.message.pathHashSize).reversed.expand((h) => h).toList())
            : selectedPathTmp;

        final selectedIndex = PathResolver.indexForPath(selectedPath, observedPaths);
        final startLocation = (connector.selfLatitude != null && connector.selfLongitude != null)
            ? LatLng(connector.selfLatitude!, connector.selfLongitude!)
            : null;
        final hops = PathResolver.buildPathHops(
          selectedPath, 
          connector.allContacts, 
          startLocation: startLocation, 
          stride: widget.message.pathHashSize,
        );

        final points = <LatLng>[];

        if ((widget.message.isOutgoing && !widget.channelMessage) ||
            (widget.message.isOutgoing && widget.channelMessage)) {
          points.add(LatLng(connector.selfLatitude!, connector.selfLongitude!));
        }

        for (final hop in hops) {
          if (hop.hasLocation) {
            points.add(hop.effectivePosition!);
          }
        }

        if ((!widget.message.isOutgoing && !widget.channelMessage) ||
            (!widget.message.isOutgoing && widget.channelMessage)) {
          points.add(LatLng(connector.selfLatitude!, connector.selfLongitude!));
        }

        final polylines = points.length > 1
            ? [
                Polyline(
                  points: points,
                  strokeWidth: 4,
                  color: Colors.blueAccent,
                ),
              ]
            : <Polyline>[];

        final initialCenter = points.isNotEmpty
            ? points.first
            : const LatLng(0, 0);
        final initialZoom = points.isNotEmpty ? 13.0 : 2.0;
        if (!_didReceivePositionUpdate) {
          _showNodeLabels = initialZoom >= _labelZoomThreshold;
        }
        final bounds = points.length > 1
            ? LatLngBounds.fromPoints(points)
            : null;
        final mapKey = ValueKey(
          '${PathHelper.formatPathHex(selectedPath, stride: widget.message.pathHashSize)},${context.l10n.pathTrace_you}',
        );
        _pathDistance = _getPathDistance(points);

        return Scaffold(
          appBar: AppBar(
            title: AdaptiveAppBarTitle(context.l10n.channelPath_mapTitle),
          ),
          body: SafeArea(
            top: false,
            child: Stack(
              children: [
                FlutterMap(
                  key: mapKey,
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: initialCenter,
                    initialZoom: initialZoom,
                    initialCameraFit: bounds == null
                        ? null
                        : CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(64),
                            maxZoom: 16,
                          ),
                    minZoom: 2.0,
                    maxZoom: 18.0,
                    interactionOptions: InteractionOptions(
                      flags: ~InteractiveFlag.rotate,
                    ),
                    onPositionChanged: (camera, hasGesture) {
                      final shouldShow = camera.zoom >= _labelZoomThreshold;
                      if (!_didReceivePositionUpdate ||
                          shouldShow != _showNodeLabels) {
                        if (!mounted) return;
                        setState(() {
                          _didReceivePositionUpdate = true;
                          _showNodeLabels = shouldShow;
                        });
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: kMapTileUrlTemplate,
                      tileProvider: tileCache.tileProvider,
                      userAgentPackageName:
                          MapTileCacheService.userAgentPackageName,
                      maxZoom: 19,
                    ),
                    if (polylines.isNotEmpty)
                      PolylineLayer(polylines: polylines),
                    MarkerLayer(
                      markers: _buildHopMarkers(
                        hops,
                        showLabels: _showNodeLabels,
                      ),
                    ),
                  ],
                ),
                if (observedPaths.length > 1)
                  _buildPathSelector(context, observedPaths, selectedIndex, (
                    index,
                  ) {
                    setState(() {
                      _selectedPath = observedPaths[index].pathBytes;
                      _focusedHopIndex = null;
                    });
                  }),
                if (points.isEmpty)
                  Center(
                    child: Card(
                      color: Colors.white.withValues(alpha: 0.9),
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Text(
                          context.l10n.channelPath_noRepeaterLocations,
                        ),
                      ),
                    ),
                  ),
                _buildLegendCard(context, hops, isImperial),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPathSelector(
    BuildContext context,
    List<ObservedPath> paths,
    int selectedIndex,
    ValueChanged<int> onSelected,
  ) {
    final l10n = context.l10n;
    final selectedPath = paths[selectedIndex];
    final label = selectedPath.isPrimary
        ? l10n.channelPath_primaryPath(selectedIndex + 1)
        : l10n.channelPath_pathLabel(selectedIndex + 1);
    return Positioned(
      left: 16,
      right: 16,
      top: 16,
      child: SafeArea(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.channelPath_observedPathHeader,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: selectedIndex,
                    items: [
                      for (int i = 0; i < paths.length; i++)
                        DropdownMenuItem(
                          value: i,
                          child: Text(
                            '${paths[i].isPrimary ? l10n.channelPath_primaryPath(i + 1) : l10n.channelPath_pathLabel(i + 1)}'
                            ' • ${_formatHopCount(paths[i].getHopCount(widget.message.pathHashSize), l10n)}',
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      onSelected(value);
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.channelPath_selectedPathLabel(
                    label,
                    PathHelper.formatPathHex(selectedPath.pathBytes, stride: widget.message.pathHashSize),
                  ),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Marker> _buildHopMarkers(
    List<ResolvedHop> hops, {
    required bool showLabels,
  }) {
    final markers = <Marker>[];
    for (final hop in hops) {
      if (!hop.hasLocation) continue;
      final point = hop.effectivePosition!;
      markers.add(
        Marker(
          point: point,
          width: 35,
          height: 35,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              hop.index.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
      if (showLabels) {
        markers.add(
          _buildNodeLabelMarker(
            point: point,
            label: hop.contact?.name ?? hop.fullPrefixLabel,
          ),
        );
      }
    }

    final selfLat = context.read<MeshCoreConnector>().selfLatitude;
    final selfLon = context.read<MeshCoreConnector>().selfLongitude;
    if (selfLat != null && selfLon != null) {
      final selfPoint = LatLng(selfLat, selfLon);
      markers.add(
        Marker(
          point: selfPoint,
          width: 35,
          height: 35,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.teal,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              context.l10n.pathTrace_you,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
      );
      if (showLabels) {
        markers.add(
          _buildNodeLabelMarker(
            point: selfPoint,
            label: context.l10n.pathTrace_you,
          ),
        );
      }
    }

    return markers;
  }

  Marker _buildNodeLabelMarker({required LatLng point, required String label}) {
    return Marker(
      point: point,
      width: 120,
      height: 24,
      alignment: Alignment.topCenter,
      child: IgnorePointer(
        child: Transform.translate(
          offset: const Offset(0, -20),
          child: FittedBox(
            fit: BoxFit.contain,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendCard(
    BuildContext context,
    List<ResolvedHop> hops,
    bool isImperial,
  ) {
    final l10n = context.l10n;
    final maxHeight = MediaQuery.of(context).size.height * 0.35;
    final estimatedHeight = 72.0 + (hops.length * 56.0);
    final cardHeight = max(96.0, min(maxHeight, estimatedHeight));

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SizedBox(
        height: cardHeight,
        child: Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  '${l10n.channelPath_repeaterHops} ${formatDistance(_pathDistance, isImperial: isImperial)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: hops.isEmpty
                    ? Center(
                        child: Text(l10n.channelPath_noHopDetailsAvailable),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: hops.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final hop = hops[index];
                          final isFocused = _focusedHopIndex == hop.index;
                          return ListTile(
                            dense: true,
                            enabled: hop.hasLocation,
                            selected: isFocused,
                            selectedTileColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.12),
                            onTap: hop.hasLocation
                                ? () => _onHopTapped(hop)
                                : null,
                            leading: CircleAvatar(
                              radius: 14,
                              child: Text(
                                hop.index.toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            title: Text('(${hop.fullPrefixLabel}) ${_resolveName(hop.contact, l10n)}'),
                            subtitle: Text(
                              hop.hasLocation
                                  ? '${hop.effectivePosition!.latitude.toStringAsFixed(5)}, '
                                        '${hop.effectivePosition!.longitude.toStringAsFixed(5)}'
                                  : l10n.channelPath_noLocationData,
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatHopCount(int count, AppLocalizations l10n) {
  return l10n.chat_hopsCount(count);
}

String _resolveName(Contact? contact, AppLocalizations l10n) {
  if (contact == null) return l10n.channelPath_unknownRepeater;
  final name = contact.name.trim();
  if (name.isEmpty || name.toLowerCase() == 'unknown') {
    return l10n.channelPath_unknownRepeater;
  }
  return name;
}
