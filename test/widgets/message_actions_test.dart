import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/widgets/message_actions.dart';

void main() {
  late List<String> picked;

  List<MessageAction> actions() => [
        MessageAction(Icons.reply, 'Reply', () => picked.add('reply')),
        MessageAction(Icons.copy, 'Copy', () => picked.add('copy')),
      ];

  Future<void> pump(WidgetTester tester, {required bool rightClick}) async {
    picked = [];
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => ContextMenuRegion(
              onContextMenu: rightClick
                  ? (at) => showMessageActions(context, actions(), position: at)
                  : null,
              child: GestureDetector(
                onLongPress: () => showMessageActions(context, actions()),
                // The bubble text: selectable on desktop, where it takes
                // right-clicks itself; plain on phones.
                child: rightClick
                    ? const SelectableText('a message with text')
                    : const Text('a message with text'),
              ),
            ),
          ),
        ),
      ),
    ));
  }

  testWidgets('a right-click on the text opens the menu at the pointer',
      (tester) async {
    await pump(tester, rightClick: true);
    final at = tester.getCenter(find.byType(SelectableText));
    final mouse = await tester.startGesture(
      at,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await mouse.up();
    await tester.pumpAndSettle();

    expect(find.byType(PopupMenuItem<MessageAction>), findsNWidgets(2));
    final menuTop = tester.getTopLeft(find.text('Reply'));
    expect((menuTop.dy - at.dy).abs(), lessThan(60));

    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(picked, ['copy']);
  });

  testWidgets('a left-click opens nothing', (tester) async {
    await pump(tester, rightClick: true);
    final mouse = await tester.startGesture(
      tester.getCenter(find.byType(SelectableText)),
      kind: PointerDeviceKind.mouse,
    );
    await mouse.up();
    await tester.pumpAndSettle();
    expect(find.byType(PopupMenuItem<MessageAction>), findsNothing);
  });

  testWidgets('a long-press opens the sheet, with Cancel', (tester) async {
    await pump(tester, rightClick: false);
    await tester.longPress(find.text('a message with text'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Reply'));
    await tester.pumpAndSettle();
    expect(picked, ['reply']);
    expect(find.byType(BottomSheet), findsNothing);
  });
}
