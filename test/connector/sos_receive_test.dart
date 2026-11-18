import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/message_retry_service.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/services/sos_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/pinned_messages_bar.dart';
import 'package:latlong2/latlong.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

// A received SOS must never be missed, and its repeats must not bury the
// chat (Martin's decisions 16 and 17, preliminary). The repeats of one SOS
// are one card that updates where it stands; "SOS cancelled" closes it; it
// alerts through the channel's mute and the channel-message switch, on its
// own notification category, until the user has seen to it.
class _Connector extends MeshCoreConnector {
  final frames = <Uint8List>[];

  @override
  bool get isConnected => true;

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async => frames.add(data);
}

final _psk = Uint8List.fromList(List.generate(16, (i) => 0x30 + i));

Uint8List _selfInfo() {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 20, 22]);
  w.add(Uint8List.fromList(List.filled(32, 0x77)));
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(
    (ByteData(8)
          ..setUint32(0, 910525, Endian.little)
          ..setUint32(4, 62500, Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

Uint8List _channelInfo() => Uint8List.fromList([
  respCodeChannelInfo,
  ...buildSetChannelFrame(1, '#trip', _psk).sublist(1),
]);

/// The radio's log of a flood copy one repeater passed on, sealed with the
/// channel key as the firmware seals it.
Uint8List _heardCopy(int secs, String sender, String text) {
  final plain = BytesBuilder()
    ..add((ByteData(4)..setUint32(0, secs, Endian.little)).buffer.asUint8List())
    ..addByte(0)
    ..add(utf8.encode('$sender: $text'))
    ..addByte(0);
  final bytes = plain.toBytes();
  final padded = Uint8List((bytes.length + 15) ~/ 16 * 16)
    ..setRange(0, bytes.length, bytes);
  final cipher = ECBBlockCipher(AESEngine())..init(true, KeyParameter(_psk));
  final sealed = Uint8List(padded.length);
  for (var i = 0; i < padded.length; i += 16) {
    cipher.processBlock(padded, i, sealed, i);
  }
  final key32 = Uint8List(32)..setRange(0, 16, _psk);
  final mac = crypto.Hmac(crypto.sha256, key32).convert(sealed).bytes;
  return Uint8List.fromList([
    pushCodeLogRxData, 0x14, 0xA0,
    (0x05 << 2) | 0x01, // group text, flood
    1, 0xAB, // one hop, through repeater AB
    crypto.sha256.convert(_psk).bytes[0],
    mac[0], mac[1],
    ...sealed,
  ]);
}

String _sos(String text, double lat) =>
    SosMessage(position: LatLng(lat, -116.870000), text: text).toWire();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Connector c;
  late Channel channel;
  late AppSettingsService settings;
  final shown = <ShownNotification>[];
  // Fresh for each test: a live message more than 2 minutes old is
  // re-stamped as it arrives, as a broken clock's would be.
  late int now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    settings = AppSettingsService();
    await settings.loadSettings();
    c = _Connector()
      ..initialize(
        retryService: MessageRetryService(),
        appSettingsService: settings,
      );
    c.handleFrameForTest(_selfInfo());
    await pumpEventQueue(times: 200);
    c.handleFrameForTest(_channelInfo());
    await pumpEventQueue(times: 200);
    c.markChannelsVerifiedForTest();
    channel = c.channels.single;
    shown.clear();
    NotificationService.debugOnShow = shown.add;
    now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  });

  tearDown(() => NotificationService.debugOnShow = null);

  Future<void> hear(int secs, String sender, String text) async {
    c.handleFrameForTest(_heardCopy(secs, sender, text));
    await pumpEventQueue(times: 200);
  }

  Future<List<ChannelMessage>> rows() => c.loadChannelMessagesFor(channel);

  List<ShownNotification> sosAlerts() => shown
      .where((n) => n.channelId == NotificationService.sosChannelId)
      .toList();

  List<PinnedEntry> pins(List<ChannelMessage> rows, {Set<String>? dismissed}) =>
      PinnedMessagesBar.compute(
        candidates: [
          for (final (i, m) in rows.indexed)
            PinCandidate(
              id: m.messageId,
              text: m.text,
              timestamp: m.timestamp,
              index: i,
              sosUpdatedAt: m.sosUpdatedAt,
              sosCancelled: m.sosCancelledAt != null,
            ),
        ],
        dismissed: dismissed ?? const {},
        isRoom: false,
        now: DateTime.now().add(const Duration(hours: 6)),
      );

  group('a received SOS alerts', () {
    test('through the channel\'s mute and with channel messages off', () async {
      await settings.setNotifyOnNewChannelMessage(false);
      await settings.muteChannel(channel.idKey);

      await hear(now - 30, 'Ann', 'Anyone at the springs?');
      expect(shown, isEmpty, reason: 'an ordinary message stays quiet');

      await hear(now - 20, 'Ann', _sos('Broken leg', 36.46));
      final sos = (await rows()).last;
      final alert = shown.single;
      expect(alert.channelId, 'meshtrax_sos_morse');
      expect(alert.title, 'SOS from Ann');
      expect(alert.body, 'Broken leg · trip');
      expect(
        alert.payload,
        'mention:1:${sos.messageId}',
        reason: 'a tap lands on the card',
      );
      expect(alert.silent, isFalse);
    });

    test('on its own category, which nothing else uses', () async {
      await hear(now - 40, 'Ann', 'Morning');
      await hear(now - 30, 'Bob', '@[GWQ] are you up?');
      await hear(now - 20, 'Cy', 'Location: Water tap\n36.460000, -116.870000');
      await hear(now - 10, 'Ann', _sos('Lost', 36.46));
      expect(shown.map((n) => n.channelId), [
        'meshtrax_channels',
        'meshtrax_channels',
        'meshtrax_channels',
        'meshtrax_sos_morse',
      ]);
    });

    test('but not with the app\'s notifications off', () async {
      await settings.setNotificationsEnabled(false);
      await hear(now - 20, 'Ann', _sos('Broken leg', 36.46));
      expect(shown, isEmpty);
    });
  });

  group('repeats', () {
    test('are one card that updates where it stands', () async {
      await hear(now - 100, 'Ann', _sos('Broken leg', 36.460000));
      final first = (await rows()).single;
      await hear(now - 90, 'Bob', 'On my way?');
      await hear(now - 10, 'Ann', _sos('Broken leg', 36.461234));

      final shownRows = await rows();
      expect(shownRows.map((m) => m.senderName), [
        'Ann',
        'Bob',
      ], reason: 'the card keeps its place; nothing new at the bottom');
      final card = shownRows.first;
      expect(card.messageId, first.messageId);
      expect(card.text, _sos('Broken leg', 36.461234));
      expect(card.timestamp, first.timestamp);
      expect(
        card.sosUpdatedAt,
        DateTime.fromMillisecondsSinceEpoch((now - 10) * 1000),
      );
      final unread = (await c.watchChannelUnreadCounts().first)[channel.idKey];
      expect(unread, 2, reason: 'a repeat is not another unread message');
    });

    test('a relayed copy only counts as heard; a late older one changes '
        'nothing', () async {
      await hear(now - 100, 'Ann', _sos('Broken leg', 36.460000));
      await hear(now - 10, 'Ann', _sos('Broken leg', 36.461234));
      await hear(now - 10, 'Ann', _sos('Broken leg', 36.461234));
      var card = (await rows()).single;
      expect(card.repeatCount, 1);

      await hear(now - 50, 'Ann', _sos('Broken leg', 36.455555));
      card = (await rows()).single;
      expect(
        card.text,
        _sos('Broken leg', 36.461234),
        reason: 'an older position never replaces a newer one',
      );
      expect(
        card.sosUpdatedAt,
        DateTime.fromMillisecondsSinceEpoch((now - 10) * 1000),
      );
    });

    // By the sender's clock: the time a chat shows is re-stamped for a
    // clock that looks broken, one message and not the next.
    group('are told apart by the sender\'s clock', () {
      ChannelMessage at(int secs, {List<int> heard = const [], int? cancel}) =>
          ChannelMessage(
            senderName: 'Ann',
            text: _sos('Broken leg', 36.46),
            timestamp: DateTime.now(),
            isOutgoing: false,
            channelIndex: 1,
            messageId: '${secs * 1000}_1_2',
            sentWireSecs: heard,
            sosCancelledAt: cancel == null ? null : DateTime.now(),
          );
      SosCopy kind(ChannelMessage card, int secs, {int? cancelSecs}) =>
          MeshCoreConnector.sosCopyOf(card, at(secs), cancelSecs: cancelSecs);

      test('a copy, a newer repeat, a late older one', () {
        final card = at(1000, heard: [1120]);
        expect(kind(card, 1000), SosCopy.relayed);
        expect(kind(card, 1120), SosCopy.relayed);
        expect(kind(card, 1240), SosCopy.newer);
        expect(kind(card, 1060), SosCopy.older);
      });

      test('after 30 minutes of silence, or long before, a new SOS', () {
        final card = at(1000, heard: [1120]);
        expect(kind(card, 1120 + 30 * 60), SosCopy.newer);
        expect(kind(card, 1121 + 30 * 60), SosCopy.apart);
        expect(kind(card, 1000 - 30 * 60 - 1), SosCopy.apart);
      });

      test('after a cancel: older than it a late copy, else a new SOS', () {
        final card = at(1000, heard: [1120], cancel: 1200);
        expect(kind(card, 1150, cancelSecs: 1200), SosCopy.older);
        expect(kind(card, 1201, cancelSecs: 1200), SosCopy.apart);
        expect(
          kind(card, 1150),
          SosCopy.apart,
          reason: 'no cancel to compare: shown, not lost',
        );
      });
    });

    test('a broken clock re-stamped on one message and not the next still '
        'orders them', () async {
      // 119 s old: kept as sent. Then 130 s old, re-stamped to now. By the
      // shown times the second is newer; by the sender's clock it is not.
      await hear(now - 119, 'Ann', _sos('Broken leg', 36.460000));
      await hear(now - 30, 'Ann', _sos('Broken leg', 36.461234));
      await hear(now - 130, 'Ann', _sos('Broken leg', 36.455555));
      final card = (await rows()).single;
      expect(card.text, _sos('Broken leg', 36.461234));
    });

    test('alert again until seen to: the pin dismissed, a reply sent, or '
        'the chat open', () async {
      final dismissed = <String>{};
      c.isPinDismissed = (chat, id) =>
          chat == channel.idKey && dismissed.contains(id);

      await hear(now - 100, 'Ann', _sos('Broken leg', 36.460));
      await hear(now - 80, 'Ann', _sos('Broken leg', 36.461));
      expect(sosAlerts(), hasLength(2), reason: 'not seen to yet');
      expect(
        sosAlerts().map((n) => n.id).toSet(),
        hasLength(1),
        reason: 'one notification, replaced',
      );

      dismissed.add((await rows()).single.messageId);
      await hear(now - 60, 'Ann', _sos('Broken leg', 36.462));
      expect(sosAlerts(), hasLength(2));

      await hear(now - 50, 'Cy', _sos('Lost', 36.50));
      final cy = (await rows()).last;
      await SosService(c).sendGotIt(channel, cy);
      await pumpEventQueue(times: 200);
      await hear(now - 40, 'Cy', _sos('Lost', 36.51));
      expect(sosAlerts().where((n) => n.title == 'SOS from Cy'), hasLength(1));

      await hear(now - 30, 'Dee', _sos('Stuck', 36.6));
      c.setActiveChannel(channel.index);
      await hear(now - 20, 'Dee', _sos('Stuck', 36.61));
      expect(sosAlerts().where((n) => n.title == 'SOS from Dee'), hasLength(1));
    });
  });

  group('stays pinned', () {
    test('until dismissed, hours on', () async {
      await hear(now - 30, 'Ann', _sos('Broken leg', 36.46));
      final list = await rows();
      expect(pins(list).single.id, list.single.messageId);
      expect(
        pins(list).single.at,
        DateTime.fromMillisecondsSinceEpoch((now - 30) * 1000),
      );
      expect(pins(list, dismissed: {list.single.messageId}), isEmpty);
    });

    test(
      'under one id as it updates, so a dismissed pin stays dismissed',
      () async {
        await hear(now - 30, 'Ann', _sos('Broken leg', 36.46));
        final id = (await rows()).single.messageId;
        await hear(now - 10, 'Ann', _sos('Broken leg', 36.47));
        final list = await rows();
        expect(
          pins(list).single.at,
          DateTime.fromMillisecondsSinceEpoch((now - 10) * 1000),
        );
        expect(pins(list, dismissed: {id}), isEmpty);
      },
    );
  });

  group('SOS cancelled', () {
    test('closes the card, which leaves the pinned bar; the cancel is a '
        'message of its own', () async {
      await hear(now - 100, 'Ann', _sos('Broken leg', 36.46));
      await hear(now - 60, 'Ann', SosMessage.cancelText);
      final list = await rows();
      expect(list.map((m) => m.text), [
        _sos('Broken leg', 36.46),
        'SOS cancelled',
      ]);
      expect(
        list.first.sosCancelledAt,
        DateTime.fromMillisecondsSinceEpoch((now - 60) * 1000),
      );
      expect(pins(list), isEmpty);
      final last = sosAlerts().last;
      expect(last.title, 'SOS cancelled by Ann');
      expect(last.silent, isTrue);
    });

    test(
      'a second cancel soon after the first closes the second SOS',
      () async {
        await hear(now - 110, 'Ann', _sos('Broken leg', 36.46));
        await hear(now - 100, 'Ann', 'SOS cancelled');
        await hear(now - 90, 'Ann', _sos('Broken leg', 36.46));
        await hear(now - 80, 'Ann', 'SOS cancelled');
        final list = await rows();
        expect(list, hasLength(4), reason: 'two cancels, two messages');
        expect(
          list
              .where((m) => m.text.startsWith('SOS:'))
              .map((m) => m.sosCancelledAt != null),
          [true, true],
        );
        expect(pins(list), isEmpty);
      },
    );

    test('from someone else closes nothing', () async {
      await hear(now - 100, 'Ann', _sos('Broken leg', 36.46));
      await hear(now - 60, 'Bob', 'SOS cancelled');
      expect((await rows()).first.sosCancelledAt, isNull);
    });

    test('a new SOS after it, same words, is a new card that alerts', () async {
      await hear(now - 100, 'Ann', _sos('Broken leg', 36.46));
      await hear(now - 60, 'Ann', 'SOS cancelled');
      await hear(now - 30, 'Ann', _sos('Broken leg', 36.46));
      final list = await rows();
      expect(list, hasLength(3));
      expect(list.last.sosCancelledAt, isNull);
      expect(pins(list).single.id, list.last.messageId);
      expect(sosAlerts().last.silent, isFalse);
      expect(sosAlerts().last.title, 'SOS from Ann');
    });
  });

  group('Got it', () {
    test('goes back as a reply to the SOS', () async {
      await hear(now - 30, 'Ann', _sos('Broken leg', 36.46));
      final sos = (await rows()).single;
      await SosService(c).sendGotIt(channel, sos);
      await pumpEventQueue(times: 200);

      final reply = (await rows()).last;
      expect(reply.isOutgoing, isTrue);
      expect(reply.text, 'Got it');
      expect(reply.replyToMessageId, sos.messageId);
      final wire = utf8.encode('@[Ann]\n>SOS: Broke..\nGot it');
      expect(
        c.frames.any((f) => _contains(f, wire)),
        isTrue,
        reason: 'the reply format other apps read',
      );
    });

    test(
      'reaches the sender, and the repeats slow to every 5 minutes',
      () async {
        final sos = SosService(c);
        addTearDown(sos.dispose);
        await sos.start(
          channel,
          const SosRequest(
            message: SosMessage(
              position: LatLng(36.46, -116.87),
              text: 'Broken leg',
            ),
          ),
        );
        await pumpEventQueue(times: 200);
        final mine = (await rows()).single;
        expect(mine.isOutgoing, isTrue);
        expect(sos.interval, SosService.firstInterval);

        final wire = ChannelMessage.buildReplyWireText(
          targetName: 'GWQ',
          quoteText: mine.text,
          body: 'Got it',
          fits: (_) => true,
        )!;
        await hear(now, 'Ann', wire);
        await pumpEventQueue(times: 200);

        final reply = (await rows()).firstWhere((m) => m.text == 'Got it');
        expect(reply.replyToMessageId, mine.messageId);
        expect(sos.current!.gotIt, ['Ann']);
        expect(sos.interval, SosService.slowInterval);
      },
    );

    test('is a button on the alert, which its cancel no longer has', () async {
      await hear(now - 30, 'Ann', _sos('Broken leg', 36.46));
      expect(sosAlerts().single.gotIt, isTrue);
      await hear(now - 20, 'Ann', SosMessage.cancelText);
      expect(sosAlerts().last.silent, isTrue);
      expect(sosAlerts().last.gotIt, isFalse);
    });

    test('stops its alert at once, even while it sounds', () async {
      final cancelled = <int>[];
      NotificationService.debugOnCancel = cancelled.add;
      addTearDown(() => NotificationService.debugOnCancel = null);
      await hear(now - 30, 'Ann', _sos('Broken leg', 36.46));
      final sos = (await rows()).single;
      await SosService(c).sendGotIt(channel, sos);
      expect(cancelled, [
        NotificationService.sosNotificationId(channel.idKey, 'Ann'),
      ]);
      expect(sosAlerts().single.id, cancelled.single);
    });

    test('from the alert goes back as a reply to its card', () async {
      await hear(now - 30, 'Ann', _sos('Broken leg', 36.46));
      final sos = (await rows()).single;
      await SosService(c).gotItFor(channel, sos.messageId);
      await pumpEventQueue(times: 200);
      final reply = (await rows()).last;
      expect(reply.text, 'Got it');
      expect(reply.replyToMessageId, sos.messageId);
    });

    test('from the alert sends nothing once the SOS is cancelled', () async {
      await hear(now - 30, 'Ann', _sos('Broken leg', 36.46));
      final sos = (await rows()).single;
      await hear(now - 20, 'Ann', SosMessage.cancelText);
      await SosService(c).gotItFor(channel, sos.messageId);
      await pumpEventQueue(times: 200);
      expect((await rows()).where((m) => m.isOutgoing), isEmpty);
    });
  });
}

bool _contains(Uint8List haystack, List<int> needle) {
  outer:
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) continue outer;
    }
    return true;
  }
  return false;
}
