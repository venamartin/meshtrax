import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/screens/channel_chat_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/mention_composer.dart';

// The owner, 2026-11-17: typing @ in a channel made the keyboard go away.
// The @ list and the composer below it were both Consumer<MeshCoreConnector>,
// so when the list appeared Flutter gave the composer's element to the list
// and built a new composer, whose text box had never had the focus.
class _Radio extends MeshCoreConnector {
  @override
  bool get isConnected => true;

  @override
  List<Channel> get channels => const [];

  @override
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) =>
      Stream.value([
        ChannelMessage(
          senderName: 'Ridge Walker',
          text: 'Is the ridge repeater back up?',
          timestamp: DateTime(2026, 11, 16, 9),
          isOutgoing: false,
          status: ChannelMessageStatus.sent,
          channelIndex: 1,
          messageId: 'p0',
        ),
      ]);
}

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  // The connector gathers its change notices before it sends one.
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  testWidgets('typing @ in a channel keeps the keyboard up', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final radio = _Radio();
    addTearDown(radio.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: AppSettingsService()),
          ChangeNotifierProvider.value(value: UiViewStateService()),
          ChangeNotifierProvider.value(value: ChatTextScaleService()),
          ChangeNotifierProvider.value(value: PathGraphService()),
          ChangeNotifierProvider.value(value: MessageRetryService()),
        ],
        child: MaterialApp(
          navigatorObservers: [NotificationService.routeObserver],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ChannelChatScreen(
            channel: Channel(index: 1, name: '#test', psk: Uint8List(16)),
          ),
        ),
      ),
    );
    await _settle(tester);

    final composer = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'Type a message...',
    );
    await tester.showKeyboard(composer);
    final box = tester.state<EditableTextState>(
      find.descendant(of: composer, matching: find.byType(EditableText)),
    );

    for (final typed in ['@', '@Ri', '@Ridge W']) {
      tester.testTextInput.updateEditingValue(TextEditingValue(
        text: typed,
        selection: TextSelection.collapsed(offset: typed.length),
      ));
      await tester.pump();

      expect(find.byType(MentionsOverlay), findsOneWidget, reason: typed);
      expect(
        tester.state<EditableTextState>(
          find.descendant(of: composer, matching: find.byType(EditableText)),
        ),
        same(box),
        reason: 'the same text box after "$typed", not a new one',
      );
      expect(box.widget.focusNode.hasFocus, isTrue, reason: typed);
      expect(tester.testTextInput.isVisible, isTrue,
          reason: 'the keyboard is still up after "$typed"');
    }

    await tester.tap(find.descendant(
      of: find.byType(MentionsOverlay),
      matching: find.text('Ridge Walker'),
    ));
    await tester.pump();
    expect(find.byType(MentionsOverlay), findsNothing);
    expect(box.widget.controller.text, '@[Ridge Walker] ');
    expect(box.widget.focusNode.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);
    // The scroll the screen starts when the composer takes the focus.
    await _settle(tester);
  });
}
