import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/drawing_map.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/screens/drawing_compose_screen.dart';
import 'package:meshtrax/screens/drawing_settings_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';
import 'package:meshtrax/widgets/drawing_canvas.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';

import '../helpers/map_fakes.dart';

class _NoDownloads implements PackDownloader {
  @override
  Stream<PackDownload> get updates => const Stream.empty();
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(DownloadItem item) async {}
  @override
  Future<void> pause(String packId) async {}
  @override
  Future<void> resume(String packId) async {}
  @override
  Future<void> cancel(String packId) async {}
  @override
  Future<void> finish(String id, {String? error}) async {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Widget app(AppSettingsService service, Widget home, {MapPacksService? maps}) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: service),
          if (maps != null) ChangeNotifierProvider.value(value: maps),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: home,
        ),
      );

  void phone(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
  }

  group('the drawing page', () {
    /// Opens it from a button, returning a getter for what it popped.
    Future<String? Function()> open(
      WidgetTester tester, {
      int maxBytes = 148,
      MapPacksService? maps,
    }) async {
      phone(tester);
      String? wire;
      await tester.pumpWidget(app(
        AppSettingsService(),
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => DrawingComposeScreen.open(
                  context,
                  maxBytes: maxBytes,
                ).then((w) => wire = w),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        maps: maps,
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return () => wire;
    }

    Finder pad() => find.byType(CustomPaint).last;

    Future<void> drag(WidgetTester tester, List<Offset> fractions) async {
      final box = tester.getRect(find.descendant(
        of: find.byType(AspectRatio),
        matching: find.byType(Listener),
      ).first);
      Offset at(Offset f) => box.topLeft + Offset(f.dx * box.width, f.dy * box.height);
      final gesture = await tester.startGesture(at(fractions.first));
      for (final f in fractions.skip(1)) {
        await gesture.moveTo(at(f));
      }
      await gesture.up();
      await tester.pump();
    }

    FilledButton insert(WidgetTester tester) => tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Insert'),
        );

    testWidgets('opens empty, with Insert off', (tester) async {
      await open(tester);
      expect(find.text('Draw with your finger, or pick a shape.'), findsOneWidget);
      expect(insert(tester).onPressed, isNull);
      expect(pad(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a finger stroke becomes a drawing to insert', (tester) async {
      final wire = await open(tester);
      await drag(tester, [
        for (var i = 0; i <= 40; i++)
          Offset(0.1 + i * 0.02, 0.5 + 0.3 * (i.isEven ? 1 : -1) * (i / 40)),
      ]);
      expect(find.textContaining('/ 148 bytes'), findsOneWidget);
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();
      final sent = wire()!;
      expect(sent, startsWith('SVG:M'));
      expect(StructuredMessage.parse(sent), isA<SvgMessage>());
    });

    testWidgets('a circle costs a couple of dozen bytes', (tester) async {
      final wire = await open(tester);
      await tester.tap(find.byTooltip('Circle'));
      await tester.pump();
      await drag(tester, [const Offset(0.5, 0.5), const Offset(0.8, 0.5)]);
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();
      expect(wire(), 'SVG:M99 50a50 50 0 1 1 0-.1z');
    });

    testWidgets('the caption goes on its own line and takes room', (tester) async {
      final wire = await open(tester);
      await tester.tap(find.byTooltip('Line'));
      await tester.pump();
      await drag(tester, [const Offset(0.1, 0.1), const Offset(0.9, 0.9)]);
      await tester.enterText(find.widgetWithText(TextField, 'Caption'), 'Trail');
      await tester.pump();
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();
      expect(wire(), endsWith('\nTrail'));
      final m = StructuredMessage.parse(wire()!) as SvgMessage;
      expect(m.drawing.caption, 'Trail');
    });

    testWidgets('undo and clear', (tester) async {
      await open(tester);
      await tester.tap(find.byTooltip('Line'));
      await tester.pump();
      await drag(tester, [const Offset(0.1, 0.1), const Offset(0.9, 0.9)]);
      await drag(tester, [const Offset(0.1, 0.9), const Offset(0.9, 0.1)]);
      expect(insert(tester).onPressed, isNotNull);
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(insert(tester).onPressed, isNotNull);
      await tester.tap(find.byTooltip('Clear'));
      await tester.pump();
      expect(insert(tester).onPressed, isNull);
    });

    testWidgets('a tiny budget says the drawing is too detailed', (tester) async {
      await open(tester, maxBytes: 12);
      await drag(tester, [
        for (var i = 0; i <= 30; i++) Offset(0.1 + i * 0.025, 0.2 + (i % 5) * 0.12),
      ]);
      expect(find.textContaining('Too detailed'), findsOneWidget);
      expect(insert(tester).onPressed, isNull);
    });

    testWidgets('pasting an SVG draws it, and a bad one says why', (tester) async {
      final wire = await open(tester);
      await tester.tap(find.text('Paste'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'not svg <');
      await tester.tap(find.text('Use this SVG'));
      await tester.pump();
      expect(find.text("That isn't SVG the app can read."), findsOneWidget);
      await tester.enterText(
        find.byType(TextField).first,
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" '
        'stroke="currentColor"><path d="M4 12h16M12 4v16"/></svg>',
      );
      await tester.tap(find.text('Use this SVG'));
      await tester.pump();
      expect(insert(tester).onPressed, isNotNull);
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();
      // 12 sits halfway across 4..20, so it lands on 49.5, which rounds up.
      expect(wire(), 'SVG:M0 50h99M50 0v99');
    });

    testWidgets('every tool shows in full, even on a small phone', (tester) async {
      await open(tester);
      for (final width in [411.0, 360.0]) {
        tester.view.physicalSize = Size(width * 3, 2400);
        tester.view.devicePixelRatio = 3;
        await tester.pumpAndSettle();
        final rects = [
          for (final tool in [
            'Pen',
            'Route',
            'Line',
            'Arrow',
            'X mark',
            'Rectangle',
            'Circle',
            'Ellipse',
          ])
            tester.getRect(find.byTooltip(tool)),
        ];
        for (var i = 0; i < rects.length; i++) {
          expect(rects[i].left, greaterThanOrEqualTo(16), reason: '$width $i');
          expect(rects[i].right, lessThanOrEqualTo(width - 16), reason: '$width $i');
          if (i > 0) expect(rects[i].left, greaterThanOrEqualTo(rects[i - 1].right - 1));
        }
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('the ellipse tool draws an ellipse', (tester) async {
      final wire = await open(tester);
      await tester.tap(find.byTooltip('Ellipse'));
      await tester.pump();
      await drag(tester, [const Offset(0.2, 0.3), const Offset(0.8, 0.6)]);
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();
      final m = StructuredMessage.parse(wire()!) as SvgMessage;
      expect(m.drawing.pathData, matches(RegExp(r'^M99 \d+a50 \d+ 0 1 1 0-\.1z$')));
    });

    testWidgets('a route takes a point a tap, and Undo takes the last back', (
      tester,
    ) async {
      final wire = await open(tester);
      await tester.tap(find.byTooltip('Route'));
      await tester.pump();
      expect(
        find.text('Tap to add points. Tap the last one again to finish.'),
        findsOneWidget,
      );
      for (final f in const [Offset(0.1, 0.1), Offset(0.5, 0.9), Offset(0.9, 0.1)]) {
        await drag(tester, [f]);
      }
      expect(find.textContaining('3 points'), findsOneWidget);
      await tester.tap(find.byTooltip('Undo'));
      await tester.pump();
      expect(find.textContaining('2 points'), findsOneWidget);
      // The last point again finishes the route; the next tap starts one.
      await drag(tester, [const Offset(0.5, 0.9)]);
      await drag(tester, [const Offset(0.9, 0.9)]);
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();
      final d = (StructuredMessage.parse(wire()!) as SvgMessage).drawing;
      expect(d.polylines()!.length, 2);
      expect(d.polylines()!.first.length, 2);
    });

    testWidgets('an arrow started near the end of a route starts right on it', (
      tester,
    ) async {
      final wire = await open(tester);
      await tester.tap(find.byTooltip('Route'));
      await tester.pump();
      await drag(tester, [const Offset(0.1, 0.5)]);
      await drag(tester, [const Offset(0.5, 0.5)]);
      await drag(tester, [const Offset(0.5, 0.5)]);
      await tester.tap(find.byTooltip('Arrow'));
      await tester.pump();
      // A little off the route's end, as a finger would be.
      await drag(tester, [const Offset(0.52, 0.53), const Offset(0.9, 0.5)]);
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();
      final lines = (StructuredMessage.parse(wire()!) as SvgMessage)
          .drawing
          .polylines()!;
      // The route and the arrow's shaft are one line now; the head is apart.
      expect(lines.first, [
        (x: 0.0, y: 0.0),
        (x: 50.0, y: 0.0),
        (x: 99.0, y: 0.0),
      ]);
    });

    testWidgets('a tapped X on its own fills the drawing', (tester) async {
      final wire = await open(tester);
      await tester.tap(find.byTooltip('X mark'));
      await tester.pump();
      await drag(tester, [const Offset(0.5, 0.5)]);
      await tester.tap(find.text('Insert'));
      await tester.pumpAndSettle();
      expect(wire(), 'SVG:M0 0l99 99M99 0 0 99');
    });

    testWidgets('with no map packs service there is no map to pick', (
      tester,
    ) async {
      await open(tester);
      expect(find.text('No map'), findsNothing);
    });

    group('over a map', () {
      late Directory tmp;
      setUp(() async => tmp = await Directory.systemTemp.createTemp('drawmap'));
      tearDown(() async {
        try {
          await tmp.delete(recursive: true);
        } on FileSystemException {
          // Windows can hold a map file a moment longer.
        }
      });

      MapPacksService maps() => MapPacksService(
            manager: PackManager(Directory('${tmp.path}/packs')),
            downloader: _NoDownloads(),
            cacheDir: tmp,
            styles: StyleRegistry(MemoryStyles(maps: ['osm', 'usgs', 'charts'])),
          );

      Future<void> settle(WidgetTester tester) async {
        for (var i = 0; i < 6; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      testWidgets('pick a map, draw here, and the message carries the map', (
        tester,
      ) async {
        final wire = await open(tester, maps: maps());
        expect(find.text('No map'), findsOneWidget);
        // Nothing is downloaded, so only Standard can be picked.
        await tester.tap(find.text('Charts'));
        await settle(tester);
        expect(find.text('Draw here'), findsNothing);
        await tester.tap(find.text('Standard'));
        await settle(tester);
        expect(find.byType(AppMap), findsOneWidget);
        expect(find.text('Draw here'), findsOneWidget);
        expect(
          find.text('Pan and zoom to the place, then tap Draw here.'),
          findsOneWidget,
        );
        expect(insert(tester).onPressed, isNull);

        await tester.tap(find.text('Draw here'));
        await settle(tester);
        expect(find.byTooltip('Move map'), findsOneWidget);
        expect(tester.widget<AppMap>(find.byType(AppMap)).exact, isTrue);
        await tester.tap(find.byTooltip('X mark'));
        await tester.pump();
        await drag(tester, [const Offset(0.5, 0.5)]);
        expect(find.textContaining('Standard,'), findsOneWidget);
        final first = insert(tester);
        expect(first.onPressed, isNotNull);

        // Move map, then Draw here on the same spot: the same drawing.
        await tester.tap(find.byTooltip('Move map'));
        await settle(tester);
        expect(insert(tester).onPressed, isNull);
        await tester.tap(find.text('Draw here'));
        await settle(tester);

        await tester.tap(find.text('Insert'));
        await settle(tester);
        final m = StructuredMessage.parse(wire()!) as SvgMessage;
        expect(m.drawing.map, isNotNull);
        expect(m.drawing.map!.type, DrawingMapType.standard);
        expect(m.drawing.map!.toLine(), 'map=3/0/0');
        // A tapped X, 8 grid steps across, in the middle of the frame.
        expect(m.drawing.pathData, 'M46 34l8 8m0-8-8 8');
      });
    });

    testWidgets('it fits a phone with the keyboard open', (tester) async {
      await open(tester);
      tester.view.viewInsets = const FakeViewPadding(bottom: 800);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('the settings', () {
    test('default to the look the owner picked', () {
      for (final s in [AppSettings(), AppSettings.fromJson(const {})]) {
        expect(s.showDrawings, isTrue);
        expect(s.drawingPenColor, 0xFF33FF33);
        expect(s.drawingLineWidth, 2);
        expect(s.drawingGlow, 65);
        expect(s.drawingScanlines, 33);
      }
    });

    test('survive a save and a load, and ignore the Logo test keys', () {
      final s = AppSettings().copyWith(
        showDrawings: false,
        drawingPenColor: 0xFFFFB000,
        drawingLineWidth: 1.25,
        drawingGlow: 10,
        drawingScanlines: 0,
      );
      final loaded = AppSettings.fromJson(s.toJson());
      expect(loaded.showDrawings, isFalse);
      expect(loaded.drawingPenColor, 0xFFFFB000);
      expect(loaded.drawingLineWidth, 1.25);
      expect(loaded.drawingGlow, 10);
      expect(loaded.drawingScanlines, 0);
      final logo = AppSettings.fromJson(const {
        'show_drawings': false,
        'logo_pen_color': 0xFFFFB000,
      });
      expect(logo.showDrawings, isTrue);
      expect(logo.drawingPenColor, 0xFF33FF33);
    });

    Future<AppSettingsService> pump(WidgetTester tester) async {
      phone(tester);
      final service = AppSettingsService();
      await tester.pumpWidget(app(service, const DrawingSettingsScreen()));
      await tester.pump();
      return service;
    }

    testWidgets('shows a preview and every control', (tester) async {
      await pump(tester);
      expect(find.byType(DrawingCanvas), findsOneWidget);
      for (final text in [
        'Show drawings',
        'Pen color',
        '#33FF33',
        'Line width',
        'Glow',
        '65',
        'Scanlines',
        '33',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('a slider previews while dragged and saves when let go', (
      tester,
    ) async {
      final service = await pump(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Slider).at(1)),
      );
      await gesture.moveBy(const Offset(-200, 0));
      await tester.pump();
      final dragged =
          tester.widget<DrawingCanvas>(find.byType(DrawingCanvas)).look.glow;
      expect(dragged, lessThan(65));
      expect(service.settings.drawingGlow, 65);
      await gesture.up();
      await tester.pump();
      expect(service.settings.drawingGlow, dragged);
    });

    testWidgets('a pen color from the presets or by code', (tester) async {
      final service = await pump(tester);
      await tester.tap(find.text('Pen color'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('#FFB000'));
      await tester.pumpAndSettle();
      expect(service.settings.drawingPenColor, 0xFFFFB000);
      await tester.tap(find.text('Pen color'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '12ab34');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'OK'));
      await tester.pumpAndSettle();
      expect(service.settings.drawingPenColor, 0xFF12AB34);
    });

    testWidgets('reset brings back the default look', (tester) async {
      final service = await pump(tester);
      await service.setDrawingLook(penColor: 0xFFFFB000, glow: 1, scanlines: 2);
      await tester.pump();
      await tester.ensureVisible(find.text('Reset'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pump();
      expect(service.settings.drawingPenColor, AppSettings.defaultDrawingPenColor);
      expect(service.settings.drawingGlow, AppSettings.defaultDrawingGlow);
      expect(service.settings.drawingScanlines, AppSettings.defaultDrawingScanlines);
    });
  });
}
