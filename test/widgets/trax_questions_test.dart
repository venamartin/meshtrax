import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/radio_settings.dart';
import 'package:meshtrax/models/trax.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/trax_dialogs.dart';
import 'package:meshtrax/widgets/trax_guide.dart';

// TRAX mode's questions come over whatever screen is open, and again from a
// TRAX notification's tap while they still fit, never stacked on an open
// copy: a phone in a pocket may have had one put up meanwhile.
class _Radio extends MeshCoreConnector {
  _Radio({this.repeat = false});

  bool repeat;
  final sent = <Uint8List>[];
  final incoming =
      StreamController<
        ({ChannelMessage message, bool fromBacklog})
      >.broadcast();

  @override
  Stream<({ChannelMessage message, bool fromBacklog})> get channelMessagesIn =>
      incoming.stream;
  @override
  List<Channel> get channels => [_trip];
  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async => sent.add(data);
  @override
  bool get isConnected => true;
  @override
  bool? get clientRepeat => repeat;
  @override
  int? get currentFreqHz => repeat ? 918000 : 910525;
  @override
  int? get currentBwHz => 62500;
  @override
  int? get currentSf => 7;
  @override
  int? get currentCr => 5;
  @override
  int? get firmwareVerCode => 14;
  @override
  String get selfPublicKeyHex => '11' * 32;
  @override
  Future<List<({int lowerKhz, int upperKhz})>?>
  getAllowedRepeatFrequencies() async => null;

  void hear(String sender, String text) => incoming.add((
    message: ChannelMessage(
      senderKey: null,
      senderName: sender,
      text: text,
      timestamp: DateTime.now(),
      isOutgoing: false,
      channelIndex: _trip.index,
    ),
    fromBacklog: false,
  ));
}

/// A radio that takes the TRAX settings when asked, as companion 1.18 does.
class _SwitchingRadio extends _Radio {
  @override
  Future<bool> waitUntilSynced({
    Duration timeout = const Duration(seconds: 90),
  }) async => true;
  @override
  Future<List<({int lowerKhz, int upperKhz})>?>
  getAllowedRepeatFrequencies() async => [(lowerKhz: 918000, upperKhz: 918000)];
  @override
  Future<bool> setRadioParams(
    int freqKhz,
    int bwHz,
    int sf,
    int cr, {
    bool? clientRepeat,
  }) async {
    repeat = clientRepeat ?? repeat;
    return true;
  }

  @override
  Future<bool> waitForRadio({
    Duration timeout = const Duration(seconds: 3),
  }) async => true;
  @override
  Future<void> sendSelfAdvert({bool flood = true}) async {}
  @override
  Future<void> refreshRadioSettings() async {}
}

final _trip = Channel(
  index: 1,
  name: 'Desert trip',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x40 + i)),
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  /// TRAX mode over a home screen, wired as the app wires it; the test
  /// disposes [TraxService], whose timer must not outlive it.
  Future<(TraxService, TraxQuestions)> pump(
    WidgetTester tester,
    _Radio radio,
  ) async {
    final trax = TraxService(radio);
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: key,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Text('Map')),
      ),
    );
    final questions = TraxQuestions(trax, key);
    trax.prompts.listen(questions.ask);
    return (trax, questions);
  }

  final stillOn = find.textContaining('Still in TRAX mode');
  final ago = DateTime.now().subtract(const Duration(minutes: 1));

  testWidgets('the trip\'s end reminder asks again, never on top of itself', (
    tester,
  ) async {
    final (trax, questions) = await pump(tester, _Radio(repeat: true));
    await trax.updateSetup(TraxSetup(until: ago));
    expect(questions.onTap('channel:1'), 'channel:1', reason: 'not TRAX\'s');

    // Put up at the end, with the phone in a pocket.
    questions.ask(const TraxStillOnPrompt());
    await tester.pumpAndSettle();
    expect(questions.onTap(NotificationService.traxEndedPayload), isNull);
    await tester.pumpAndSettle();
    expect(stillOn, findsOneWidget);

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(stillOn, findsNothing);
    questions.onTap(NotificationService.traxEndedPayload);
    await tester.pumpAndSettle();
    expect(stillOn, findsOneWidget, reason: 'asked again');
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    trax.dispose();
  });

  testWidgets('a reminder that no longer fits only opens the app', (
    tester,
  ) async {
    final radio = _Radio(repeat: true);
    final (trax, questions) = await pump(tester, radio);
    await trax.updateSetup(
      TraxSetup(until: DateTime.now().add(const Duration(hours: 1))),
    );
    expect(questions.onTap(NotificationService.traxEndedPayload), isNull);
    await tester.pumpAndSettle();
    expect(stillOn, findsNothing, reason: 'the trip got longer');

    await trax.updateSetup(TraxSetup(until: ago));
    radio.repeat = false;
    expect(questions.onTap(NotificationService.traxEndedPayload), isNull);
    await tester.pumpAndSettle();
    expect(stillOn, findsNothing, reason: 'the radio left TRAX mode');
    trax.dispose();
  });

  final on = TraxMessage.switching(
    until: DateTime.now().add(const Duration(days: 1)),
    preset: const LoRaParams(freqKhz: 918000, bwHz: 62500, sf: 7, cr: 5),
  ).toWire();
  final switchToo = find.textContaining('Switch too?');

  testWidgets('Switch too asks the member\'s question, once, and switches '
      'nothing', (tester) async {
    final radio = _Radio();
    final (trax, questions) = await pump(tester, radio);
    radio.hear('Ana', on);
    await tester.pumpAndSettle();
    expect(switchToo, findsOneWidget, reason: 'put up as it came');

    expect(questions.onTap('traxfollow:channel:1'), isNull);
    await tester.pumpAndSettle();
    expect(switchToo, findsOneWidget, reason: 'not stacked on itself');

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(switchToo, findsNothing);
    expect(questions.onTap('traxfollow:channel:1'), isNull);
    await tester.pumpAndSettle();
    expect(switchToo, findsOneWidget, reason: 'asked again');
    expect(radio.sent, isEmpty, reason: 'only its own button switches');
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    // Ana left again: her old button opens the chat instead.
    radio.hear('Ana', 'TRAX: off');
    await tester.pumpAndSettle();
    expect(questions.onTap('traxfollow:channel:1'), 'channel:1');
    await tester.pumpAndSettle();
    expect(switchToo, findsNothing);
    trax.dispose();
  });

  // Martin, 2026-11-26: "How TRAX works" after switching on, until "Don't
  // show this again": a friend who switches from a message learns it too.
  testWidgets('after Switch too, How TRAX works until "Don\'t show this '
      'again"', (tester) async {
    final radio = _SwitchingRadio();
    final (trax, _) = await pump(tester, radio);
    radio.hear('Ana', on);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Switch too'));
    await tester.pumpAndSettle();
    expect(trax.isOn, isTrue);
    expect(find.text('How TRAX works'), findsOneWidget);
    final dontShow = find.text("Don't show this again");
    await tester.scrollUntilVisible(dontShow, 200);
    await tester.tap(dontShow);
    await tester.pump();
    expect(PrefsManager.instance.getBool(TraxGuide.prefKey), isTrue);
    trax.dispose();
  });

  testWidgets('Leave too asks while this radio is on TRAX', (tester) async {
    final radio = _Radio(repeat: true);
    final (trax, questions) = await pump(tester, radio);
    final leaveToo = find.textContaining('Leave too?');
    radio.hear('Bo', 'TRAX: off');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(leaveToo, findsNothing);

    expect(questions.onTap('traxleave:mention:1:m1'), isNull);
    await tester.pumpAndSettle();
    expect(leaveToo, findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(
      questions.onTap('traxfollow:channel:1'),
      'channel:1',
      reason: 'a Switch too that no longer fits',
    );
    expect(questions.onTap('traxleave:channel:7'), 'channel:7');
    radio.repeat = false;
    expect(questions.onTap('traxleave:channel:1'), 'channel:1');
    await tester.pumpAndSettle();
    expect(leaveToo, findsNothing);
    trax.dispose();
  });
}
