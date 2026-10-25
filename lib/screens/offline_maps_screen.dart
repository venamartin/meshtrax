import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/map_packs_service.dart';
import 'offline_maps/charts_tab.dart';
import 'offline_maps/downloaded_tab.dart';
import 'offline_maps/maps_tab.dart';

/// The Offline maps screen's tabs, in order.
enum OfflineMapsTab { maps, charts, downloaded }

/// Download and manage offline map packs: browse regions (Maps), pick NOAA
/// chart areas by coast (Charts) and see what's on the device (Downloaded).
/// Layout and wording follow docs/offline-maps-roadmap.md, screen S3.
class OfflineMapsScreen extends StatefulWidget {
  /// Opens the Maps tab on this region's detail (a picker `path`).
  final String? initialRegionPath;

  /// Opens on this tab.
  final OfflineMapsTab? initialTab;

  /// Opens the Charts tab with this chart area ticked (its pack region).
  final String? initialChartArea;

  const OfflineMapsScreen({
    super.key,
    this.initialRegionPath,
    this.initialTab,
    this.initialChartArea,
  });

  @override
  State<OfflineMapsScreen> createState() => _OfflineMapsScreenState();
}

class _OfflineMapsScreenState extends State<OfflineMapsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  /// The region whose children the Maps tab lists; null is the top level.
  String? _browsePath;

  /// The region whose detail is open.
  String? _selectedPath;

  /// Chart areas ticked for download, by pack region.
  late Set<String> _chartSelection;

  @override
  void initState() {
    super.initState();
    final maps = context.read<MapPacksService>();
    _selectedPath = widget.initialRegionPath;
    _browsePath = _selectedPath == null
        ? null
        : maps.regions?[_selectedPath!]?.parentPath;
    _chartSelection = {?widget.initialChartArea};
    final tab = widget.initialChartArea != null
        ? OfflineMapsTab.charts
        : widget.initialTab ??
              (_selectedPath == null &&
                      (maps.installed.isNotEmpty ||
                          maps.activeDownloadCount > 0)
                  ? OfflineMapsTab.downloaded
                  : OfflineMapsTab.maps);
    _tabs = TabController(
      length: OfflineMapsTab.values.length,
      vsync: this,
      initialIndex: tab.index,
    );
    // After the first frame: refreshing notifies listeners at once.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && maps.status != CatalogueStatus.loading) {
        unawaited(maps.refresh());
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _openRegion(String path) {
    final regions = context.read<MapPacksService>().regions;
    final region = regions?[path];
    setState(() {
      // A region since split (whole-Alaska packs once Alaska became 8
      // regions) has nothing to download itself: show what it holds.
      if (region != null && regions!.childrenOf(region).isNotEmpty) {
        _selectedPath = null;
        _browsePath = path;
      } else {
        _selectedPath = path;
        _browsePath = region?.parentPath;
      }
    });
    _tabs.animateTo(OfflineMapsTab.maps.index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final badge = context.select<MapPacksService, int>((m) => m.badgeCount);
    final loading = context.select<MapPacksService, bool>(
      (m) => m.status == CatalogueStatus.loading,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.offlineMaps_title),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.offlineMaps_refresh,
            onPressed: loading
                ? null
                : () => context.read<MapPacksService>().refresh(),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: l10n.offlineMaps_tabMaps),
            Tab(text: l10n.offlineMaps_tabCharts),
            Tab(
              child: Badge(
                isLabelVisible: badge > 0,
                label: Text('$badge'),
                child: Text(l10n.offlineMaps_tabDownloaded),
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          MapsTab(
            browsePath: _browsePath,
            selectedPath: _selectedPath,
            onBrowse: (path) => setState(() {
              _browsePath = path;
              _selectedPath = null;
            }),
            onSelect: (path) => setState(() => _selectedPath = path),
            onOpenCharts: () => _tabs.animateTo(OfflineMapsTab.charts.index),
          ),
          ChartsTab(
            openArea: widget.initialChartArea,
            selected: _chartSelection,
            onSelectionChanged: (s) => setState(() => _chartSelection = s),
          ),
          DownloadedTab(
            onOpenRegion: _openRegion,
            onFindMaps: () => _tabs.animateTo(OfflineMapsTab.maps.index),
          ),
        ],
      ),
    );
  }
}
