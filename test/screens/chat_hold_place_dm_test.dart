import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/screens/chat_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// The direct-message and room screen keeps its place by row number too, as
// the channel screen did (see chat_hold_place_test.dart): each message
// arriving at the bottom moved a reader above the newest one row.
class _Radio extends MeshCoreConnector {
  final posts = StreamController<List<Message>>.broadcast();
  List<Message> latest = const [];

  _Radio() {
    posts.stream.listen((m) => latest = m);
  }

  @override
  bool get isConnected => true;

  @override
  Stream<List<Message>> watchConversation(
    Contact contact, {
    int limit = 200,
  }) async* {
    if (latest.isNotEmpty) yield latest;
    yield* posts.stream;
  }
}

final _start = DateTime(2026, 10, 30, 8);
final _peerKey = Uint8List.fromList(List.generate(32, (i) => 0x5B + i));
final _roomKey = Uint8List.fromList(List.generate(32, (i) => 0x40 + i));
final _authorKey = Uint8List.fromList(List.generate(32, (i) => 0x60 + i));

Contact _contact(Uint8List key, int type) => Contact(
      publicKey: key,
      name: type == advTypeRoom ? 'Room' : 'Peer',
      type: type,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: _start,
    );

Message _dm(int i, {bool outgoing = false, String? text, String? id}) =>
    Message(
      senderKey: _peerKey,
      text: text ?? 'post $i',
      timestamp: _start.add(Duration(minutes: i)),
      isOutgoing: outgoing,
      status: MessageStatus.sent,
      messageId: id ?? 'd$i',
    );

Message _roomPost(int i, {String? text}) => Message(
      senderKey: _roomKey,
      text: text ?? 'post $i',
      timestamp: _start.add(Duration(minutes: i)),
      isOutgoing: false,
      status: MessageStatus.sent,
      messageId: 'r$i',
      fourByteRoomContactKey: _authorKey.sublist(0, 4),
    );

Finder get _list => find.byType(ScrollablePositionedList);

Rect? _row(WidgetTester tester, Finder inRow) {
  final row = find.ancestor(
    of: inRow,
    matching: find.byType(SizeChangedLayoutNotifier),
  );
  return row.evaluate().isEmpty ? null : tester.getRect(row.first);
}

/// The post highest on screen with its whole row inside the list: the one
/// a reader's eye is on.
int _read(WidgetTester tester) {
  final view = tester.getRect(_list);
  int? highest;
  var top = double.infinity;
  for (var i = 100; i <= 320; i++) {
    final r = _row(tester, find.text('post $i'));
    if (r == null || r.top < view.top + 20 || r.bottom > view.bottom) continue;
    if (r.top < top) {
      top = r.top;
      highest = i;
    }
  }
  return highest!;
}

void _expectStill(WidgetTester tester, Finder inRow, double was, String when) {
  final now = _row(tester, inRow);
  expect(now, isNotNull, reason: 'the row read is gone $when');
  expect(now!.top - was, closeTo(0, 1), reason: 'the row read moved $when');
}

void _expectNewestShown(WidgetTester tester, String text) {
  final row = _row(tester, find.text(text));
  expect(row, isNotNull, reason: '$text was not built');
  expect(
    row!.bottom,
    lessThan(tester.getRect(_list).bottom + 0.5),
    reason: '$text hangs below the list',
  );
  expect(_jumpButtonScale(tester), 0.0, reason: 'the jump-down button shows');
}

double _jumpButtonScale(WidgetTester tester) => tester
    .widget<AnimatedScale>(find.ancestor(
      of: find.byType(FloatingActionButton),
      matching: find.byType(AnimatedScale),
    ))
    .scale;

Future<void> _settle(WidgetTester tester) async {
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

/// The rows just posted reach the screen, with no frame drawn yet.
Future<void> _deliver(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.idle();
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  /// A full watched window of a DM: each new row drops the oldest.
  List<Message> window(int newest, {Map<int, Message> swap = const {}}) => [
        for (var i = newest - 199; i <= newest; i++) swap[i] ?? _dm(i),
      ];

  // The owner's phone: nine rows of one line on screen.
  Future<_Radio> open(
    WidgetTester tester,
    List<Message> first, {
    Contact? contact,
    int? unread,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.625;
    addTearDown(tester.view.reset);
    final radio = _Radio()..latest = first;
    addTearDown(radio.posts.close);
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ChatScreen(
            contact: contact ?? _contact(_peerKey, advTypeChat),
            unreadCount: unread,
          ),
        ),
      ),
    );
    await _settle(tester);
    return radio;
  }

  /// Opens a full window and scrolls up about a screen.
  Future<_Radio> openAndReadUp(
    WidgetTester tester, {
    List<Message>? first,
    Contact? contact,
    double by = 900,
  }) async {
    final radio = await open(tester, first ?? window(299), contact: contact);
    await tester.drag(_list, Offset(0, by));
    await _settle(tester);
    return radio;
  }

  group('a reader above the newest message keeps the row read in place', () {
    testWidgets('as messages arrive, one after the other', (tester) async {
      final radio = await openAndReadUp(tester);
      final read = find.text('post ${_read(tester)}');
      final was = _row(tester, read)!.top;
      for (var n = 300; n < 320; n++) {
        radio.posts.add(window(n));
        await _settle(tester);
        _expectStill(tester, read, was, 'after post $n arrived');
      }
    });

    testWidgets('in every frame of an arrival', (tester) async {
      final radio = await openAndReadUp(tester);
      final read = find.text('post ${_read(tester)}');
      final was = _row(tester, read)!.top;
      radio.posts.add(window(300));
      await _deliver(tester);
      for (var frame = 1; frame <= 4; frame++) {
        await tester.pump();
        _expectStill(tester, read, was, 'in frame $frame of the arrival');
      }
    });

    testWidgets('when five arrive at once', (tester) async {
      final radio = await openAndReadUp(tester);
      final read = find.text('post ${_read(tester)}');
      final was = _row(tester, read)!.top;
      radio.posts.add(window(304));
      await _settle(tester);
      _expectStill(tester, read, was, 'after five posts arrived together');
    });

    testWidgets('when a late message sorts in below it', (tester) async {
      final radio = await openAndReadUp(tester);
      final read = find.text('post ${_read(tester)}');
      final was = _row(tester, read)!.top;
      final late = window(299).sublist(1)
        ..insert(197, _dm(297, text: 'late one', id: 'late'));
      radio.posts.add(late);
      await _settle(tester);
      _expectStill(tester, read, was, 'after a late post landed below');
    });

    testWidgets('opened on NEW MESSAGES and not touched', (tester) async {
      final radio = await open(tester, window(299), unread: 15);
      final line = find.text('NEW MESSAGES');
      final was = _row(tester, line)!.top;
      for (var n = 300; n <= 302; n++) {
        radio.posts.add(window(n));
        await _settle(tester);
        _expectStill(tester, line, was, 'after post $n arrived');
      }
    });

    testWidgets('in a room, as posts arrive and file in', (tester) async {
      List<Message> room(int newest) =>
          [for (var i = newest - 199; i <= newest; i++) _roomPost(i)];
      final radio = await openAndReadUp(
        tester,
        first: room(299),
        contact: _contact(_roomKey, advTypeRoom),
      );
      final read = find.text('post ${_read(tester)}');
      final was = _row(tester, read)!.top;
      for (var n = 300; n <= 302; n++) {
        radio.posts.add(room(n));
        await _settle(tester);
        _expectStill(tester, read, was, 'after post $n arrived');
      }
      // A post the room held back files in above the newest.
      final filed = room(302).sublist(1)
        ..insert(198, _roomPost(301, text: 'held back'));
      radio.posts.add(filed);
      await _settle(tester);
      _expectStill(tester, read, was, 'after a held-back post filed in');
    });
  });

  // Holding a row in place is a jump to where it already is, and a jump
  // stops a scroll and replaces a jump asked for a moment earlier.
  group('holding a row in place leaves alone', () {
    testWidgets('a drag in progress', (tester) async {
      final radio = await openAndReadUp(tester);
      final read = find.text('post ${_read(tester)}');
      final finger = await tester.startGesture(tester.getCenter(_list));
      await finger.moveBy(const Offset(0, kDragSlopDefault + 40));
      await tester.pump();
      radio.posts.add(window(300));
      await _deliver(tester);
      await tester.pump();
      await tester.pump();
      final dragFrom = _row(tester, read)!.top;
      await finger.moveBy(const Offset(0, 60));
      await tester.pump();
      expect(
        _row(tester, read)!.top - dragFrom,
        closeTo(60, 1),
        reason: 'the arrival took the list from the finger',
      );
      await finger.up();
      await _settle(tester);
    });

    testWidgets('a fling in progress', (tester) async {
      final radio = await openAndReadUp(tester);
      await tester.fling(_list, const Offset(0, 300), 3000);
      for (var i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final atArrival = _read(tester);
      radio.posts.add(window(300));
      await _deliver(tester);
      for (var i = 0; i < 14; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        atArrival - _read(tester),
        greaterThan(2),
        reason: 'the arrival stopped the fling',
      );
      await _settle(tester);
    });

    testWidgets('the glide to the bottom', (tester) async {
      final radio = await openAndReadUp(tester, by: 200);
      expect(_jumpButtonScale(tester), 1.0);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump(const Duration(milliseconds: 100));
      radio.posts.add(window(300));
      await _deliver(tester);
      await _settle(tester);
      _expectNewestShown(tester, 'post 300');
    });

    testWidgets('a jump down tapped as a message arrives', (tester) async {
      final radio = await openAndReadUp(tester, by: 3000);
      await tester.tap(find.byType(FloatingActionButton));
      radio.posts.add(window(300));
      await _deliver(tester);
      await _settle(tester);
      _expectNewestShown(tester, 'post 300');
    });

    testWidgets('a quote tapped in a room as a post arrives', (tester) async {
      final author = pubKeyToHex(_authorKey.sublist(0, 4)).toUpperCase();
      final swap = {
        110: _roomPost(110, text: 'way back when'),
        290: _roomPost(290, text: '@[$author]\n>way back w..\nmy answer'),
      };
      List<Message> room(int newest) => [
            for (var i = newest - 199; i <= newest; i++)
              swap[i] ?? _roomPost(i),
          ];
      final radio = await openAndReadUp(
        tester,
        first: room(299),
        contact: _contact(_roomKey, advTypeRoom),
        by: 500,
      );
      // The quote shows the original's text, so its neighbour tells where
      // the list is.
      expect(find.text('post 111'), findsNothing);
      await tester.tap(find.text('Reply to $author'));
      // The chat's double-tap holds a tap this long. No frame is drawn, so
      // the scroll to the original is asked for and not yet begun.
      await tester.binding.delayed(const Duration(milliseconds: 400));
      await _deliver(tester);
      radio.posts.add(room(300));
      await _deliver(tester);
      await _settle(tester);
      expect(find.text('post 111'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('our send, with a message arriving right behind it',
        (tester) async {
      final radio = await openAndReadUp(tester);
      final mine = {300: _dm(300, outgoing: true)};
      radio.posts.add(window(300, swap: mine));
      await _deliver(tester);
      // The frame that asks for the jump to our send, not the one showing it.
      await tester.pump();
      radio.posts.add(window(301, swap: mine));
      await _deliver(tester);
      await _settle(tester);
      _expectNewestShown(tester, 'post 301');
    });

    testWidgets('following the newest, once dragged back down', (tester) async {
      final radio = await openAndReadUp(tester);
      radio.posts.add(window(300));
      await _settle(tester);
      radio.posts.add(window(301));
      await _settle(tester);
      await tester.drag(_list, const Offset(0, -3000));
      await _settle(tester);
      _expectNewestShown(tester, 'post 301');
      radio.posts.add(window(302));
      await _settle(tester);
      _expectNewestShown(tester, 'post 302');
    });

    testWidgets('a change to rows already there', (tester) async {
      final radio = await openAndReadUp(tester);
      final read = find.text('post ${_read(tester)}');
      final was = _row(tester, read)!.top;
      radio.posts.add(window(299));
      await _settle(tester);
      _expectStill(tester, read, was, 'after a status change');
    });
  });
}
