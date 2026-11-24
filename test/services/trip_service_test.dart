import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/trax.dart';
import 'package:meshtrax/services/radio_ask_service.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/services/trip_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Trip setup has nothing to set up: the trip channel's posters are the
// members, they may ask this radio as soon as the channel is picked, and
// Leave after the trip's end puts it all back.
class _Radio extends MeshCoreConnector {
  bool connected = true;
  bool synced = true;
  List<Channel> channelList = [];
  List<Contact> saved = [];
  String key = 'ab' * 32;
  int modeBase = teleModeDeny;
  int modeLoc = teleModeDeny;
  bool gps = false;
  bool repeat = false;
  int freq = 910525;
  List<ChannelMessage> history = [];
  final heard = <String, DateTime>{};
  final incoming =
      StreamController<
        ({ChannelMessage message, bool fromBacklog})
      >.broadcast();

  /// Each contact write: name, favourite, base, location.
  final flagWrites = <(String, bool?, bool?, bool?)>[];
  final modeWrites = <(int, int)>[];
  final vars = <String>[];

  @override
  bool get isConnected => connected;
  @override
  bool get isSynced => synced;
  @override
  bool get channelsVerified => true;
  @override
  List<Channel> get channels => channelList;
  @override
  List<Contact> get contacts => saved;
  @override
  String get selfPublicKeyHex => key;
  @override
  String? get selfName => 'Me';
  @override
  int get telemetryModeBase => modeBase;
  @override
  int get telemetryModeLoc => modeLoc;
  @override
  int get telemetryModeEnv => teleModeDeny;
  @override
  int get advertLocationPolicy => 0;
  @override
  int get multiAcks => 0;
  @override
  bool get gpsOn => gps;
  @override
  bool? get clientRepeat => repeat;
  @override
  int? get currentFreqHz => freq;
  @override
  Stream<({ChannelMessage message, bool fromBacklog})> get channelMessagesIn =>
      incoming.stream;
  @override
  Future<List<ChannelMessage>> loadChannelMessagesFor(Channel channel) async =>
      [
        for (final m in history)
          if (m.channelIndex == channel.index) m,
      ];
  @override
  DateTime? getLocalDiscoveredTime(String pubKeyHex) => heard[pubKeyHex];

  @override
  Future<void> setContactFlags(
    Contact contact, {
    bool? isFavorite,
    bool? teleBase,
    bool? teleLoc,
    bool? teleEnv,
    bool? remoteCli,
  }) async {
    flagWrites.add((contact.name, isFavorite, teleBase, teleLoc));
    final i = saved.indexWhere((c) => c.publicKeyHex == contact.publicKeyHex);
    var flags = saved[i].flags;
    int set(int flags, int bit, bool? on) =>
        on == null ? flags : (on ? flags | bit : flags & ~bit);
    flags = set(flags, contactFlagFavorite, isFavorite);
    flags = set(flags, contactFlagTeleBase, teleBase);
    flags = set(flags, contactFlagTeleLoc, teleLoc);
    saved = [...saved]..[i] = saved[i].copyWith(flags: flags);
    notifyListeners();
  }

  @override
  Future<void> setTelemetryModeBase(
    int base,
    int location,
    int env,
    int advert,
  ) async {
    modeBase = base;
    modeLoc = location;
    modeWrites.add((base, location));
    notifyListeners();
  }

  @override
  Future<void> setGps(bool on) async {
    gps = on;
    vars.add('gps:${on ? 1 : 0}');
    notifyListeners();
  }

  @override
  Future<void> setCustomVar(String value) async => vars.add(value);

  void changed() => notifyListeners();
}

/// TRAX mode's parts Trip setup reads, set by the test.
class _Trax extends TraxService {
  _Trax(super.connector);

  DateTime? since;
  DateTime? checked;
  final leftEvents = StreamController<DateTime?>.broadcast();

  @override
  DateTime? get heardSince => since;
  @override
  DateTime? get checkedAt => checked;
  @override
  Stream<DateTime?> get left => leftEvents.stream;

  void changed() => notifyListeners();
}

class _Asks extends RadioAskService {
  _Asks(super.connector);

  final asked = <String>[];
  final answered = <String, RadioAsk>{};

  @override
  void ask(Contact contact) => asked.add(contact.name);
  @override
  RadioAsk? askFor(Contact contact) => answered[contact.publicKeyHex];
}

final _trip = Channel(
  index: 1,
  name: 'Desert trip',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x40 + i)),
);
final _other = Channel(
  index: 2,
  name: 'Club',
  psk: Uint8List.fromList(List.generate(16, (i) => 0x60 + i)),
);

Contact _contact(String name, int b, {int flags = 0}) => Contact(
  publicKey: Uint8List(32)..fillRange(0, 32, b),
  name: name,
  type: advTypeChat,
  flags: flags,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 1,
  lastSeen: DateTime.now(),
);

ChannelMessage _post(
  String sender,
  Channel channel, {
  DateTime? at,
  bool outgoing = false,
}) => ChannelMessage(
  senderKey: null,
  senderName: sender,
  text: 'hi',
  timestamp: at ?? DateTime.now(),
  isOutgoing: outgoing,
  channelIndex: channel.index,
);

/// Past the connector's 50 ms batching of its notifications.
Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 80));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Radio radio;
  late _Trax trax;
  late _Asks asks;
  late TripService trip;
  final bo = _contact('Bo', 0x11);
  final cy = _contact('Cy', 0x22);
  final ed = _contact('Ed', 0x33);
  final end = DateTime.now().add(const Duration(days: 2));

  Future<void> start({
    TraxSetup? setup,
    Duration askAfter = const Duration(minutes: 2),
  }) async {
    trax = _Trax(radio);
    await trax.updateSetup(
      setup ?? TraxSetup(channelKey: _trip.idKey, until: end),
    );
    asks = _Asks(radio);
    trip = TripService(radio, trax, asks, askAfter: askAfter);
    await _settle();
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    radio = _Radio()
      ..channelList = [_trip, _other]
      ..saved = [bo, cy, ed]
      ..history = [
        _post('Bo', _trip),
        _post('cy', _trip),
        _post('Dee', _trip),
        _post(
          'Ed',
          _trip,
          at: DateTime.now().subtract(const Duration(days: 40)),
        ),
        _post('Ed', _other),
        _post('Me', _trip, outgoing: true),
      ];
  });

  tearDown(() {
    trip.dispose();
    trax.dispose();
  });

  test('the members are the trip channel\'s posters of the last 30 days, '
      'matched to contacts by name', () async {
    await start();
    expect(trip.members.map((m) => (m.name, m.contact?.name)), [
      ('Bo', 'Bo'),
      ('Cy', 'Cy'),
      ('Dee', null),
    ], reason: 'Dee is no contact; Ed posted 40 days ago, or elsewhere');
  });

  test('a name two contacts share matches neither', () async {
    radio.saved = [bo, _contact('Bo', 0x44), cy];
    await start();
    expect(trip.members.firstWhere((m) => m.name == 'Bo').contact, isNull);
  });

  test('picking the trip channel is all it takes: location by contact, GPS '
      'on, and each member a favourite allowed to ask', () async {
    await start();
    expect(radio.modeWrites, [(teleModeAllowFlags, teleModeAllowFlags)]);
    expect(radio.vars, ['gps:1']);
    expect(radio.flagWrites, [
      ('Bo', true, true, true),
      ('Cy', true, true, true),
    ]);
    expect(trip.active, isTrue);
    expect(radio.telemetryGrantedTo(radio.saved[0]).location, isTrue);
    expect(radio.telemetryGrantedTo(radio.saved[2]).location, isFalse);
  });

  test('with GPS on already it writes the GPS refresh, and a member already '
      'allowed is left alone', () async {
    radio
      ..gps = true
      ..modeBase = teleModeAllowFlags
      ..modeLoc = teleModeAllowFlags
      ..saved = [
        _contact(
          'Bo',
          0x11,
          flags: contactFlagFavorite | contactFlagTeleBase | contactFlagTeleLoc,
        ),
        cy,
        ed,
      ];
    await start();
    expect(radio.vars, ['gps_interval:0']);
    expect(radio.modeWrites, isEmpty);
    expect(radio.flagWrites, [('Cy', true, true, true)]);
  });

  test('a new poster becomes a member and is allowed at once', () async {
    await start();
    radio.flagWrites.clear();
    radio.incoming.add((message: _post('Ed', _trip), fromBacklog: false));
    await _settle();
    expect(trip.members.map((m) => m.name), contains('Ed'));
    expect(radio.flagWrites, [('Ed', true, true, true)]);
  });

  test('nothing without a trip channel, or with asking off', () async {
    await start(setup: TraxSetup(until: end));
    expect(trip.members, isEmpty);
    expect(radio.flagWrites, isEmpty);
    expect(radio.modeWrites, isEmpty);
    trip.dispose();
    trax.dispose();

    await start(
      setup: TraxSetup(channelKey: _trip.idKey, until: end, askMyRadio: false),
    );
    expect(radio.flagWrites, isEmpty);
    expect(trip.active, isFalse);
  });

  test('a removed member gets their permissions back; added by hand gets '
      'them', () async {
    await start();
    radio.flagWrites.clear();
    trip.removeMember(radio.saved[0]);
    await _settle();
    expect(trip.members.map((m) => m.name), ['Cy', 'Dee']);
    expect(radio.flagWrites, [('Bo', null, false, false)]);

    radio.flagWrites.clear();
    trip.addMember(ed);
    await _settle();
    expect(trip.members.map((m) => m.name), ['Cy', 'Dee', 'Ed']);
    expect(radio.flagWrites, [('Ed', true, true, true)]);
  });

  test('turning asking off puts back the permissions, the privacy settings '
      'and GPS; favourites stay', () async {
    await start();
    radio.flagWrites.clear();
    await trax.updateSetup(trax.setup.copyWith(askMyRadio: false));
    await _settle();
    expect(radio.flagWrites, [
      ('Bo', null, false, false),
      ('Cy', null, false, false),
    ]);
    expect(radio.modeWrites.last, (teleModeDeny, teleModeDeny));
    expect(radio.vars.last, 'gps:0');
    expect(radio.saved[0].isFavorite, isTrue);
    expect(trip.active, isFalse);
  });

  test('Share my location off later is not turned back on by a new '
      'member', () async {
    await start();
    radio.modeLoc = teleModeDeny;
    radio.modeWrites.clear();
    radio.incoming.add((message: _post('Ed', _trip), fromBacklog: false));
    await _settle();
    expect(radio.modeWrites, isEmpty);
    expect(trip.blockedBySharing, isTrue);
  });

  test('Leave after the trip\'s end takes it all back until a new end; a '
      'Leave before the end keeps it', () async {
    await start();
    radio.flagWrites.clear();
    trax.leftEvents.add(end);
    await _settle();
    expect(radio.flagWrites, isEmpty, reason: 'left before the end');

    final past = DateTime.now().subtract(const Duration(hours: 1));
    await trax.updateSetup(trax.setup.copyWith(until: () => past));
    await _settle();
    trax.leftEvents.add(past);
    await _settle();
    expect(radio.flagWrites, [
      ('Bo', null, false, false),
      ('Cy', null, false, false),
    ]);
    expect(trip.active, isFalse);

    // A reconnect doesn't bring them back.
    radio.flagWrites.clear();
    radio.connected = false;
    radio.changed();
    await _settle();
    radio.connected = true;
    radio.changed();
    await _settle();
    expect(radio.flagWrites, isEmpty);

    // The next trip does.
    await trax.updateSetup(trax.setup.copyWith(until: () => end));
    await _settle();
    expect(trip.active, isTrue);
    expect(radio.flagWrites, [
      ('Bo', true, true, true),
      ('Cy', true, true, true),
    ]);
  });

  test('a radio that was away when asking stopped is put back at its next '
      'connect', () async {
    await start();
    radio.connected = false;
    radio.changed();
    await _settle();
    await trax.updateSetup(trax.setup.copyWith(askMyRadio: false));
    await _settle();
    expect(radio.flagWrites.where((w) => w.$3 == false), isEmpty);

    radio.connected = true;
    radio.changed();
    await _settle();
    expect(radio.flagWrites.where((w) => w.$3 == false), hasLength(2));
  });

  test('in TRAX mode, two minutes after a group check, the radios of members '
      'not heard are asked', () async {
    radio
      ..repeat = true
      ..freq = 918000;
    await start(askAfter: const Duration(milliseconds: 150));
    // TRAX mode began after the posts.
    final since = DateTime.now();
    radio.heard[cy.publicKeyHex] = since.add(const Duration(seconds: 1));
    trax
      ..since = since
      ..checked = since;
    trax.changed();
    await _settle();
    expect(asks.asked, isEmpty, reason: 'not yet two minutes');
    await Future<void>.delayed(const Duration(milliseconds: 150));
    expect(asks.asked, ['Bo'], reason: 'Cy was heard; Dee is no contact');
    expect(trip.onTrax(cy), isTrue);
    expect(trip.onTrax(bo), isFalse);

    // Bo's radio answers: on TRAX.
    asks.answered[bo.publicKeyHex] = RadioAsk(bo)
      ..first = RadioAnswer(receivedAt: DateTime.now());
    expect(trip.onTrax(bo), isTrue);
  });
}
