import 'dart:async';

import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart' as traxmap show LatLng, MapType;

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/map_focus.dart';
import '../screens/map_screen.dart';
import '../screens/offline_maps_screen.dart';
import '../services/app_settings_service.dart';
import '../services/routing_service.dart';
import '../services/water_routing_service.dart';
import '../utils/format_bytes.dart';
import 'link_handler.dart';

/// What Navigate on a card does with a point.
sealed class NavigatePlan {
  const NavigatePlan();
}

/// Our routing has the place and knows where you are: route there.
class NavigateRoute extends NavigatePlan {
  const NavigateRoute();
}

/// Our routing has the place, but the radio has no position.
class NavigateNeedsStart extends NavigatePlan {
  const NavigateNeedsStart();
}

/// The place's region has routing to download: on the charts, its chart
/// area's water routing.
class NavigateNeedsDownload extends NavigatePlan {
  final String regionPath;
  final String regionName;
  final int bytes;
  final bool water;
  const NavigateNeedsDownload(
    this.regionPath,
    this.regionName,
    this.bytes, {
    this.water = false,
  });
}

/// There's no routing to get for the place.
class NavigateNoRouting extends NavigatePlan {
  const NavigateNoRouting();
}

/// This device can't route at all: hand the point to another app.
class NavigateOtherApp extends NavigatePlan {
  const NavigateOtherApp();
}

/// Navigate on a Location or SOS card: our own offline routing first, else
/// what to download or another map app (owner, 2026-11-16). On the charts it
/// is a trip on the water (owner, 2026-11-24).
class NavigateHelper {
  /// The plan for a point in [region] (null: no downloadable region there).
  /// [downloadBytes] is null when no routing is on offer for the region.
  static NavigatePlan plan({
    required bool canRoute,
    required ({String path, String name})? region,
    required bool installed,
    required int? downloadBytes,
    required bool hasPosition,
  }) {
    if (!canRoute) return const NavigateOtherApp();
    if (region != null && installed) {
      return hasPosition ? const NavigateRoute() : const NavigateNeedsStart();
    }
    if (region != null && downloadBytes != null) {
      return NavigateNeedsDownload(region.path, region.name, downloadBytes);
    }
    return const NavigateNoRouting();
  }

  /// The plan on the charts for a point in chart [area] (null: no chart
  /// area there has water routing). Away from the areas on the device a
  /// trip is still tried: it ends short or says why, and offers the land
  /// map.
  static NavigatePlan planWater({
    required bool canRoute,
    required ({String path, String name})? area,
    required bool installed,
    required bool hasRoutingData,
    required int? downloadBytes,
    required bool hasPosition,
  }) {
    if (!canRoute) return const NavigateOtherApp();
    final route = hasPosition
        ? const NavigateRoute()
        : const NavigateNeedsStart();
    if (area != null && installed) return route;
    if (area != null && downloadBytes != null) {
      return NavigateNeedsDownload(
        area.path,
        area.name,
        downloadBytes,
        water: true,
      );
    }
    return hasRoutingData ? route : const NavigateNoRouting();
  }

  static Future<void> navigate(
    BuildContext context,
    LatLng position, {
    String? label,
  }) async {
    final connector = context.read<MeshCoreConnector>();
    final hasPosition = connector.hasValidLocation(
      connector.selfLatitude,
      connector.selfLongitude,
    );
    final settings = context.read<AppSettingsService>().settings;
    if (traxmap.MapType.parse(settings.mapType) == traxmap.MapType.charts) {
      final water = context.read<WaterRoutingService?>();
      final area = water?.areaAt(
        traxmap.LatLng(position.latitude, position.longitude),
      );
      final todo = area == null
          ? const <String>{}
          : water!.downloadsFor({area.packRegion});
      final plan = NavigateHelper.planWater(
        canRoute: water != null,
        area: area == null ? null : (path: area.packRegion, name: area.name),
        installed: area != null && water!.isInstalled(area.packRegion),
        hasRoutingData: water?.hasRoutingData ?? false,
        downloadBytes: todo.isEmpty ? null : water!.bytesFor(todo),
        hasPosition: hasPosition,
      );
      return act(context, plan, position, label: label);
    }
    final routing = context.read<RoutingService?>();
    final region = routing?.maps.regions?.regionAt(
      traxmap.LatLng(position.latitude, position.longitude),
    );
    final offered =
        region != null && routing!.bundleFor(region.path) != null;
    final plan = NavigateHelper.plan(
      canRoute: routing != null && routing.available,
      region: region == null ? null : (path: region.path, name: region.name),
      installed: region != null && routing!.isInstalled(region.path),
      downloadBytes: offered ? routing.bytesFor({region.path}) : null,
      hasPosition: hasPosition,
    );
    await act(context, plan, position, label: label);
  }

  /// Does what [plan] says for [position]: route, hand it to another app,
  /// or ask first.
  @visibleForTesting
  static Future<void> act(
    BuildContext context,
    NavigatePlan plan,
    LatLng position, {
    String? label,
  }) async {
    void route() =>
        MapScreen.show(context, MapFocusRoute(position, label: label));
    void otherApp() =>
        unawaited(LinkHandler.openInMapsApp(context, position, label: label));

    final l10n = context.l10n;
    final (String? text, String? yes, VoidCallback? onYes) = switch (plan) {
      NavigateOtherApp() || NavigateRoute() => (null, null, null),
      NavigateNeedsStart() => (
        l10n.navigate_noPosition,
        l10n.navigate_pickStart,
        route,
      ),
      NavigateNeedsDownload(
        :final regionPath,
        :final regionName,
        :final bytes,
        :final water,
      ) =>
        (
          '${water ? l10n.water_routingMissing(regionName) : l10n.navigate_routingMissing(regionName)} '
              '${l10n.navigate_routingSize(formatBytes(bytes))}',
          l10n.navigate_showDownload,
          () => unawaited(
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => water
                    ? OfflineMapsScreen(initialWaterRouting: regionPath)
                    : OfflineMapsScreen(initialRegionPath: regionPath),
              ),
            ),
          ),
        ),
      NavigateNoRouting() => (l10n.navigate_noRoutingHere, null, null),
    };
    if (plan is NavigateOtherApp) return otherApp();
    if (plan is NavigateRoute) return route();
    final answer = await _ask(context, text!, yes);
    if (!context.mounted) return;
    if (answer == true) onYes?.call();
    if (answer == false) otherApp();
  }

  /// Cancel (null), Another app (false) and, when [yes] is given, it (true).
  static Future<bool?> _ask(BuildContext context, String text, String? yes) {
    final l10n = context.l10n;
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.structured_navigate),
        content: Text(text),
        actions: [
          if (yes == null)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.common_cancel),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.navigate_otherApp),
          ),
          if (yes != null)
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(yes),
            ),
        ],
      ),
    );
  }
}
