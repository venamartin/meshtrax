import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/helpers/meshtrax_dm.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/widgets/byte_count_input.dart';
import 'package:meshtrax/widgets/meshtrax_dm_counter.dart';
import 'package:meshtrax/widgets/meshtrax_pill.dart';

// Owner, 2026-11-27: in the DM composer, "show where I stand while typing,
// and which way the message will go": bytes left of the packed text, live,
// against 126, with a MeshTrax mark while it fits.
void main() {
  const room = 126;
  late TextEditingController box;

  Future<void> pump(WidgetTester tester) async {
    box = TextEditingController();
    addTearDown(box.dispose);
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: ByteCountedTextField(
          maxBytes: 150,
          controller: box,
          counterBuilder: (context, text, counter) =>
              MeshTraxDmCounter(text: text, room: room, standard: counter),
        ),
      ),
    ));
  }

  int packed(String text) => MeshTraxDmText.pack(text).bytes.length;

  testWidgets('bytes left of the packed text, with the MeshTrax mark',
      (tester) async {
    await pump(tester);
    expect(find.byType(MeshTraxPill), findsNothing, reason: 'nothing typed');

    const text = 'Are you on the way home? The weather is turning.';
    box.text = text;
    await tester.pump();
    expect(find.byType(MeshTraxPill), findsOneWidget);
    expect(find.text('${room - packed(text)} left'), findsOneWidget);
    expect(room - packed(text), greaterThan(room - utf8.encode(text).length),
        reason: 'packed bytes, not characters or plain bytes');
  });

  testWidgets('text Smaz cannot shrink counts as its UTF-8 bytes',
      (tester) async {
    await pump(tester);
    box.text = 'Здравей';
    await tester.pump();
    expect(find.text('${room - 14} left'), findsOneWidget);
  });

  testWidgets('it follows every change, down and up', (tester) async {
    await pump(tester);
    final seen = <int>[];
    for (final text in ['th', 'the', 'the w', 'the', 'the weather']) {
      box.text = text;
      await tester.pump();
      seen.add(room - packed(text));
      expect(find.text('${seen.last} left'), findsOneWidget);
    }
    expect(seen[3], seen[1], reason: 'deleting gives the bytes back');
  });

  testWidgets('past the line: a standard message, with that way\'s counter',
      (tester) async {
    await pump(tester);
    // Nothing Smaz can shrink.
    final fits = List.generate(room, (i) => 'Q7#Z'[i % 4]).join();
    box.text = fits;
    await tester.pump();
    expect(find.text('0 left'), findsOneWidget);
    expect(find.byType(MeshTraxPill), findsOneWidget);

    box.text = '${fits}Q';
    await tester.pump();
    expect(find.byType(MeshTraxPill), findsNothing);
    expect(find.text('Too long for MeshTrax: goes as a standard message'),
        findsOneWidget);
    expect(find.text('${room + 1} / 150'), findsOneWidget);
  });

  testWidgets('without the builder the field is as it was', (tester) async {
    final plain = TextEditingController(text: 'hello');
    addTearDown(plain.dispose);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ByteCountedTextField(maxBytes: 150, controller: plain),
      ),
    ));
    expect(find.text('5 / 150'), findsOneWidget);
  });

  testWidgets('the mark under a sent message names the way it went',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Column(children: [
          SentWayMark(meshTrax: true),
          SentWayMark(meshTrax: false),
        ]),
      ),
    ));
    expect(find.text('MeshTrax'), findsOneWidget);
    expect(find.text('Standard message'), findsOneWidget);
  });
}
