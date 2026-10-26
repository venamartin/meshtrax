import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/widgets/routing_dialog.dart';

class _FakeMeshCoreConnector extends MeshCoreConnector {
  _FakeMeshCoreConnector({
    required this.contact,
    this.connected = false,
    this.saved = true,
  });

  Contact contact;
  final bool connected;
  bool saved;
  int setPathOverrideCalls = 0;
  int? lastPathLen;
  Uint8List? lastPathBytes;
  int getContactsCalls = 0;
  int importCalls = 0;

  @override
  bool get isConnected => connected;

  @override
  int get pathHashByteWidth => 2;

  @override
  List<Contact> get contacts => saved ? [contact] : [];

  @override
  List<Contact> get allContacts => [contact];

  @override
  Future<bool> importDiscoveredContact(
    Contact contact, {
    int? lastAdvertEpochSeconds,
  }) async {
    importCalls++;
    saved = true;
    notifyListeners();
    return true;
  }

  @override
  Future<void> getContacts({int? since, bool preserveExisting = false}) async {
    getContactsCalls++;
    // Simulate the contact sync notifying listeners while dialogs are open.
    notifyListeners();
  }

  @override
  Future<void> setPathOverride(
    Contact contact, {
    int? pathLen,
    Uint8List? pathBytes,
  }) async {
    setPathOverrideCalls++;
    lastPathLen = pathLen;
    lastPathBytes = pathBytes;
    this.contact = this.contact.copyWith(
      pathOverride: pathLen,
      pathOverrideBytes: pathBytes,
      clearPathOverride: pathLen == null && pathBytes == null,
    );
    notifyListeners();
  }

  @override
  Future<void> clearContactPath(Contact contact) async {}
}

Contact _repeater() {
  final pubKey = Uint8List.fromList(List<int>.generate(32, (i) => i + 1));
  return Contact(
    publicKey: pubKey,
    name: 'MADONNA',
    type: 2, // repeater
    pathLength: 2,
    path: Uint8List.fromList([0xA2, 0x77, 0xBE, 0xEF]),
    pathHashSize: 2,
    lastSeen: DateTime.now(),
  );
}

Widget _host(MeshCoreConnector connector, Contact contact) {
  return ChangeNotifierProvider<MeshCoreConnector>.value(
    value: connector,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => RoutingDialog.show(context, contact: contact),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openCustomPathDialog(WidgetTester tester) async {
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  expect(find.text('Routing'), findsOneWidget);

  // The 2-byte fixture must read as two hops, never A2,77,BE,EF.
  expect(find.textContaining('A277,BEEF'), findsOneWidget);

  await tester.tap(find.text('Custom path'));
  await tester.pumpAndSettle();
  expect(find.text('Enter Custom Path'), findsOneWidget);
}

void main() {
  testWidgets('custom path dialog: Set Path applies and closes', (
    tester,
  ) async {
    final contact = _repeater();
    final connector = _FakeMeshCoreConnector(contact: contact);
    await tester.pumpWidget(_host(connector, contact));

    await _openCustomPathDialog(tester);

    await tester.enterText(find.byType(TextField), 'A277');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Set Path'));
    await tester.pumpAndSettle();

    expect(find.text('Enter Custom Path'), findsNothing,
        reason: 'Set Path must close the dialog');
    expect(connector.setPathOverrideCalls, 1);
    expect(connector.lastPathBytes, [0xA2, 0x77]);
  });

  testWidgets('custom path dialog: Cancel closes', (tester) async {
    final contact = _repeater();
    final connector = _FakeMeshCoreConnector(contact: contact);
    await tester.pumpWidget(_host(connector, contact));

    await _openCustomPathDialog(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Enter Custom Path'), findsNothing,
        reason: 'Cancel must close the dialog');
    expect(connector.setPathOverrideCalls, 0);
  });

  testWidgets(
    'unsaved discovered repeater: routing change imports it first, then applies',
    (tester) async {
      final contact = _repeater();
      final connector = _FakeMeshCoreConnector(
        contact: contact,
        connected: true,
        saved: false,
      );
      await tester.pumpWidget(_host(connector, contact));

      await _openCustomPathDialog(tester);

      await tester.enterText(find.byType(TextField), 'A277');
      await tester.tap(find.text('Set Path'));
      await tester.pumpAndSettle();

      expect(find.text('Enter Custom Path'), findsNothing);
      expect(connector.importCalls, 1,
          reason: 'repeater must be saved before the override can stick');
      expect(connector.setPathOverrideCalls, 1);
      expect(connector.lastPathBytes, [0xA2, 0x77]);
    },
  );

  testWidgets(
    'unsaved discovered repeater: flood mode imports it first, then applies',
    (tester) async {
      final contact = _repeater();
      final connector = _FakeMeshCoreConnector(
        contact: contact,
        connected: true,
        saved: false,
      );
      await tester.pumpWidget(_host(connector, contact));

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Always flood'));
      await tester.pumpAndSettle();

      expect(connector.importCalls, 1);
      expect(connector.setPathOverrideCalls, 1);
      expect(connector.lastPathLen, -1);
    },
  );

  testWidgets(
    'custom path dialog survives connector rebuilds while open (connected)',
    (tester) async {
      final contact = _repeater();
      final connector = _FakeMeshCoreConnector(contact: contact, connected: true);
      await tester.pumpWidget(_host(connector, contact));

      await _openCustomPathDialog(tester);

      // Contact sync pushes while the dialog is open.
      connector.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.text('Enter Custom Path'), findsOneWidget,
          reason: 'exactly one dialog instance expected');

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Enter Custom Path'), findsNothing);
    },
  );
}
