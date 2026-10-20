import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/map_packs_service.dart';
import 'offline_maps/downloaded_tab.dart';
import 'offline_maps/maps_tab.dart';

/// Download and manage offline map packs: browse regions (Maps) and see
/// what's on the device (Downloaded). Layout and wording follow
/// docs/offline-maps-roadmap.md, screen S3.
class OfflineMapsScreen extends StatefulWidget {
  /// Opens the Maps tab on this region's detail (a picker `path`).
  final String? initialRegionPath;

  const OfflineMapsScreen({super.key, this.initialRegionPath});

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

  @override
  void initState() {
    super.initState();
    final maps = context.read<MapPacksService>();
    _selectedPath = widget.initialRegionPath;
    _browsePath = _selectedPath == null
        ? null
        : maps.regions?[_selectedPath!]?.parentPath;
    final openDownloaded =
        _selectedPath == null &&
        (maps.installed.isNotEmpty || maps.activeDownloadCount > 0);
    _tabs = TabController(
      length: 2,
      vsync: this,
      initialIndex: openDownloaded ? 1 : 0,
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
    setState(() {
      _selectedPath = path;
      _browsePath = regions?[path]?.parentPath;
    });
    _tabs.animateTo(0);
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
          ),
          DownloadedTab(
            onOpenRegion: _openRegion,
            onFindMaps: () => _tabs.animateTo(0),
          ),
        ],
      ),
    );
  }
}
