import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/helpers/navigate_helper.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/utils/format_bytes.dart';
import 'package:meshtrax/widgets/route_sheet.dart';
import 'package:traxroute/traxroute.dart';

// Navigate on a card handed every point to another app; it now routes in
// MeshTrax when the place's routing is on the phone, and otherwise says what
// to download, or offers a start or another app (owner, 2026-11-16).
void main() {
  const region = (path: 'north-america/us/california-north', name: 'Northern California');

  NavigatePlan plan({
    bool canRoute = true,
    ({String path, String name})? where = region,
    bool installed = true,
    int? bytes = 85000000,
    bool hasPosition = true,
  }) =>
      NavigateHelper.plan(
        canRoute: canRoute,
        region: where,
        installed: installed,
        downloadBytes: bytes,
        hasPosition: hasPosition,
      );

  group('plan', () {
    test('routing on the phone and a position: route in MeshTrax', () {
      expect(plan(), isA<NavigateRoute>());
    });

    test('routing on the phone, no position: ask for a start', () {
      expect(plan(hasPosition: false), isA<NavigateNeedsStart>());
    });

    test('routing to download: name the region and its size', () {
      final p = plan(installed: false);
      expect(p, isA<NavigateNeedsDownload>());
      p as NavigateNeedsDownload;
      expect(p.regionName, 'Northern California');
      expect(p.regionPath, region.path);
      expect(p.bytes, 85000000);
    });

    test('no routing to get there, or no region at all', () {
      expect(plan(installed: false, bytes: null), isA<NavigateNoRouting>());
      expect(plan(where: null), isA<NavigateNoRouting>());
    });

    test('a device that cannot route hands the point on', () {
      expect(plan(canRoute: false), isA<NavigateOtherApp>());
    });
  });

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );

  Future<void> actOn(WidgetTester tester, NavigatePlan p) async {
    await pump(
      tester,
      Builder(
        builder: (context) => TextButton(
          onPressed: () => NavigateHelper.act(
            context,
            p,
            const LatLng(37.0, -121.9),
          ),
          child: const Text('go'),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('the download dialog names the region and its size', (
    tester,
  ) async {
    const bytes = 85 * 1000 * 1000;
    await actOn(
      tester,
      NavigateNeedsDownload(region.path, region.name, bytes),
    );
    expect(
      find.text("Offline routing for Northern California isn't on this "
          'phone. Its download is ${formatBytes(bytes)}.'),
      findsOneWidget,
    );
    expect(find.text('Show download'), findsOneWidget);
    expect(find.text('Another app'), findsOneWidget);
    expect(find.text('Cancel'), findsNothing,
        reason: 'two buttons fit a phone row; a tap outside cancels');
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('no position: pick a start or another app', (tester) async {
    await actOn(tester, const NavigateNeedsStart());
    expect(find.textContaining('No GPS position.'), findsOneWidget);
    expect(find.text('Pick a start'), findsOneWidget);
    expect(find.text('Another app'), findsOneWidget);
  });

  testWidgets('no routing there: only another app', (tester) async {
    await actOn(tester, const NavigateNoRouting());
    expect(find.text("There's no offline routing for this area yet."),
        findsOneWidget);
    expect(find.text('Another app'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Show download'), findsNothing);
    expect(find.text('Pick a start'), findsNothing);
  });

  group('route sheet', () {
    Widget sheet({VoidCallback? onOtherApp}) => RouteSheet(
          destination: 'Ridge trailhead',
          start: null,
          onUseMyPosition: () {},
          pathType: PathType.hiking,
          onPathType: (_) {},
          options: const RouteOptions(),
          onOptions: (_) {},
          result: null,
          loading: false,
          error: null,
          units: UnitSystem.metric,
          onClose: () {},
          onOtherApp: onOtherApp,
          side: true,
        );

    testWidgets('its top row hands the route to another app', (tester) async {
      var handed = 0;
      await pump(tester, sheet(onOtherApp: () => handed++));
      await tester.tap(find.byTooltip('Open in another app'));
      expect(handed, 1);
    });

    testWidgets('no button without somewhere to hand it', (tester) async {
      await pump(tester, sheet());
      expect(find.byTooltip('Open in another app'), findsNothing);
    });
  });
}
