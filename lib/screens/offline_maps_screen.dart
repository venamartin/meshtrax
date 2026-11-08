import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../helpers/date_time_helper.dart';
import '../l10n/l10n.dart';
import '../services/map_packs_service.dart';
import 'offline_maps/charts_tab.dart';
import 'offline_maps/downloaded_tab.dart';
import 'offline_maps/maps_tab.dart';
import 'offline_maps/offline_maps_ui.dart';

/// The Offline maps screen's tabs, in order.
enum OfflineMapsTab { maps, charts, downloaded }

/// Download and manage offline map packs: browse regions (Maps), pick NOAA
/// chart areas by coast (Charts) and see what's on the device (Downloaded).
/// Layout and wording follow docs/technical/offline-maps-roadmap.md, screen S3.
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

  /// Checks the drive in use is still there when the app comes back.
  late final AppLifecycleListener _lifecycle;

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
    // After the first frame: refreshing notifies listeners at once. A drive
    // in use is only checked: reading it all again is the Refresh button's.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (maps.drive != null) {
        unawaited(maps.checkDrive());
      } else if (maps.status != CatalogueStatus.loading) {
        unawaited(maps.refresh());
      }
    });
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(maps.checkDrive()),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _useDrive() async {
    if (!await chooseDrive(context) || !mounted) return;
    setState(() {
      _browsePath = null;
      _selectedPath = null;
      _chartSelection = {};
    });
    _tabs.animateTo(OfflineMapsTab.maps.index);
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
          PopupMenuButton<void>(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: _useDrive,
                child: Text(l10n.offlineMaps_useDrive),
              ),
            ],
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
      // The tabs' lists set their own padding, so they don't leave room for
      // the phone's navigation buttons by themselves.
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const _DriveLine(),
            Expanded(
              child: TabBarView(
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
                    onOpenCharts: () =>
                        _tabs.animateTo(OfflineMapsTab.charts.index),
                  ),
                  ChartsTab(
                    openArea: widget.initialChartArea,
                    selected: _chartSelection,
                    onSelectionChanged: (s) =>
                        setState(() => _chartSelection = s),
                  ),
                  DownloadedTab(
                    onOpenRegion: _openRegion,
                    onFindMaps: () =>
                        _tabs.animateTo(OfflineMapsTab.maps.index),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Under the tabs: the drive in use, with Back to internet, and a reminder
/// to keep the app open while files copy; or that a drive went away.
class _DriveLine extends StatelessWidget {
  const _DriveLine();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final maps = context.watch<MapPacksService>();
    final drive = maps.drive;
    if (maps.readingDrive) {
      return ListTile(
        leading: const SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text(l10n.offlineMaps_readingDrive),
      );
    }
    if (drive == null) {
      if (!maps.driveRemoved) return const SizedBox.shrink();
      return ListTile(
        leading: Icon(Icons.usb_off, color: scheme.error),
        title: Text(l10n.offlineMaps_driveRemoved),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.common_close,
          onPressed: maps.dismissDriveRemoved,
        ),
      );
    }
    final made = maps.driveMapsDate;
    return Material(
      color: scheme.secondaryContainer,
      child: ListTile(
        leading: const Icon(Icons.usb),
        title: Text(
          l10n.offlineMaps_onDrive(
            drive.name,
            made == null
                ? '—'
                : DateFormat.yMMMd(DateTimeHelper.localeOf(context))
                      .format(made.toLocal()),
          ),
        ),
        subtitle: maps.driveBusy ? Text(l10n.offlineMaps_keepOpen) : null,
        trailing: TextButton(
          onPressed: () => _backToInternet(context, maps),
          child: Text(l10n.offlineMaps_backToInternet),
        ),
      ),
    );
  }

  /// Leaves the drive, asking first when files are still copying from it.
  Future<void> _backToInternet(
    BuildContext context,
    MapPacksService maps,
  ) async {
    if (maps.driveBusy) {
      final l10n = context.l10n;
      final stop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.offlineMaps_stopDriveTitle),
          content: Text(l10n.offlineMaps_stopDriveBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.offlineMaps_keepInstalling),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.offlineMaps_stopDrive),
            ),
          ],
        ),
      );
      if (stop != true) return;
    }
    await maps.useInternet();
  }
}
