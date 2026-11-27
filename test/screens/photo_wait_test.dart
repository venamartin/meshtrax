import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/screens/photo_send_screen.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// On a MeshCore frequency, the wait after the last photo through repeaters
// is told as the sender taps Photo, before picking anything (the owner,
// 2026-11-27: "the rules are enforced at the beginning. Not the end").

const _key = '77777777777777777777777777777777';

class _Radio extends MeshCoreConnector {
  _Radio(this.freqKhz);

  final int freqKhz;

  @override
  int? get currentFreqHz => freqKhz;

  @override
  String get selfPublicKeyHex => _key;

  @override
  bool isNearbyOnlyChannel(int channelIndex) => false;
}

final _channel = Channel(index: 1, name: 'Trip', psk: Uint8List(16));

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'photo_last_sent_via_${_key.substring(0, 16)}': DateTime.now()
          .subtract(const Duration(minutes: 3))
          .millisecondsSinceEpoch,
      'photo_last_sent_packets_${_key.substring(0, 16)}': 4,
    });
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<void> open(WidgetTester tester, _Radio radio) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<MeshCoreConnector>.value(
        value: radio,
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => PhotoSendScreen.open(context, _channel),
              child: const Text('Photo'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
  }

  testWidgets('after a 4-packet photo three minutes ago, Photo says so at '
      'once, and Close opens nothing', (tester) async {
    await open(tester, _Radio(910525));
    expect(
      find.text('Next photo through repeaters in 17 min'),
      findsOneWidget,
    );
    expect(find.textContaining('after a photo of 4 packets'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Zero hop'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(PhotoSendScreen), findsNothing);
  });
}
