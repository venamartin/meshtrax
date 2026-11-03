import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/services/notification_service.dart';

// Tapping notification after notification opened a new page each time, so
// Back stepped through the same channel again and again (owner,
// 2026-11-03). A tapped chat now takes the place of the chats on top, as in
// other messaging apps; other pages stay where they are.

/// A page; a chat one adds itself to [NotificationService.chatRoutes] the
/// way the chat screens do.
class _Page extends StatefulWidget {
  const _Page(this.name, {this.chat = false});

  final String name;
  final bool chat;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> {
  Route<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.chat) NotificationService.chatRoutes.add(_route = ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    NotificationService.chatRoutes.remove(_route);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(body: Text(widget.name));
}

void main() {
  final key = GlobalKey<NavigatorState>();
  NavigatorState nav() => key.currentState!;

  tearDown(NotificationService.chatRoutes.clear);

  Future<void> start(WidgetTester tester, {bool chatHome = false}) =>
      tester.pumpWidget(MaterialApp(
          navigatorKey: key, home: _Page('Home', chat: chatHome)));

  Future<void> tap(WidgetTester tester, String chat) async {
    NotificationService.openChat(nav(), _Page(chat, chat: true));
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester) async {
    nav().pop();
    await tester.pumpAndSettle();
  }

  testWidgets('taps one after another never stack chats; Back goes home',
      (tester) async {
    await start(tester);
    await tap(tester, 'Public');
    await tap(tester, 'Public');
    await tap(tester, 'Public');
    expect(find.text('Public'), findsOneWidget);

    await back(tester);
    expect(find.text('Home'), findsOneWidget);
    expect(NotificationService.chatRoutes, isEmpty);
  });

  testWidgets('a chat opened by hand gives way to the tapped one',
      (tester) async {
    await start(tester);
    nav().push(MaterialPageRoute(builder: (_) => const _Page('A', chat: true)));
    await tester.pumpAndSettle();
    await tap(tester, 'B');
    expect(find.text('B'), findsOneWidget);

    await back(tester);
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('a page that is not a chat stays where it is', (tester) async {
    await start(tester);
    nav().push(MaterialPageRoute(builder: (_) => const _Page('A', chat: true)));
    nav().push(MaterialPageRoute(builder: (_) => const _Page('Settings')));
    await tester.pumpAndSettle();
    await tap(tester, 'B');

    await back(tester);
    expect(find.text('Settings'), findsOneWidget);
    await back(tester);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('the first page is never taken away', (tester) async {
    await start(tester, chatHome: true);
    await tap(tester, 'B');

    await back(tester);
    expect(find.text('Home'), findsOneWidget);
  });
}
