import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/services/sos_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// The sender's side of the minimal SOS (Martin's decisions 16 and 17,
// preliminary): sent, then again every 2 minutes with the radio's latest
// position until cancelled, every 5 once someone answered; Public with the
// first message only; Cancel tells everyone it reached.

/// A radio that records what the SOS sends, with replies fed by hand.
class _Radio extends MeshCoreConnector {
  _Radio(this.list);

  final List<Channel> list;
  bool connected = true;
  double? lat = 36.460000, lon = -116.870000;
  int viewers = 0;
  int _next = 0;

  /// (chat, wire text) of every new message, and of every repeat.
  final sent = <(String, String)>[];
  final repeats = <(String, String, String)>[];
  final cancelled = <(String, String)>[];
  final _rows = <String, StreamController<List<ChannelMessage>>>{};

  void rows(Channel channel, List<ChannelMessage> rows) =>
      _rows[channel.idKey]!.add(rows);

  @override
  bool get isConnected => connected;
  @override
  List<Channel> get channels => list;
  @override
  String? get selfName => 'GWQ';
  @override
  double? get selfLatitude => lat;
  @override
  double? get selfLongitude => lon;
  @override
  void addSelfPositionViewer() => viewers++;
  @override
  void removeSelfPositionViewer() => viewers--;
  @override
  String prepareChannelOutboundText(int channelIndex, String text) => text;

  @override
  Future<String?> sendChannelMessage(
    Channel channel,
    String text, {
    ChannelMessage? replyTarget,
  }) async {
    if (!connected) return null;
    sent.add((channel.idKey, text));
    return 'row${_next++}';
  }

  @override
  Future<bool> repeatChannelMessage(
    Channel channel,
    String messageId,
    String text,
  ) async {
    if (!connected) return false;
    repeats.add((channel.idKey, messageId, text));
    return true;
  }

  @override
  Future<void> markSosCancelled(Channel channel, String messageId) async =>
      cancelled.add((channel.idKey, messageId));

  @override
  Stream<List<ChannelMessage>> watchChannelMessages(
    Channel channel, {
    int limit = 200,
  }) => (_rows[channel.idKey] ??= StreamController.broadcast()).stream;
}

Uint8List _hex(String hex) => Uint8List.fromList([
  for (var i = 0; i < hex.length; i += 2)
    int.parse(hex.substring(i, i + 2), radix: 16),
]);

final _trip = Channel(
  index: 1,
  name: '#trip',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x30 + i)),
);
final _public = Channel(
  index: 0,
  name: '',
  psk: _hex(Channel.publicChannelPsk),
);
final _other = Channel(
  index: 2,
  name: '#camp',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x50 + i)),
);

const _here = LatLng(36.460000, -116.870000);

SosRequest _request({
  bool alsoPublic = true,
  bool followRadio = true,
  LatLng position = _here,
}) => SosRequest(
  message: SosMessage(position: position, text: 'Broken leg'),
  alsoPublic: alsoPublic,
  followRadio: followRadio,
);

ChannelMessage _reply(String from, String toId, {int minutes = 0}) =>
    ChannelMessage(
      senderName: from,
      text: SosMessage.gotItText,
      timestamp: DateTime(2026, 11, 16, 14, minutes),
      isOutgoing: false,
      channelIndex: 1,
      replyToMessageId: toId,
      replyToSenderName: 'GWQ',
      replyToText: 'SOS: Broken leg',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  final start = DateTime(2026, 11, 16, 14);

  /// Runs [body] on a fake clock that starts at [start].
  void onClock(
    void Function(FakeAsync async, SosService sos, _Radio radio) body, {
    List<Channel>? channels,
  }) {
    fakeAsync((async) {
      final radio = _Radio(channels ?? [_public, _trip]);
      final sos = SosService(radio, now: () => start.add(async.elapsed));
      body(async, sos, radio);
      sos.dispose();
      async.flushMicrotasks();
    });
  }

  test('the first message goes to the chat and to Public; repeats only to '
      'the chat, every 2 minutes, with the latest position', () {
    onClock((async, sos, radio) {
      sos.start(_trip, _request());
      async.flushMicrotasks();
      expect(radio.sent, [
        (_trip.idKey, 'SOS: Broken leg\n36.460000, -116.870000'),
        (_public.idKey, 'SOS: Broken leg\n36.460000, -116.870000'),
      ]);
      expect(radio.viewers, 1, reason: 'the radio is asked every 10 s');

      async.elapse(const Duration(seconds: 115));
      expect(radio.repeats, isEmpty);
      radio.lat = 36.461234;
      async.elapse(const Duration(seconds: 10));
      expect(radio.repeats, [
        (_trip.idKey, 'row0', 'SOS: Broken leg\n36.461234, -116.870000'),
      ]);

      async.elapse(const Duration(minutes: 2));
      expect(radio.repeats, hasLength(2));
      expect(radio.sent, hasLength(2), reason: 'Public: the first only');
      expect(radio.repeats.every((r) => r.$1 == _trip.idKey), isTrue);
    });
  });

  // Martin, 2026-11-17: an SOS in Public goes once, like a message there.
  test('an SOS in Public goes once: no repeat, nothing kept or saved', () {
    onClock((async, sos, radio) {
      sos.start(_public, _request());
      async.flushMicrotasks();
      expect(radio.sent, [
        (_public.idKey, 'SOS: Broken leg\n36.460000, -116.870000'),
      ]);
      expect(sos.current, isNull, reason: 'no active SOS, no bar, no Cancel');
      expect(radio.viewers, 0);
      expect(
        PrefsManager.instance.getString('active_sos'),
        isNull,
        reason: 'nothing to pick up after a restart',
      );

      async.elapse(const Duration(minutes: 12));
      expect(radio.sent, hasLength(1));
      expect(radio.repeats, isEmpty);
    });
  });

  test('an SOS in Public leaves the one active in another channel going', () {
    onClock((async, sos, radio) {
      sos.start(_trip, _request(alsoPublic: false));
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 1));
      sos.start(_public, _request());
      async.flushMicrotasks();
      expect(radio.sent.map((s) => s.$1), [_trip.idKey, _public.idKey]);
      expect(sos.current!.channelIdKey, _trip.idKey);
      expect(sos.current!.phase, SosPhase.active);

      async.elapse(const Duration(minutes: 1, seconds: 5));
      expect(
        radio.repeats.single.$1,
        _trip.idKey,
        reason: 'still every 2 minutes in its own channel',
      );
      async.elapse(const Duration(minutes: 2));
      expect(radio.repeats, hasLength(2));
      expect(radio.repeats.every((r) => r.$1 == _trip.idKey), isTrue);
      expect(
        radio.sent.where((s) => s.$2 == SosMessage.cancelText),
        isEmpty,
        reason: 'nothing cancelled it',
      );
    });
  });

  test('an SOS in Public with the radio away says it was not sent', () {
    onClock((async, sos, radio) {
      radio.connected = false;
      bool? sent;
      sos.sendOnce(_public, _request()).then((v) => sent = v);
      async.flushMicrotasks();
      expect(sent, isFalse);
      expect(radio.sent, isEmpty);
      expect(sos.current, isNull);
    });
  });

  test('Public unticked: nothing goes there', () {
    onClock((async, sos, radio) {
      sos.start(_trip, _request(alsoPublic: false));
      async.flushMicrotasks();
      expect(radio.sent.map((s) => s.$1), [_trip.idKey]);
    });
  });

  test('after the first Got it, the repeats slow to every 5 minutes', () {
    onClock((async, sos, radio) {
      sos.start(_trip, _request());
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 2, seconds: 5));
      expect(radio.repeats, hasLength(1));

      radio.rows(_trip, [_reply('Ann', 'row0', minutes: 3)]);
      async.flushMicrotasks();
      expect(sos.current!.gotIt, ['Ann']);
      expect(sos.interval, SosService.slowInterval);

      async.elapse(const Duration(minutes: 4));
      expect(radio.repeats, hasLength(1), reason: 'not at 2 minutes now');
      async.elapse(const Duration(minutes: 1, seconds: 5));
      expect(radio.repeats, hasLength(2));

      // A Got it to the Public copy counts too; my own reply does not.
      radio.rows(_public, [
        _reply('Bob', 'row1'),
        ChannelMessage(
          senderName: 'GWQ',
          text: 'Hold on',
          timestamp: start,
          isOutgoing: true,
          replyToMessageId: 'row1',
        ),
      ]);
      async.flushMicrotasks();
      expect(sos.current!.gotIt, ['Ann', 'Bob']);
    });
  });

  test('my own replies and replies to other messages are not a Got it', () {
    final mine = ChannelMessage(
      senderName: 'GWQ',
      text: 'still here',
      timestamp: start,
      isOutgoing: true,
      replyToMessageId: 'row0',
    );
    expect(
      SosService.answeredBy([mine, _reply('Ann', 'other')], {'row0'}),
      isEmpty,
    );
    expect(
      SosService.answeredBy(
        [_reply('Ann', 'row0'), _reply('Ann', 'row0'), _reply('Cy', 'row0')],
        {'row0'},
      ),
      ['Ann', 'Cy'],
    );
  });

  test('Cancel sends "SOS cancelled" to the chat and to Public, closes both '
      'cards and stops the repeats', () {
    onClock((async, sos, radio) {
      sos.start(_trip, _request());
      async.flushMicrotasks();
      async.elapse(const Duration(minutes: 2, seconds: 5));
      expect(radio.repeats, hasLength(1));

      sos.cancel();
      async.flushMicrotasks();
      expect(radio.sent.skip(2), [
        (_trip.idKey, 'SOS cancelled'),
        (_public.idKey, 'SOS cancelled'),
      ]);
      expect(radio.cancelled, [(_trip.idKey, 'row0'), (_public.idKey, 'row1')]);
      expect(sos.current, isNull);
      expect(radio.viewers, 0);
      expect(PrefsManager.instance.getString('active_sos'), isNull);

      async.elapse(const Duration(minutes: 10));
      expect(radio.repeats, hasLength(1), reason: 'no repeat after Cancel');
    });
  });

  test('Cancel with the radio away waits for it, and sends nothing more', () {
    onClock((async, sos, radio) {
      sos.start(_trip, _request(alsoPublic: false));
      async.flushMicrotasks();
      radio.connected = false;
      sos.cancel();
      async.flushMicrotasks();
      expect(sos.current!.phase, SosPhase.cancelling);
      async.elapse(const Duration(minutes: 5));
      expect(radio.repeats, isEmpty);
      expect(radio.sent, hasLength(1));

      radio.connected = true;
      async.elapse(const Duration(seconds: 6));
      expect(radio.sent.last, (_trip.idKey, 'SOS cancelled'));
      expect(sos.current, isNull);
    });
  });

  test('a position typed over the radio\'s goes out with every repeat', () {
    onClock((async, sos, radio) {
      const typed = LatLng(36.5, -117.0);
      sos.start(_trip, _request(followRadio: false, position: typed));
      async.flushMicrotasks();
      radio.lat = 36.47;
      async.elapse(const Duration(minutes: 2, seconds: 5));
      expect(radio.sent.first.$2, 'SOS: Broken leg\n36.500000, -117.000000');
      expect(
        radio.repeats.single.$3,
        'SOS: Broken leg\n36.500000, -117.000000',
      );
    });
  });

  test('a radio with no position: the typed one, until the radio has one', () {
    onClock((async, sos, radio) {
      radio.lat = null;
      radio.lon = null;
      const typed = LatLng(36.5, -117.0);
      sos.start(_trip, _request(position: typed));
      async.flushMicrotasks();
      expect(radio.sent.first.$2, endsWith('36.500000, -117.000000'));
      radio.lat = 36.48;
      radio.lon = -116.9;
      async.elapse(const Duration(minutes: 2, seconds: 5));
      expect(radio.repeats.single.$3, endsWith('36.480000, -116.900000'));
    });
  });

  test('not connected: the first message waits for the radio, never lost', () {
    onClock((async, sos, radio) {
      radio.connected = false;
      sos.start(_trip, _request(alsoPublic: false));
      async.flushMicrotasks();
      expect(radio.sent, isEmpty);
      expect(sos.current!.messageId, isNull);
      radio.connected = true;
      async.elapse(const Duration(seconds: 6));
      expect(radio.sent, hasLength(1));
      expect(sos.current!.messageId, 'row0');
    });
  });

  test('a repeat that cannot go out is tried again, every few seconds', () {
    onClock((async, sos, radio) {
      sos.start(_trip, _request(alsoPublic: false));
      async.flushMicrotasks();
      radio.connected = false;
      async.elapse(const Duration(minutes: 3));
      expect(radio.repeats, isEmpty);
      radio.connected = true;
      async.elapse(const Duration(seconds: 6));
      expect(radio.repeats, hasLength(1));
    });
  });

  test(
    'the SOS in the same chat again: new words, sent now, still one SOS',
    () {
      onClock((async, sos, radio) {
        sos.start(_trip, _request());
        async.flushMicrotasks();
        sos.start(
          _trip,
          const SosRequest(
            message: SosMessage(position: _here, text: 'Two hurt'),
            alsoPublic: true,
          ),
        );
        async.flushMicrotasks();
        expect(radio.sent, hasLength(2), reason: 'Public again? no');
        expect(radio.repeats.single.$3, startsWith('SOS: Two hurt'));
        expect(sos.current!.messageId, 'row0');
      });
    },
  );

  test('an SOS in another chat cancels the one before', () {
    onClock((async, sos, radio) {
      sos.start(_trip, _request(alsoPublic: false));
      async.flushMicrotasks();
      sos.start(_other, _request(alsoPublic: false));
      async.flushMicrotasks();
      expect(radio.sent.map((s) => s), [
        (_trip.idKey, 'SOS: Broken leg\n36.460000, -116.870000'),
        (_trip.idKey, 'SOS cancelled'),
        (_other.idKey, 'SOS: Broken leg\n36.460000, -116.870000'),
      ]);
      expect(sos.current!.channelIdKey, _other.idKey);
    }, channels: [_public, _trip, _other]);
  });

  group('the app closed and opened again', () {
    void saved(DateTime lastSent, {SosPhase phase = SosPhase.active}) {
      final sos = ActiveSos(
        channelIdKey: _trip.idKey,
        channelName: 'trip',
        messageId: 'row7',
        text: 'Broken leg',
        position: _here,
        startedAt: lastSent.subtract(const Duration(minutes: 4)),
        lastSentAt: lastSent,
        phase: phase,
        gotIt: const ['Ann'],
      );
      PrefsManager.instance.setString('active_sos', jsonEncode(sos.toJson()));
    }

    test('within 30 minutes of its last send, it carries on by itself', () {
      onClock((async, sos, radio) {
        saved(start.subtract(const Duration(minutes: 10)));
        sos.restore();
        async.flushMicrotasks();
        expect(sos.current!.phase, SosPhase.active);
        expect(sos.current!.gotIt, ['Ann']);
        async.elapse(const Duration(seconds: 6));
        expect(radio.repeats.single.$2, 'row7');
      });
    });

    test('longer ago, it waits for Send again', () {
      onClock((async, sos, radio) {
        saved(start.subtract(const Duration(hours: 3)));
        sos.restore();
        async.flushMicrotasks();
        expect(sos.current!.phase, SosPhase.stopped);
        async.elapse(const Duration(minutes: 10));
        expect(radio.repeats, isEmpty);

        sos.resume();
        async.flushMicrotasks();
        expect(radio.repeats, hasLength(1));
        expect(sos.current!.phase, SosPhase.active);
      });
    });

    test('a cancel that had not gone out yet goes out', () {
      onClock((async, sos, radio) {
        saved(start, phase: SosPhase.cancelling);
        sos.restore();
        async.elapse(const Duration(seconds: 6));
        expect(radio.sent.single, (_trip.idKey, 'SOS cancelled'));
        expect(sos.current, isNull);
      });
    });
  });

  test('every step is saved for the next start', () {
    onClock((async, sos, radio) {
      sos.start(_trip, _request());
      async.flushMicrotasks();
      final saved = ActiveSos.fromJson(
        jsonDecode(PrefsManager.instance.getString('active_sos')!)
            as Map<String, Object?>,
      )!;
      expect(saved.messageId, 'row0');
      expect(saved.publicMessageId, 'row1');
      expect(saved.lastSentAt, start);
      expect(saved.text, 'Broken leg');
    });
  });
}
