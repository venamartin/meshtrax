import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/helpers/svg_drawing.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';
import 'package:meshtrax/widgets/drawing_canvas.dart';
import 'package:meshtrax/widgets/drawing_map_view.dart';
import 'package:meshtrax/widgets/structured_message_card.dart';
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
  Future<void> start(PackIndexEntry entry) async {}
  @override
  Future<void> pause(String packId) async {}
  @override
  Future<void> resume(String packId) async {}
  @override
  Future<void> cancel(String packId) async {}
}

void main() {
  const plain = DrawingLook(
    pen: Color(0xFF33FF33),
    lineWidth: 2,
    glow: 0,
    scanlines: 0,
  );
  const size = Size(100, 100);

  List<List<SvgPoint>> lines(String path) =>
      SvgDrawing.tryParse(path)!.polylines()!;

  Future<List<int>> pixel(ui.Image image, int x, int y) async {
    final data = (await image.toByteData())!;
    final i = (y * image.width + x) * 4;
    return [for (var c = 0; c < 4; c++) data.getUint8(i + c)];
  }

  group('rasterizeDrawing', () {
    testWidgets('the screen fills it, in device pixels', (tester) async {
      await tester.runAsync(() async {
        final image = rasterizeDrawing(lines('M0 0 0 9'), plain, size, 2);
        expect((image.width, image.height), (200, 200));
        expect(await pixel(image, 2, 2), [0x01, 0x0A, 0x03, 0xFF]);
      });
    });

    testWidgets('a line down the middle is the pen color', (tester) async {
      await tester.runAsync(() async {
        final image = rasterizeDrawing(lines('M0 0 0 9'), plain, size, 2);
        expect(await pixel(image, 100, 100), [0x33, 0xFF, 0x33, 0xFF]);
      });
    });

    testWidgets('y points down, as in SVG', (tester) async {
      await tester.runAsync(() async {
        // A short tick at the top of a tall line: it must land at the top.
        // The line fills 68 of the 100 units, so the tick runs from x 43 to
        // 57 at y 16, and flipped it would be at y 84.
        final image = rasterizeDrawing(
          lines('M50 0v100M50 0h20'),
          plain,
          size,
          2,
        );
        expect(await pixel(image, 100, 16 * 2), [0x33, 0xFF, 0x33, 0xFF]);
        expect(await pixel(image, 100, 84 * 2), [0x01, 0x0A, 0x03, 0xFF]);
      });
    });

    testWidgets('a tap shows as a dot', (tester) async {
      await tester.runAsync(() async {
        final image = rasterizeDrawing(lines('M5 5h0'), plain, size, 2);
        expect(await pixel(image, 100, 100), [0x33, 0xFF, 0x33, 0xFF]);
      });
    });

    testWidgets('glow and scanlines change the picture', (tester) async {
      await tester.runAsync(() async {
        Future<List<int>> bytes(DrawingLook look) async {
          final image = rasterizeDrawing(lines('M0 0 0 9'), look, size, 2);
          return (await image.toByteData())!.buffer.asUint8List();
        }

        final base = await bytes(plain);
        const glow = DrawingLook(
          pen: Color(0xFF33FF33),
          lineWidth: 2,
          glow: 65,
          scanlines: 0,
        );
        const scan = DrawingLook(
          pen: Color(0xFF33FF33),
          lineWidth: 2,
          glow: 0,
          scanlines: 33,
        );
        expect(await bytes(glow), isNot(base));
        expect(await bytes(scan), isNot(base));
      });
    });
  });

  group('the card', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
    });

    Future<AppSettingsService> pumpCard(
      WidgetTester tester,
      String text, {
      Brightness brightness = Brightness.dark,
      double width = 322,
      MapPacksService? maps,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.625;
      addTearDown(tester.view.reset);
      final settings = AppSettingsService();
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: settings),
            if (maps != null) ChangeNotifierProvider.value(value: maps),
          ],
          child: MaterialApp(
            theme: ThemeData(brightness: brightness),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: width,
                  child: StructuredMessageCard(
                    message: StructuredMessage.parse(text)!,
                    textScale: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return settings;
    }

    for (final brightness in Brightness.values) {
      testWidgets('draws at card size, ${brightness.name}', (tester) async {
        await pumpCard(tester, 'SVG:M10 10h80v80H10z', brightness: brightness);
        expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
        expect(tester.getSize(find.byType(DrawingCanvas)), const Size(322, 240));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('a narrow card is as tall as it is wide', (tester) async {
      await pumpCard(tester, 'SVG:M0 0 9 9', width: 200);
      expect(tester.getSize(find.byType(DrawingCanvas)), const Size(200, 200));
    });

    testWidgets('the caption shows under the picture', (tester) async {
      await pumpCard(tester, 'SVG:M0 0 9 9\nOur camp');
      expect(find.text('Our camp'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Our camp')).dy,
        greaterThan(tester.getBottomLeft(find.byType(DrawingCanvas)).dy),
      );
    });

    testWidgets('with drawings off it shows the code, and comes back', (
      tester,
    ) async {
      final settings = await pumpCard(tester, 'SVG:M0 0 9 9');
      await settings.setShowDrawings(false);
      await tester.pump();
      expect(find.byType(DrawingCanvas), findsNothing);
      expect(find.text('SVG:M0 0 9 9'), findsOneWidget);
      await settings.setShowDrawings(true);
      await tester.pump();
      expect(find.byType(DrawingCanvas), findsOneWidget);
    });

    testWidgets('a new look repaints an open card', (tester) async {
      final settings = await pumpCard(tester, 'SVG:M0 0 9 9');
      final before = tester.widget<RawImage>(find.byType(RawImage)).image;
      await settings.setDrawingLook(glow: 10);
      await tester.pump();
      final after = tester.widget<RawImage>(find.byType(RawImage)).image;
      expect(identical(before, after), isFalse);
    });

    testWidgets('a tap opens the viewer, whose Copy gives an SVG file', (
      tester,
    ) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpCard(tester, 'SVG:M10 10h80v80H10z');
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(find.text('M10 10h80v80H10z'), findsOneWidget);
      expect(find.byType(DrawingCanvas), findsNWidgets(2));
      await tester.tap(find.text('Copy SVG'));
      await tester.pumpAndSettle();
      expect(copied, startsWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="7 7 86 86">'));
      expect(copied, contains('d="M10 10h80v80H10z" fill="none" stroke="#33ff33"'));
      expect(copied, contains('stroke-linecap="round"'));
    });

    const anchored =
        'SVG:M55 33l8 8m0-8-8 8\nmap=16/36.9695/-121.9525/c\nAnchored here';

    testWidgets('without maps, a map drawing still draws on the green screen', (
      tester,
    ) async {
      await pumpCard(tester, anchored);
      expect(find.byType(DrawingCanvas), findsOneWidget);
      expect(find.byType(DrawingMapView), findsNothing);
      expect(find.text('Anchored here'), findsOneWidget);
    });

    group('over a map', () {
      late Directory tmp;
      setUp(() async => tmp = await Directory.systemTemp.createTemp('cardmap'));
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

      testWidgets('the card shows the exact frame, Standard without charts, '
          'and says the area is not downloaded', (tester) async {
        await pumpCard(tester, anchored, maps: maps());
        await settle(tester);
        final view = tester.widget<DrawingMapView>(find.byType(DrawingMapView));
        final map = tester.widget<AppMap>(find.byType(AppMap));
        expect(map.exact, isTrue);
        expect(map.compact, isTrue);
        expect(map.mapType, MapType.osm);
        expect(map.initialCamera!.center, const LatLng(36.9695, -121.9525));
        expect(
          map.initialCamera!.zoom,
          closeTo(15 + math.log(view.width / 400) / math.ln2, 1e-9),
        );
        final box = tester.getSize(find.byType(AppMap));
        expect(box.height, closeTo(box.width * 0.75, 0.01));
        expect(find.text("This area isn't downloaded"), findsOneWidget);
        expect(find.text('Anchored here'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('a far-out frame needs no download', (tester) async {
        await pumpCard(tester, 'SVG:M10 10 90 60\nmap=9/36.97/-121.95', maps: maps());
        await settle(tester);
        expect(find.byType(DrawingMapView), findsOneWidget);
        expect(find.text("This area isn't downloaded"), findsNothing);
      });

      testWidgets('a tap opens the viewer with the map, and Copy keeps the frame', (
        tester,
      ) async {
        String? copied;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          },
        );
        addTearDown(
          () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          ),
        );
        await pumpCard(tester, anchored, maps: maps());
        await settle(tester);
        await tester.tap(find.byType(InkWell).first);
        await settle(tester);
        expect(find.byType(DrawingMapView), findsNWidgets(2));
        expect(
          find.text('M55 33l8 8m0-8-8 8\nmap=16/36.9695/-121.9525/c'),
          findsOneWidget,
        );
        await tester.tap(find.text('Copy SVG'));
        await settle(tester);
        expect(copied, startsWith('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 75">'));
      });
    });
  });
}
