import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/widgets/mention_composer.dart';

Contact contact(String name, {int type = advTypeChat}) => Contact(
      publicKey: Uint8List.fromList(List.filled(32, name.length)),
      name: name,
      type: type,
      pathLength: 0,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime.now(),
    );

Widget host(Widget child) => MaterialApp(
      home: Scaffold(body: Column(children: [child])),
    );

void main() {
  testWidgets('the panel lists every row and stays within 200 px',
      (tester) async {
    await tester.pumpWidget(host(MentionsPanel(
      itemCount: 12,
      itemBuilder: (_, i) => ListTile(title: Text('row $i')),
    )));
    expect(find.byType(ListTile), findsWidgets);
    expect(tester.getSize(find.byType(MentionsPanel)).height,
        lessThanOrEqualTo(200 + 16));
    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('the mention picker still hands back the tapped contact',
      (tester) async {
    Contact? picked;
    final contacts = [contact('Alice'), contact('Bob 🦅')];
    await tester.pumpWidget(host(MentionsOverlay(
      contacts: contacts,
      onSelect: (c) => picked = c,
    )));
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('🦅'), findsOneWidget, reason: 'emoji avatar');
    expect(find.byIcon(Icons.chat_bubble), findsOneWidget,
        reason: 'type icon when the name has no emoji');
    await tester.tap(find.text('Bob 🦅'));
    expect(picked, same(contacts[1]));
  });
}
