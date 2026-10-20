import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/screens/companion_cli_screen.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Remote CLI to another 1.18 companion: our command goes out as txt_type 3
// and the answer comes back as a txt_type 1 DM carrying our token. A
// companion also chats, and a plain DM landing while the command is
// pending must not be taken for its answer.
class _Radio extends MeshCoreConnector {
  final commands = <String>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    if (data[0] != cmdSendTxtMsg || data[1] != txtTypeCliCommand) return;
    var text = utf8.decode(data.sublist(13));
    if (text.endsWith('\u0000')) text = text.substring(0, text.length - 1);
    commands.add(text);
    final token = text.substring(0, 3);
    scheduleMicrotask(() {
      handleFrameForTest(_dm(txtTypePlain, 'are you there?'));
      handleFrameForTest(_dm(txtTypeCliData, '$token> v1.18.0'));
    });
  }
}

final _peerKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));

Uint8List _dm(int txtType, String text) {
  final w = BytesBuilder();
  w.add([respCodeContactMsgRecvV3, 0x14, 0, 0]);
  w.add(_peerKey.sublist(0, 6));
  w.add([0xFF, txtType]);
  w.add(Uint8List(4));
  w.add(utf8.encode(text));
  return w.toBytes();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  testWidgets('a chat message mid-command is not taken for the reply',
      (tester) async {
    final radio = _Radio();
    final peer = Contact(
      publicKey: _peerKey,
      name: 'WHALE',
      type: advTypeChat,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime(2026, 10, 15),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<MeshCoreConnector>.value(
        value: radio,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: CompanionCliScreen(contact: peer),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'ver');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(radio.commands.single, endsWith('|ver'));
    expect(find.text('> v1.18.0'), findsOneWidget);
    expect(find.text('are you there?'), findsNothing);
  });
}
