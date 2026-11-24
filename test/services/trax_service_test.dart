import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/structured_message.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/radio_settings.dart';
import 'package:meshtrax/models/trax.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// TRAX mode's radio part: one tap saves the radio's settings on the phone,
// tells the group, moves the radio with repeat on, and Leave puts it back.
// A member's message only ever asks.
class _Radio extends MeshCoreConnector {
  final sent = <Uint8List>[];
  final posted = <String>[];
  List<Channel> channelList = [];
  List<Contact> contactList = [];
  final heardWhen = <String, DateTime>{};
  final incoming =
      StreamController<
        ({ChannelMessage message, bool fromBacklog})
      >.broadcast();

  bool refuseSettings = false;
  bool connected = true;

  /// Stats polls before the radio has sent what it was handed.
  int pollsUntilSent = 2;
  int _pollsLeft = 0;
  int _floods = 0;
  int _queued = 0;

  void drop() {
    connected = false;
    notifyListeners();
  }

  @override
  bool get isConnected => connected;
  @override
  bool get channelsVerified => true;
  @override
  List<Channel> get channels => channelList;
  @override
  List<Contact> get allContacts => contactList;
  @override
  DateTime? getLocalDiscoveredTime(String pubKeyHex) => heardWhen[pubKeyHex];
  @override
  Stream<({ChannelMessage message, bool fromBacklog})> get channelMessagesIn =>
      incoming.stream;
  @override
  Future<bool> waitUntilSynced({
    Duration timeout = const Duration(seconds: 90),
  }) async => true;
  @override
  Future<void> refreshRadioSettings() async {}

  @override
  Future<String?> sendChannelMessage(
    Channel channel,
    String text, {
    ChannelMessage? replyTarget,
  }) async {
    posted.add(text);
    await sendFrame(buildSendChannelTextMsgFrame(channel.index, text));
    return null;
  }

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {
    sent.add(data);
    scheduleMicrotask(() => _answer(data));
  }

  void _answer(Uint8List d) {
    switch (d[0]) {
      case cmdSendChannelTxtMsg:
        _queued = 1;
        _pollsLeft = pollsUntilSent;
        handleFrameForTest([respCodeOk]);
      case cmdGetStats when d[1] == statsTypeCore:
        handleFrameForTest([
          respCodeStats,
          statsTypeCore,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          _queued,
        ]);
      case cmdGetStats when d[1] == statsTypePackets:
        if (_queued > 0 && _pollsLeft-- <= 0) {
          _queued = 0;
          _floods++;
        }
        handleFrameForTest([
          respCodeStats,
          statsTypePackets,
          ..._u32(9),
          ..._u32(4),
          ..._u32(_floods),
          ..._u32(0),
        ]);
      case cmdSetRadioParams:
        handleFrameForTest(refuseSettings ? [respCodeErr, 6] : [respCodeOk]);
      case cmdGetAllowedRepeatFreq:
        handleFrameForTest([
          respCodeAllowedRepeatFreq,
          for (final f in [433000, 869495, 918000]) ...[..._u32(f), ..._u32(f)],
        ]);
      case cmdGetBattAndStorage:
        handleFrameForTest([
          respCodeBattAndStorage,
          0x10,
          0x0E,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ]);
      case cmdSendSelfAdvert || cmdSetRadioTxPower:
        handleFrameForTest([respCodeOk]);
    }
  }

  List<int> commands() => [for (final f in sent) f[0]];
}

/// For fake time: answers at once. The connector's own waits end on a
/// stream cancel that completes outside a fake zone.
class _InstantRadio extends _Radio {
  @override
  Future<RepeatRanges?> getAllowedRepeatFrequencies() async => [
    for (final f in [433000, 869495, 918000]) (lowerKhz: f, upperKhz: f),
  ];

  @override
  Future<bool> setRadioParams(
    int freqKhz,
    int bwHz,
    int sf,
    int cr, {
    bool? clientRepeat,
  }) async {
    sent.add(
      buildSetRadioParamsFrame(
        freqKhz,
        bwHz,
        sf,
        cr,
        clientRepeat: clientRepeat,
      ),
    );
    return true;
  }

  @override
  Future<bool> waitForRadio({
    Duration timeout = const Duration(seconds: 3),
  }) async => true;
}

List<int> _u32(int v) =>
    (ByteData(4)..setUint32(0, v, Endian.little)).buffer.asUint8List();

Uint8List _key(int b) => Uint8List(32)..fillRange(0, 32, b);

/// DEVICE_INFO of companion 1.18: byte 80 is Off-Grid Repeat.
Uint8List _deviceInfo({bool repeat = false}) {
  final frame = Uint8List(82);
  frame[0] = respCodeDeviceInfo;
  frame[1] = 14;
  frame.setRange(60, 67, 'v1.18.0'.codeUnits);
  frame[80] = repeat ? 1 : 0;
  return frame;
}

Uint8List _selfInfo({
  required Uint8List key,
  int freq = 910525,
  int bw = 62500,
  int sf = 7,
  int cr = 5,
  int tx = 20,
}) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, tx, 22]);
  w.add(key);
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add([..._u32(freq), ..._u32(bw)]);
  w.add([sf, cr]);
  w.add(utf8.encode('Ana'));
  return w.toBytes();
}

final _trip = Channel(
  index: 1,
  name: 'Desert trip',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x40 + i)),
);
final _public = Channel.fromHex(0, '', Channel.publicChannelPsk);
final _hashtag = Channel(
  index: 2,
  name: '#desert',
  psk: Channel.derivePskFromHashtag('#desert'),
);

/// CMD_SET_RADIO_PARAMS as companion firmware reads it (MyMesh.cpp
/// 1424-1459 at companion-v1.18.0): freq u32 LE in kHz, bw u32 LE in Hz,
/// sf, cr, then repeat.
List<int> _cmd11(int freqKhz, int bwHz, int sf, int cr, int repeat) => [
  cmdSetRadioParams,
  ..._u32(freqKhz),
  ..._u32(bwHz),
  sf,
  cr,
  repeat,
];

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 80));

ChannelMessage _from(String sender, String text, Channel channel) =>
    ChannelMessage(
      senderKey: null,
      senderName: sender,
      text: text,
      timestamp: DateTime.now(),
      isOutgoing: false,
      channelIndex: channel.index,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Radio radio;
  late TraxService trax;
  final keyA = _key(0x11), keyB = _key(0x22);
  final end = DateTime.now().add(const Duration(days: 2));

  TraxService service() => TraxService(
    radio,
    sendPoll: const Duration(milliseconds: 1),
    sendMargin: Duration.zero,
  );

  Future<void> connect(Uint8List key, {bool repeat = false, int? freq}) async {
    radio.handleFrameForTest(_deviceInfo(repeat: repeat));
    radio.handleFrameForTest(
      _selfInfo(key: key, freq: freq ?? (repeat ? 918000 : 910525)),
    );
    await _settle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    radio = _Radio()..channelList = [_public, _trip, _hashtag];
    trax = service();
    await trax.updateSetup(
      TraxSetup(channelKey: _trip.idKey, until: end, tellGroup: true),
    );
  });

  tearDown(() => trax.dispose());

  test('CMD 11 bytes match the firmware parser', () {
    expect(buildSetRadioParamsFrame(918000, 62500, 7, 5, clientRepeat: true), [
      11,
      0xF0,
      0x01,
      0x0E,
      0x00,
      0x24,
      0xF4,
      0x00,
      0x00,
      7,
      5,
      1,
    ]);
    expect(
      buildSetRadioParamsFrame(910525, 62500, 7, 5, clientRepeat: false),
      _cmd11(910525, 62500, 7, 5, 0),
    );
  });

  test('one tap: tell the group, wait until it is sent, one settings write '
      'with repeat on, then the group check', () async {
    await connect(keyA);
    radio.sent.clear();
    radio.directRepeaters.add(
      DirectRepeater(pubkeyPrefix: Uint8List.fromList([0xF8]), snr: 6),
    );

    expect(trax.isOn, isFalse);
    expect(
      trax.plannedPreset?.label,
      '918.000\u00A0MHz · 62.5\u00A0kHz · SF7 · CR5',
    );
    final outcome = await trax.start();
    expect(outcome, TraxOutcome.ok);

    final told = StructuredMessage.parse(radio.posted.single) as TraxMessage;
    expect(told.on, isTrue);
    expect(
      told.until,
      DateTime.fromMillisecondsSinceEpoch(
        end.millisecondsSinceEpoch ~/ 60000 * 60000,
      ).toUtc(),
      reason: 'the end, to the minute',
    );
    expect(
      told.preset,
      const LoRaParams(freqKhz: 918000, bwHz: 62500, sf: 7, cr: 5),
    );

    final cmds = radio.commands();
    final message = cmds.indexOf(cmdSendChannelTxtMsg);
    final write = cmds.indexOf(cmdSetRadioParams);
    expect(message, greaterThan(-1));
    expect(write, greaterThan(message));
    final pollsBetween = cmds
        .sublist(message, write)
        .where((c) => c == cmdGetStats)
        .length;
    expect(
      pollsBetween,
      greaterThanOrEqualTo(2 * 3),
      reason: 'the write waited until the radio had sent the message',
    );
    expect(cmds.where((c) => c == cmdSetRadioParams), hasLength(1));
    expect(radio.sent[write], _cmd11(918000, 62500, 7, 5, 1));
    final advert = radio.sent.lastWhere((f) => f[0] == cmdSendSelfAdvert);
    expect(advert, [cmdSendSelfAdvert, 1], reason: 'one flood advert');
    expect(cmds.lastIndexOf(cmdSendSelfAdvert), greaterThan(write));

    expect(trax.isOn, isTrue);
    expect(radio.clientRepeat, isTrue);
    expect(radio.currentFreqHz, 918000);
    expect(
      radio.directRepeaters,
      isEmpty,
      reason: 'repeaters heard on the regular mesh are out of reach',
    );
    expect(
      radio.rememberedNonRepeatRadioState?.freqHz,
      910525,
      reason: 'the radio settings dialog turns repeat off to the same place',
    );
  });

  test(
    'the saved settings survive an app restart and a change of radio',
    () async {
      await connect(keyA);
      await trax.start();
      final saved = trax.session!.saved;
      expect(
        saved,
        const TraxSavedRadio(
          freqKhz: 910525,
          bwHz: 62500,
          sf: 7,
          cr: 5,
          txPowerDbm: 20,
          repeat: false,
        ),
      );

      // The app restarts.
      trax.dispose();
      PrefsManager.reset();
      await PrefsManager.initialize();
      trax = service();
      expect(TraxService.sessionFor(radio.selfPublicKeyHex)?.saved, saved);

      // Another radio, then this one again, still in TRAX mode.
      await connect(keyB);
      expect(trax.session, isNull);
      expect(trax.isOn, isFalse);
      await connect(keyA, repeat: true);
      expect(trax.isOn, isTrue);
      expect(trax.session?.saved, saved);
      expect(trax.session?.until, isNotNull);
    },
  );

  test(
    'Leave tells the group first, then restores the settings exactly',
    () async {
      await connect(keyA);
      await trax.start();
      // A TX power change while in TRAX mode.
      radio.noteRadioSettingsSaved(
        freqKhz: 918000,
        bwHz: 62500,
        sf: 7,
        cr: 5,
        txPower: 22,
        clientRepeat: true,
      );
      radio.sent.clear();
      radio.posted.clear();

      expect(await trax.leave(), TraxOutcome.ok);
      expect(radio.posted, ['TRAX: off']);
      final cmds = radio.commands();
      final message = cmds.indexOf(cmdSendChannelTxtMsg);
      final write = cmds.indexOf(cmdSetRadioParams);
      expect(write, greaterThan(message), reason: 'told before moving back');
      expect(radio.sent[write], _cmd11(910525, 62500, 7, 5, 0));
      expect(radio.sent.where((f) => f[0] == cmdSetRadioTxPower).single, [
        cmdSetRadioTxPower,
        20,
      ]);
      expect(trax.isOn, isFalse);
      expect(radio.currentFreqHz, 910525);
      expect(radio.currentTxPower, 20);
      expect(radio.clientRepeat, isFalse);
      expect(trax.session, isNull, reason: 'nothing left to restore');
    },
  );

  test('Location in adverts, when ticked, goes on with TRAX mode before the '
      'group check, and off at Leave, which says the trip\'s end', () async {
    await trax.updateSetup(trax.setup.copyWith(advertPosition: true));
    await connect(keyA);
    final left = <DateTime?>[];
    final sub = trax.left.listen(left.add);
    expect(radio.advertLocationPolicy, 0);

    expect(await trax.start(), TraxOutcome.ok);
    expect(radio.advertLocationPolicy, 1);
    expect(trax.session?.advertSet, isTrue);
    expect(trax.checkedAt, isNotNull);
    final cmds = radio.commands();
    expect(
      cmds.indexOf(cmdSetOtherParams),
      allOf(
        greaterThan(cmds.indexOf(cmdSetRadioParams)),
        lessThan(cmds.lastIndexOf(cmdSendSelfAdvert)),
      ),
      reason: 'the group check\'s advert carries the position',
    );

    expect(await trax.leave(), TraxOutcome.ok);
    expect(radio.advertLocationPolicy, 0);
    expect(trax.checkedAt, isNull);
    await _settle();
    expect(left.map((t) => t?.millisecondsSinceEpoch), [
      end.millisecondsSinceEpoch,
    ]);
    await sub.cancel();
  });

  test('Location in adverts on before TRAX mode stays on at Leave', () async {
    await trax.updateSetup(trax.setup.copyWith(advertPosition: true));
    await connect(keyA);
    await radio.setTelemetryModeBase(
      radio.telemetryModeBase,
      radio.telemetryModeLoc,
      radio.telemetryModeEnv,
      1,
    );
    expect(await trax.start(), TraxOutcome.ok);
    expect(trax.session?.advertSet, isFalse);
    expect(await trax.leave(), TraxOutcome.ok);
    expect(radio.advertLocationPolicy, 1);
  });

  test(
    'a radio another phone switched asks which preset to return to',
    () async {
      await connect(keyA, repeat: true);
      expect(trax.isOn, isTrue);
      expect(await trax.leave(tellGroup: false), TraxOutcome.needPreset);
      expect(radio.commands(), isNot(contains(cmdSetRadioParams)));

      final usa = Trax.regularPresets.firstWhere((p) => p.$1 == 'USA/Canada');
      expect(
        await trax.leave(
          returnTo: trax.savedFromPreset(usa.$2),
          tellGroup: false,
        ),
        TraxOutcome.ok,
      );
      expect(
        radio.sent.lastWhere((f) => f[0] == cmdSetRadioParams),
        _cmd11(910525, 62500, 7, 5, 0),
      );
    },
  );

  test('a refused write changes nothing', () async {
    await connect(keyA);
    radio.refuseSettings = true;
    expect(await trax.start(tellGroup: false), TraxOutcome.refused);
    expect(trax.isOn, isFalse);
    expect(radio.currentFreqHz, 910525);
    expect(radio.clientRepeat, isFalse);
    expect(radio.commands(), isNot(contains(cmdSendSelfAdvert)));
  });

  test('switching needs an end, and a trip channel to tell', () async {
    await connect(keyA);
    await trax.updateSetup(trax.setup.copyWith(until: () => null));
    expect(await trax.start(), TraxOutcome.noEnd);
    await trax.updateSetup(
      trax.setup.copyWith(until: () => end, channelKey: () => _hashtag.idKey),
    );
    expect(
      await trax.start(),
      TraxOutcome.noChannel,
      reason: 'a hashtag channel is no trip channel',
    );
    expect(radio.commands(), isNot(contains(cmdSetRadioParams)));
  });

  test('a later settings write in TRAX mode keeps repeat on', () async {
    await connect(keyA);
    await trax.start(tellGroup: false);
    radio.sent.clear();
    await radio.setRadioParams(918000, 62500, 7, 5);
    expect(radio.sent.single, _cmd11(918000, 62500, 7, 5, 1));
  });

  group('a member\'s TRAX message', () {
    final on = TraxMessage.switching(
      until: end,
      preset: const LoRaParams(freqKhz: 918000, bwHz: 62500, sf: 7, cr: 5),
    ).toWire();
    late List<TraxPrompt> prompts;

    setUp(() async {
      await connect(keyA);
      prompts = [];
      trax.prompts.listen(prompts.add);
      radio.sent.clear();
    });

    void receive(String text, Channel channel, {bool backlog = false}) => radio
        .incoming
        .add((message: _from('Bo', text, channel), fromBacklog: backlog));

    test('asks on a private channel and never retunes by itself', () async {
      receive(on, _trip);
      await _settle();
      final prompt = prompts.single as TraxFollowPrompt;
      expect(prompt.sender, 'Bo');
      expect(prompt.channel.idKey, _trip.idKey);
      expect(radio.sent, isEmpty, reason: 'nothing goes to the radio');
      expect(trax.isOn, isFalse);

      // The tap.
      expect(await trax.follow(prompt.message, prompt.channel), TraxOutcome.ok);
      expect(radio.posted, isEmpty, reason: 'the group was told already');
      expect(
        radio.sent.firstWhere((f) => f[0] == cmdSetRadioParams),
        _cmd11(918000, 62500, 7, 5, 1),
      );
    });

    test('never asks on Public, hashtag or unknown channels', () async {
      receive(on, _public);
      receive(on, _hashtag);
      receive(on, Channel(index: 7, name: 'Gone', psk: Uint8List(16)..[0] = 1));
      await _settle();
      expect(prompts, isEmpty);
    });

    test(
      'never asks from the backlog, after its end, or when already on',
      () async {
        receive(on, _trip, backlog: true);
        receive(
          TraxMessage.switching(
            until: DateTime.now().subtract(const Duration(hours: 1)),
            preset: const LoRaParams(
              freqKhz: 918000,
              bwHz: 62500,
              sf: 7,
              cr: 5,
            ),
          ).toWire(),
          _trip,
        );
        receive('TRAX: off', _trip);
        await _settle();
        expect(prompts, isEmpty, reason: 'leaving asks only those on TRAX');

        await trax.start(tellGroup: false);
        receive(on, _trip);
        receive('TRAX: off', _trip);
        await _settle();
        expect(prompts.single, isA<TraxLeavePrompt>());
      },
    );

    // A phone in a pocket hears only the notification.
    test('its notification gets the same button, which asks again while '
        'it fits', () async {
      String? button(String text, Channel channel, {bool backlog = false}) =>
          trax.notificationAction(
            _from('Bo', text, channel),
            fromBacklog: backlog,
          );
      final over = TraxMessage.switching(
        until: DateTime.now().subtract(const Duration(hours: 1)),
        preset: const LoRaParams(freqKhz: 918000, bwHz: 62500, sf: 7, cr: 5),
      ).toWire();

      expect(button(on, _trip), NotificationService.traxFollowAction);
      expect(button(on, _public), isNull);
      expect(button(on, _hashtag), isNull);
      expect(button(on, _trip, backlog: true), isNull);
      expect(button(over, _trip), isNull, reason: 'after its end');
      expect(button('TRAX: off', _trip), isNull, reason: 'not on TRAX');
      expect(button('Meet at the trailhead', _trip), isNull);

      expect(trax.askedOn(_trip.index), isNull, reason: 'nothing heard');
      receive(on, _trip);
      await _settle();
      expect(trax.askedOn(_trip.index), prompts.single);

      await trax.start(tellGroup: false);
      expect(trax.askedOn(_trip.index), isNull, reason: 'on TRAX now');
      expect(button(on, _trip), isNull);
      expect(button('TRAX: off', _trip), NotificationService.traxLeaveAction);
      receive('TRAX: off', _trip);
      await _settle();
      expect(trax.askedOn(_trip.index), const TraxLeavePrompt('Bo'));
    });
  });

  test('the group check lists who was heard on TRAX', () async {
    await connect(keyA);
    Contact contact(int b, String name) => Contact(
      publicKey: _key(b),
      name: name,
      type: advTypeChat,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime.now(),
    );
    final cy = contact(0x33, 'Cy'), ana = contact(0x34, 'Ana');
    final dee = contact(0x35, 'Dee');
    radio.contactList = [cy, ana, dee];
    radio.heardWhen[dee.publicKeyHex] = DateTime.now().subtract(
      const Duration(hours: 1),
    );
    expect(trax.heard, isEmpty, reason: 'not on TRAX');

    await trax.start(tellGroup: false);
    expect(trax.heard, isEmpty, reason: 'Dee was heard before the switch');
    radio.heardWhen[cy.publicKeyHex] = DateTime.now();
    radio.heardWhen[ana.publicKeyHex] = DateTime.now();
    expect(trax.heard.map((c) => c.name), ['Ana', 'Cy']);

    radio.sent.clear();
    await trax.groupCheck();
    expect(radio.sent.single, [cmdSendSelfAdvert, 1]);
  });

  test('a radio found on a TRAX preset at connect is on, whichever phone '
      'switched it, and asks to leave after the trip\'s end', () async {
    final prompts = <TraxPrompt>[];
    trax.prompts.listen(prompts.add);
    await connect(keyA, repeat: true);
    expect(trax.isOn, isTrue);
    expect(prompts, isEmpty, reason: 'the trip has not ended');

    await trax.updateSetup(
      trax.setup.copyWith(
        until: () => DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    );
    await connect(keyB);
    await connect(keyA, repeat: true);
    expect(prompts.single, isA<TraxStillOnPrompt>());

    // Repeat on the regular frequency is not TRAX mode.
    expect(Trax.isOn(clientRepeat: true, freqKhz: 910525), isFalse);
  });

  test(
    'a radio off TRAX mode at connect forgets what was saved for it',
    () async {
      await connect(keyA);
      await trax.start(tellGroup: false);
      expect(trax.session, isNotNull);
      // Another phone took it back to the mesh.
      await connect(keyB);
      await connect(keyA);
      expect(TraxService.sessionFor(radio.selfPublicKeyHex), isNull);
    },
  );

  // A phone that stays connected through the trip's end heard nothing
  // there: the question came only at the next connect.
  group('the trip\'s end while connected', () {
    final t0 = DateTime(2026, 11, 21, 15);
    final shown = <ShownNotification>[];
    late List<TraxPrompt> prompts;

    setUp(() {
      shown.clear();
      NotificationService.debugOnShow = shown.add;
      trax.dispose();
      radio = _InstantRadio()..channelList = [_public, _trip, _hashtag];
    });

    tearDown(() => NotificationService.debugOnShow = null);

    /// TRAX settings ending [left] after [t0], on fake time from [t0].
    void begin(FakeAsync async, Duration left) {
      trax = TraxService(
        radio,
        clock: () => t0.add(async.elapsed),
        sendPoll: const Duration(milliseconds: 1),
        sendMargin: Duration.zero,
      );
      prompts = [];
      trax.prompts.listen(prompts.add);
      unawaited(trax.updateSetup(TraxSetup(until: t0.add(left))));
      async.flushMicrotasks();
    }

    void connectNow(FakeAsync async, {bool repeat = false}) {
      radio.handleFrameForTest(_deviceInfo(repeat: repeat));
      radio.handleFrameForTest(
        _selfInfo(key: keyA, freq: repeat ? 918000 : 910525),
      );
      async.flushMicrotasks();
    }

    test('brings a notification and the question, at the end', () {
      fakeAsync((async) {
        begin(async, const Duration(hours: 2));
        connectNow(async, repeat: true);
        expect(trax.isOn, isTrue);

        async.elapse(const Duration(hours: 1, minutes: 59));
        expect(shown, isEmpty);
        expect(prompts, isEmpty);

        async.elapse(const Duration(minutes: 1));
        final note = shown.single;
        expect(note.channelId, NotificationService.traxChannelId);
        expect(note.title, 'Your trip has ended');
        expect(
          note.body,
          "Still in TRAX mode: the regular mesh can't hear you.",
        );
        expect(note.payload, NotificationService.traxEndedPayload);
        expect(prompts.single, isA<TraxStillOnPrompt>());
        expect(
          trax.tripEndedPrompt,
          isA<TraxStillOnPrompt>(),
          reason: 'its tap asks again',
        );

        async.elapse(const Duration(days: 1));
        expect(shown, hasLength(1), reason: 'once');
      });
    });

    test('a new end in TRAX settings moves it, after this phone\'s switch '
        'too', () {
      fakeAsync((async) {
        begin(async, const Duration(hours: 1));
        connectNow(async);
        unawaited(trax.start(tellGroup: false));
        async.elapse(const Duration(seconds: 5));
        expect(trax.isOn, isTrue);
        expect(trax.session?.until, t0.add(const Duration(hours: 1)));

        unawaited(
          trax.updateSetup(
            trax.setup.copyWith(until: () => t0.add(const Duration(hours: 3))),
          ),
        );
        async.flushMicrotasks();
        expect(trax.until, t0.add(const Duration(hours: 3)));
        expect(
          trax.session?.until,
          t0.add(const Duration(hours: 3)),
          reason: 'the radio\'s end, which a connect asks by',
        );

        async.elapse(const Duration(hours: 2));
        expect(shown, isEmpty, reason: 'the old end passed quietly');
        async.elapse(const Duration(hours: 1));
        expect(shown, hasLength(1));
        expect(prompts.single, isA<TraxStillOnPrompt>());
      });
    });

    test('a member\'s end, followed, is the reminder\'s', () {
      fakeAsync((async) {
        begin(async, const Duration(hours: 1));
        connectNow(async);
        final message = TraxMessage.switching(
          until: t0.add(const Duration(hours: 5)),
          preset: const LoRaParams(freqKhz: 918000, bwHz: 62500, sf: 7, cr: 5),
        );
        TraxOutcome? outcome;
        unawaited(trax.follow(message, _trip).then((o) => outcome = o));
        async.elapse(const Duration(seconds: 5));
        expect(outcome, TraxOutcome.ok);
        expect(trax.until, t0.add(const Duration(hours: 5)));

        async.elapse(const Duration(hours: 4, minutes: 59));
        expect(shown, isEmpty, reason: 'not at the end TRAX settings had');
        async.elapse(const Duration(minutes: 1));
        expect(shown, hasLength(1));
      });
    });

    test('goes with TRAX mode, and with the radio', () {
      fakeAsync((async) {
        begin(async, const Duration(hours: 1));
        connectNow(async);
        unawaited(trax.start(tellGroup: false));
        async.elapse(const Duration(seconds: 5));
        expect(trax.isOn, isTrue);
        unawaited(trax.leave(tellGroup: false));
        async.elapse(const Duration(seconds: 5));
        expect(trax.isOn, isFalse);
        expect(trax.session, isNull);
        async.elapse(const Duration(hours: 2));
        expect(shown, isEmpty, reason: 'left before the end');

        unawaited(
          trax.updateSetup(
            trax.setup.copyWith(until: () => t0.add(const Duration(hours: 4))),
          ),
        );
        connectNow(async, repeat: true);
        expect(trax.isOn, isTrue);
        radio.drop();
        async.elapse(const Duration(hours: 3));
        expect(shown, isEmpty, reason: 'no radio to say anything about');
        expect(prompts, isEmpty);
      });
    });
  });
}
