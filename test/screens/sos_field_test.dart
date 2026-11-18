import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart' hide LatLng;

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/screens/channel_chat_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/chat_text_scale_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/sos_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/active_sos_bar.dart';
import 'package:meshtrax/widgets/active_sos_strip.dart';
import 'package:meshtrax/widgets/quick_switch_bar.dart';

import '../helpers/map_fakes.dart';

// Martin's field review, 2026-11-18, for desert trips with no cell service:
// Got it never fails silently, and my own SOS shows wherever I am.
final _trip = Channel(
  index: 1,
  name: '#trip',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x30 + i)),
);

final _annSos = ChannelMessage(
  messageId: 'ann0',
  senderName: 'Ann',
  text: const SosMessage(
    position: LatLng(36.46, -116.87),
    text: 'Broken leg',
  ).toWire(),
  timestamp: DateTime(2026, 11, 18, 14),
  isOutgoing: false,
  channelIndex: 1,
);

/// A radio with Ann's SOS in the trip chat, and what was sent to it.
class _Radio extends MeshCoreConnector {
  bool connected = true;
  final sent = <String>[];

  @override
  bool get isConnected => connected;
  @override
  List<Channel> get channels => [_trip];
  @override
  String? get selfName => 'GWQ';
  @override
  String prepareChannelOutboundText(int channelIndex, String text) => text;
  @override
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) => Stream.value([_annSos]);
  @override
  Future<List<ChannelMessage>> loadChannelMessagesFor(Channel channel) async =>
      [_annSos];
  @override
  Future<String?> sendChannelMessage(
    Channel channel,
    String text, {
    ChannelMessage? replyTarget,
  }) async {
    if (!connected) return null;
    sent.add(text);
    return 'mine${sent.length}';
  }
}

/// The SOS service with my own SOS as [show] puts it: nothing goes out.
class _MySos extends SosService {
  _MySos(super.connector);

  ActiveSos? mine;

  @override
  ActiveSos? get current => mine;

  void show(ActiveSos? sos) {
    mine = sos;
    notifyListeners();
  }
}

class _NoDownloads implements PackDownloader {
  @override
  Stream<PackDownload> get updates => const Stream.empty();
  @override
  List<PackDownload> get downloads => const [];
  @override
  Future<void> start(DownloadItem item) async {}
  @override
  Future<void> pause(String packId) async {}
  @override
  Future<void> resume(String packId) async {}
  @override
  Future<void> cancel(String packId) async {}
  @override
  Future<void> finish(String id, {String? error}) async {}
}

/// The chat's double-tap (zoom reset) holds every tap for this long.
Future<void> tapLands(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 400));

void main() {
  late Directory tmp;
  late MapPacksService maps;
  late _MySos sos;
  final cleared = <int>[];
  final annAlert = NotificationService.sosNotificationId(_trip.idKey, 'Ann');
  const notConnected = 'Not connected to a radio. Message not sent.';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    tmp = await Directory.systemTemp.createTemp('sosfield');
    maps = MapPacksService(
      manager: PackManager(Directory('${tmp.path}/packs')),
      downloader: _NoDownloads(),
      cacheDir: tmp,
      styles: StyleRegistry(MemoryStyles()),
    );
    cleared.clear();
    NotificationService.debugOnCancel = cleared.add;
  });

  tearDown(() async {
    NotificationService.debugOnCancel = null;
    await tmp.delete(recursive: true);
  });

  Future<_Radio> pump(
    WidgetTester tester,
    Widget screen, {
    bool connected = true,
    ActiveSos? mine,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final radio = _Radio()..connected = connected;
    sos = _MySos(radio)..mine = mine;
    addTearDown(sos.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
          ChangeNotifierProvider.value(value: AppSettingsService()),
          ChangeNotifierProvider.value(value: UiViewStateService()),
          ChangeNotifierProvider.value(value: ChatTextScaleService()),
          ChangeNotifierProvider.value(value: PathGraphService()),
          ChangeNotifierProvider.value(value: MessageRetryService()),
          ChangeNotifierProvider<MapPacksService>.value(value: maps),
          ChangeNotifierProvider<SosService>.value(value: sos),
        ],
        child: MaterialApp(
          navigatorObservers: [NotificationService.routeObserver],
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: screen,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    return radio;
  }

  group('Got it', () {
    testWidgets('on the card with the radio away: nothing goes, and it says '
        'so', (tester) async {
      final radio = await pump(
        tester,
        ChannelChatScreen(channel: _trip),
        connected: false,
      );
      await tester.tap(find.text('Got it'));
      await tapLands(tester);
      expect(find.text(notConnected), findsOneWidget);
      expect(radio.sent, isEmpty);
      expect(cleared, isEmpty, reason: 'the alert stays');
    });

    testWidgets('on the card goes to the radio and takes the alert away', (
      tester,
    ) async {
      final radio = await pump(tester, ChannelChatScreen(channel: _trip));
      await tester.tap(find.text('Got it'));
      await tapLands(tester);
      expect(radio.sent.single, endsWith('\nGot it'));
      expect(cleared, [annAlert]);
      expect(find.text(notConnected), findsNothing);
    });

    testWidgets('from the notification: the chat opens on the card and sends '
        'it', (tester) async {
      final radio = await pump(
        tester,
        ChannelChatScreen(
          channel: _trip,
          scrollToMessageId: _annSos.messageId,
          gotIt: true,
        ),
      );
      expect(radio.sent.single, endsWith('\nGot it'));
      expect(cleared, [annAlert]);
    });

    testWidgets('from the notification with the radio away: the chat says '
        'so, and the alert stays', (tester) async {
      final radio = await pump(
        tester,
        ChannelChatScreen(
          channel: _trip,
          scrollToMessageId: _annSos.messageId,
          gotIt: true,
        ),
        connected: false,
      );
      expect(find.text(notConnected), findsOneWidget);
      expect(find.text('Broken leg'), findsWidgets, reason: 'on the card');
      expect(radio.sent, isEmpty);
      expect(cleared, isEmpty);
    });

    testWidgets('a chat opened from a plain tap sends nothing', (tester) async {
      final radio = await pump(
        tester,
        ChannelChatScreen(channel: _trip, scrollToMessageId: _annSos.messageId),
      );
      expect(radio.sent, isEmpty);
      expect(cleared, isEmpty);
    });
  });

  group('my SOS on the Chats and Map screens', () {
    final lastSent = DateTime(2026, 11, 18, 14, 6);
    ActiveSos mine(SosPhase phase, {DateTime? at}) => ActiveSos(
      channelIdKey: _trip.idKey,
      channelName: _trip.displayName,
      messageId: 'mine0',
      text: 'Broken leg',
      position: const LatLng(36.46, -116.87),
      startedAt: DateTime(2026, 11, 18, 14),
      lastSentAt: at,
      phase: phase,
    );

    /// The bar the Chats and Map screens share, at the bottom.
    Widget chats() => Scaffold(
      body: const SizedBox.expand(),
      bottomNavigationBar: QuickSwitchBar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
      ),
    );

    final strip = find.byType(ActiveSosStrip);
    Finder line(Pattern text) =>
        find.descendant(of: strip, matching: find.textContaining(text));

    testWidgets('says in one line how it stands, in red', (tester) async {
      await pump(tester, chats(), mine: mine(SosPhase.active, at: lastSent));
      expect(
        line(RegExp(r'^Your SOS is active · last sent 2:06\sPM$')),
        findsOneWidget,
      );
      final text = find.descendant(of: strip, matching: find.byType(Text));
      expect(tester.widget<Text>(text).maxLines, 1);
      final scheme = Theme.of(tester.element(strip)).colorScheme;
      expect(
        tester
            .widget<Material>(
              find.descendant(of: strip, matching: find.byType(Material)),
            )
            .color,
        scheme.errorContainer,
        reason: 'as the bar in its chat',
      );

      sos.show(mine(SosPhase.active));
      await tester.pump();
      expect(
        line('Your SOS is active · waiting for the radio'),
        findsOneWidget,
      );

      sos.show(mine(SosPhase.stopped, at: lastSent));
      await tester.pump();
      expect(line('Your SOS stopped · Send again'), findsOneWidget);

      sos.show(mine(SosPhase.cancelling, at: lastSent));
      await tester.pump();
      expect(line('SOS cancelled · waiting for the radio'), findsOneWidget);

      sos.show(null);
      await tester.pump();
      expect(text, findsNothing);
    });

    testWidgets('never cuts its line short, even in large type', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, chats(), mine: mine(SosPhase.active, at: lastSent));
      final text = find.descendant(of: strip, matching: find.byType(Text));
      expect(
        tester.renderObject<RenderParagraph>(text).didExceedMaxLines,
        isFalse,
      );
      expect(
        tester.getRect(text).right,
        lessThanOrEqualTo(
          tester.getRect(find.byIcon(Icons.chevron_right)).left,
        ),
        reason: 'the time, last, stays in sight',
      );
    });

    testWidgets('a tap opens its chat, with the full bar there and no strip', (
      tester,
    ) async {
      await pump(tester, chats(), mine: mine(SosPhase.active, at: lastSent));
      await tester.tap(strip);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(ChannelChatScreen), findsOneWidget);
      expect(find.byType(ActiveSosBar), findsOneWidget);
      expect(find.text('Your SOS is active'), findsOneWidget);
      expect(strip, findsNothing);
    });
  });
}
