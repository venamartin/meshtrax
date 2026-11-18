import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/trax.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/trax_dialogs.dart';

// TRAX mode's questions come over whatever screen is open, and again from a
// TRAX notification's tap while they still fit, never stacked on an open
// copy: a phone in a pocket may have had one put up meanwhile.
class _Radio extends MeshCoreConnector {
  _Radio({this.repeat = false});

  bool repeat;

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
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  /// TRAX mode over a home screen; the test disposes [TraxService], whose
  /// timer must not outlive it.
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
    return (trax, TraxQuestions(trax, key));
  }

  final stillOn = find.textContaining('still in TRAX mode');
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
}
