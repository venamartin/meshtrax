import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/photo_reports.dart';
import 'package:meshtrax/services/photo_store.dart';
import 'package:meshtrax/widgets/photo_report_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

final code = List<int>.generate(435, (i) => i & 0xFF);

Widget app(String messageId) => ChangeNotifierProvider<AppSettingsService>(
  create: (_) => AppSettingsService(),
  child: MaterialApp(
    localizationsDelegates: appLocalizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Builder(
      builder: (context) => Scaffold(
        body: TextButton(
          onPressed: () => reportPhoto(
            context,
            messageId: messageId,
            sender: 'Someone',
            photoTime: DateTime(2026, 11, 22),
          ),
          child: const Text('report'),
        ),
      ),
    ),
  ),
);

Future<PhotoReport> report(WidgetTester tester, String messageId) async {
  await tester.pumpWidget(app(messageId));
  await tester.tap(find.text('report'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField), 'Nothing');
  await tester.pumpAndSettle();
  final include = find.text('Include the photo');
  await tester.ensureVisible(include);
  await tester.pumpAndSettle();
  await tester.tap(include);
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(FilledButton, 'Report'));
  await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 1)));
  await tester.pumpAndSettle();
  return PhotoReports.instance.all.first;
}

void main() {
  late Directory tmp;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tmp = Directory.systemTemp.createTempSync('photo-report');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => tmp.path,
        );
    PackageInfo.setMockInitialValues(
      appName: 'MeshTrax',
      packageName: 'test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
    final photos = Directory('${tmp.path}/photos')..createSync();
    for (final id in ['m1', 'm2']) {
      File('${photos.path}/$id.aeic').writeAsBytesSync(code);
      File('${photos.path}/$id.json').writeAsStringSync(
        jsonEncode(
          PhotoRecord(
            messageId: id,
            bytes: code.length,
            packets: 4,
            outgoing: false,
          ).toJson(),
        ),
      );
    }
    await PhotoStore.instance.load();
  });

  tearDownAll(() => tmp.deleteSync(recursive: true));

  testWidgets('Include the photo puts its code in the report', (tester) async {
    final r = await report(tester, 'm1');
    expect(r.reason, 'Nothing');
    expect(r.code, base64Encode(code));
    expect(PhotoStore.instance.recordFor('m1')!.reported, isTrue);
  });

  testWidgets(
    'with the keyboard up on a phone, the boxes can still be ticked',
    (tester) async {
      tester.view
        ..devicePixelRatio = 3
        ..physicalSize = const Size(375 * 3, 812 * 3)
        ..viewInsets = const FakeViewPadding(bottom: 336 * 3);
      addTearDown(tester.view.reset);
      final r = await report(tester, 'm2');
      expect(r.code, base64Encode(code));
    },
  );
}
