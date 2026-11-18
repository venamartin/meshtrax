import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/meshcore_qr.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/share_contact_dialog.dart';

final _selfHex = 'ab' * 32;

Contact _saved(String name, int type, int seed) => Contact(
  publicKey: Uint8List.fromList(List.generate(32, (i) => seed + i)),
  name: name,
  type: type,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 1,
  lastSeen: DateTime(2026, 11, 1),
);

final _hill = _saved('Hilltop RPT', advTypeRepeater, 0x10);
final _alice = _saved('Alice', advTypeChat, 0x40);

class _Connector extends MeshCoreConnector {
  @override
  List<Contact> get contacts => [_hill, _alice];

  @override
  String get selfPublicKeyHex => _selfHex;

  @override
  String? get selfName => 'GWQ';
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  group('the contact line', () {
    test('reads back as the same contact', () {
      final line = MeshCoreQr.encodeContactText(
        'Hilltop RPT',
        _hill.publicKeyHex,
        2,
      );
      final back = MeshCoreQr.parseContactText(line)!;
      expect(back.pubKeyHex, _hill.publicKeyHex);
      expect(back.type, 2);
      expect(back.name, 'Hilltop RPT');
      expect(StructuredMessage.parse(line), isA<ShareMessage>());
    });

    test('a name with brackets or line breaks still makes one line', () {
      final line = MeshCoreQr.encodeContactText('A<b>\nc', _selfHex, 1);
      expect(line, '<$_selfHex:1:Abc>');
    });

    test('an empty name falls back to the start of the key', () {
      expect(
        MeshCoreQr.encodeContactText('  ', _selfHex.toUpperCase(), 1),
        '<$_selfHex:1:abababab>',
      );
    });
  });

  group('the share dialog', () {
    late String? picked;

    Future<void> open(WidgetTester tester) async {
      picked = 'not closed';
      final c = _Connector();
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  picked = await showShareContactDialog(context, c),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers my contact first, then saved ones by name', (
      tester,
    ) async {
      await open(tester);
      final names = tester
          .widgetList<ListTile>(find.byType(ListTile))
          .map((t) => (t.title as Text).data)
          .toList();
      expect(names, ['My contact', 'Alice', 'Hilltop RPT']);
    });

    testWidgets('picking a contact gives its line', (tester) async {
      await open(tester);
      await tester.tap(find.text('Hilltop RPT'));
      await tester.pumpAndSettle();
      expect(picked, '<${_hill.publicKeyHex}:2:Hilltop RPT>');
    });

    testWidgets('my contact is shared as a companion', (tester) async {
      await open(tester);
      await tester.tap(find.text('My contact'));
      await tester.pumpAndSettle();
      expect(picked, '<$_selfHex:1:GWQ>');
    });

    testWidgets('search narrows the list', (tester) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'hill');
      await tester.pump();
      expect(find.text('Alice'), findsNothing);
      expect(find.text('My contact'), findsNothing);
      expect(find.text('Hilltop RPT'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('No matches'), findsOneWidget);
    });

    testWidgets('cancel gives nothing', (tester) async {
      await open(tester);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(picked, isNull);
    });
  });
}
