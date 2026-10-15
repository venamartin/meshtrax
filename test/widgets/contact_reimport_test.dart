import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/contact_import_helper.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';

// Re-importing a key that is already a saved contact (bare hex, QR, link,
// clipboard) must not send CMD_ADD_UPDATE_CONTACT: the firmware applies it
// in place (updateContactFromFrame), and the blank record built from the
// key would wipe the contact's name, type, flags, learned route and
// location.
final _key = Uint8List.fromList(List.generate(32, (i) => 0x10 + i));

final _existing = Contact(
  publicKey: _key,
  name: 'Hilltop RPT',
  type: advTypeRepeater,
  flags: 1, // favourite
  pathLength: 2,
  path: Uint8List.fromList([0xA2, 0x11, 0xBE, 0xEF]),
  pathHashSize: 2,
  latitude: 51.5,
  longitude: -0.12,
  lastSeen: DateTime(2026, 10, 1),
);

class _Connector extends MeshCoreConnector {
  final List<Contact> imported = [];

  @override
  bool get isConnected => true;

  @override
  int get pathHashByteWidth => 2;

  @override
  List<Contact> get contacts => [_existing];

  @override
  List<Contact> get allContacts => [_existing];

  @override
  Future<bool> importDiscoveredContact(Contact contact) async {
    imported.add(contact);
    return true;
  }
}

void main() {
  late _Connector c;
  late BuildContext ctx;

  Future<void> pumpHost(WidgetTester tester) async {
    c = _Connector();
    await tester.pumpWidget(
      ChangeNotifierProvider<MeshCoreConnector>.value(
        value: c,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(
            body: Builder(builder: (context) {
              ctx = context;
              return const SizedBox();
            }),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (label, data) in [
    ('bare key', _existing.publicKeyHex),
    ('bare key in uppercase', _existing.publicKeyHex.toUpperCase()),
    (
      'contact link',
      'meshcore://contact/add?name=Other&public_key='
          '${_existing.publicKeyHex}&type=1',
    ),
  ]) {
    testWidgets('re-importing a saved contact by $label leaves it untouched',
        (tester) async {
      await pumpHost(tester);

      ContactImportHelper.importFromScannedData(ctx, data);
      await tester.pump();

      expect(c.imported, isEmpty,
          reason: 'nothing may be written over the saved contact');
      expect(find.text('Hilltop RPT is already in your contacts.'),
          findsOneWidget);
    });
  }

  testWidgets('a new key is still imported', (tester) async {
    await pumpHost(tester);
    final other = List.generate(32, (i) => 0x80 + i)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    ContactImportHelper.importFromScannedData(ctx, other);
    await tester.pump();

    expect(c.imported.single.publicKeyHex, other);
  });
}
