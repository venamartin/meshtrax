import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/widgets/composer_attach_tray.dart';

void main() {
  group('isMentionOnly', () {
    test('an empty box or one holding only mentions', () {
      expect(isMentionOnly(''), isTrue);
      expect(isMentionOnly('   '), isTrue);
      expect(isMentionOnly('@[Bob] '), isTrue);
      expect(isMentionOnly('@[Bob] @[Ann 🐧]'), isTrue);
    });

    test('not once there is a message', () {
      expect(isMentionOnly('hi'), isFalse);
      expect(isMentionOnly('@[Bob] hi'), isFalse);
      expect(isMentionOnly('@Bob'), isFalse);
    });
  });

  group('afterMention', () {
    test('a tray item goes after the mention typed', () {
      expect(afterMention('@[Bob] ', 'g:abc'), '@[Bob] g:abc');
      expect(
        afterMention('@[Bob] @[Ann]', 'location: 1,2'),
        '@[Bob] @[Ann] location: 1,2',
      );
    });

    test('otherwise it replaces the text, as before', () {
      expect(afterMention('', 'g:abc'), 'g:abc');
      expect(afterMention('draft', 'g:abc'), 'g:abc');
    });
  });

  group('ComposerActionButton', () {
    Future<void> pump(WidgetTester tester, String text) async {
      final controller = TextEditingController(text: text);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ComposerActionButton(
              controller: controller,
              trayOpen: false,
              onToggleTray: () {},
              onSend: () {},
              sendTooltip: 'Send',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('offers the tray while the box holds only a mention', (
      tester,
    ) async {
      await pump(tester, '@[Bob] ');
      expect(find.byKey(const ValueKey('attach')), findsOneWidget);
      expect(find.byKey(const ValueKey('send')), findsNothing);
    });

    testWidgets('offers Send once there is a message', (tester) async {
      await pump(tester, '@[Bob] hi');
      expect(find.byKey(const ValueKey('send')), findsOneWidget);
      expect(find.byKey(const ValueKey('attach')), findsNothing);
    });
  });
}
