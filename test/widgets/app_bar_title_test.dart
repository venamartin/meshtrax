import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/widgets/app_bar.dart';

// The title has first claim on the bar; the readouts give way in a fixed
// order: the repeater line, the battery text, the battery, the signal
// (owner, 2026-10-27). Measured in the test font, where every glyph is as
// wide as its font size.
class _Radio extends MeshCoreConnector {
  @override
  bool get isConnected => true;
  @override
  String? get selfName => 'GWQ';
  @override
  int? get batteryMillivolts => 4100;
  @override
  int? get batteryPercent => 92;
  @override
  int? get currentSf => 7;
  @override
  bool get isDiscovering => false;
  @override
  List<DirectRepeater> get directRepeaters => [
    DirectRepeater(
      pubkeyPrefix: Uint8List.fromList([0xA2, 0x77]),
      snr: 12.0,
      lastUpdated: DateTime.now().subtract(const Duration(seconds: 22)),
    ),
  ];
}

void main() {
  /// The Chats bar: the radio's name, the readouts, three action buttons.
  Future<void> pump(WidgetTester tester, double width) async {
    tester.view
      ..physicalSize = Size(width, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ChangeNotifierProvider<MeshCoreConnector>.value(
        value: _Radio(),
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: const AppBarTitle('GWQ', subtitle: false),
              centerTitle: true,
              actions: [
                for (var i = 0; i < 3; i++)
                  IconButton(icon: const Icon(Icons.circle), onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool titleClipped(WidgetTester tester) =>
      tester.renderObject<RenderParagraph>(find.text('GWQ')).didExceedMaxLines;

  testWidgets('wide: every readout in full', (tester) async {
    await pump(tester, 700);
    expect(titleClipped(tester), isFalse);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('12.0 dB'), findsOneWidget);
    expect(find.textContaining('1: A277'), findsOneWidget);
  });

  testWidgets('narrower: the repeater line goes first', (tester) async {
    await pump(tester, 440);
    expect(titleClipped(tester), isFalse);
    expect(find.text('92%'), findsOneWidget);
    expect(find.text('12.0 dB'), findsOneWidget);
    expect(find.textContaining('A277'), findsNothing);
  });

  testWidgets('a phone: the battery goes, the signal and the title stay',
      (tester) async {
    await pump(tester, 360);
    expect(titleClipped(tester), isFalse);
    expect(find.text('92%'), findsNothing);
    expect(find.text('12.0 dB'), findsOneWidget);
    expect(find.textContaining('A277'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
