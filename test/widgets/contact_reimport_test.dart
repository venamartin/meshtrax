import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/contact_import_helper.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/room_login_dialog.dart';

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
  final List<int?> advertTimes = [];
  List<Contact> heard = [];

  @override
  bool get isConnected => true;

  @override
  int get pathHashByteWidth => 2;

  @override
  List<Contact> get contacts => [_existing, ...imported];

  @override
  List<Contact> get allContacts => [_existing, ...imported];

  @override
  List<Contact> get discoveredContacts => heard;

  @override
  Future<bool> importDiscoveredContact(
    Contact contact, {
    int? lastAdvertEpochSeconds,
  }) async {
    imported.add(contact);
    advertTimes.add(lastAdvertEpochSeconds);
    return true;
  }
}

void main() {
  late _Connector c;
  late BuildContext ctx;

  setUp(() async {
    // An imported room opens through its password prompt, which looks up a
    // remembered password.
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

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
    // The radio must accept the contact's own next advert.
    expect(c.advertTimes.single, 0);
  });

  testWidgets('a key already heard on air imports what its advert said',
      (tester) async {
    await pumpHost(tester);
    final key = Uint8List.fromList(List.generate(32, (i) => 0x40 + i));
    c.heard = [
      Contact(
        publicKey: key,
        name: 'Summit Room',
        type: advTypeRoom,
        pathLength: -1,
        path: Uint8List(0),
        pathHashSize: 2,
        latitude: 36.9,
        longitude: -121.9,
        lastSeen: DateTime(2026, 10, 24),
      ),
    ];
    final hex = c.heard.single.publicKeyHex;

    ContactImportHelper.importFromScannedData(
      ctx,
      'meshcore://contact/add?name=Other&public_key=$hex&type=1',
    );
    await tester.pump();

    expect(c.imported.single.name, 'Summit Room');
    expect(c.imported.single.type, advTypeRoom);
    expect(c.imported.single.latitude, 36.9);

    // No password remembered: the room asks for one before opening.
    await tester.pumpAndSettle();
    expect(find.byType(RoomLoginDialog), findsOneWidget);
  });
}
