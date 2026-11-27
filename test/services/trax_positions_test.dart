import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show HitTestResult;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/models/channel.dart';
import 'package:meshtrax/models/channel_datagram.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/map_focus.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/models/radio_settings.dart';
import 'package:meshtrax/models/trax.dart';
import 'package:meshtrax/screens/map_screen.dart';
import 'package:meshtrax/screens/trax_settings_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/services/map_packs_service.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/radio_ask_service.dart';
import 'package:meshtrax/services/trax_beacon_service.dart';
import 'package:meshtrax/services/trax_service.dart';
import 'package:meshtrax/services/trax_track.dart';
import 'package:meshtrax/services/trip_positions.dart';
import 'package:meshtrax/services/trip_service.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/app_map.dart';
import 'package:meshtrax/widgets/map_controls.dart';
import 'package:meshtrax/widgets/speed_card.dart';
import 'package:meshtrax/widgets/trax_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart';
import 'package:traxshare/traxshare.dart';

import '../helpers/map_fakes.dart';

// In TRAX mode every member's MeshTrax sends its radio's location to the
// trip channel, with the trail behind it now and then, and the others keep
// the latest from each.
class _Radio extends MeshCoreConnector {
  bool connected = true;
  List<Channel> channelList = [_trip, _other];
  List<Contact> saved = [];
  bool gps = true;
  bool fresh = true;
  DateTime? changedAt;
  bool datagramsWork = true;
  final datagrams = StreamController<ChannelDatagram>.broadcast(sync: true);
  final sends = <(Channel, int, Uint8List)>[];
  int viewers = 0;
  int speedViewers = 0;
  double? lat;
  double? lon;

  @override
  bool get isConnected => connected;
  @override
  bool get isSynced => true;
  @override
  bool get channelsVerified => true;
  @override
  List<Channel> get channels => channelList;
  @override
  List<Contact> get contacts => saved;
  @override
  Uint8List? get selfPublicKey => _key(0xAB);
  @override
  String get selfPublicKeyHex => pubKeyToHex(_key(0xAB));
  @override
  String? get selfName => 'Trail Radio';
  @override
  double? get selfLatitude => lat;
  @override
  double? get selfLongitude => lon;
  @override
  bool get hasGps => true;
  @override
  bool get gpsOn => gps;
  @override
  bool get selfGpsIsFresh => fresh;
  @override
  DateTime? get selfGpsChangedAt => changedAt;
  @override
  int? get batteryPercent => 81;
  @override
  bool get supportsChannelData => datagramsWork;
  @override
  bool get canAskSelfPosition => false;
  @override
  int get telemetryModeBase => teleModeAllowFlags;
  @override
  int get telemetryModeLoc => teleModeAllowFlags;
  @override
  Stream<ChannelDatagram> get channelDatagrams => datagrams.stream;
  @override
  Stream<({ChannelMessage message, bool fromBacklog})> get channelMessagesIn =>
      const Stream.empty();
  @override
  Future<List<ChannelMessage>> loadChannelMessagesFor(Channel channel) async =>
      const [];
  @override
  DateTime? getLocalDiscoveredTime(String pubKeyHex) => null;
  @override
  Contact? contactByKeyPrefix4(Uint8List prefix) => saved
      .where((c) => listEquals(c.publicKey.sublist(0, 4), prefix))
      .firstOrNull;
  @override
  Future<bool> sendChannelData(
    Channel channel,
    int dataType,
    Uint8List payload,
  ) async {
    sends.add((channel, dataType, payload));
    return true;
  }

  @override
  void addSelfPositionViewer() => viewers++;
  @override
  void removeSelfPositionViewer() => viewers--;
  @override
  void addSpeedViewer() => speedViewers++;
  @override
  void removeSpeedViewer() => speedViewers--;
  @override
  Future<void> setContactFlags(
    Contact contact, {
    bool? isFavorite,
    bool? teleBase,
    bool? teleLoc,
    bool? teleEnv,
    bool? remoteCli,
  }) async {}
  @override
  Future<void> setGps(bool on) async {}
  @override
  Future<void> setCustomVar(String value) async {}
  @override
  List<Contact> get allContacts => saved;
  @override
  Future<void> getChannels({int? maxChannels, bool force = false}) async {}
  @override
  Future<Map<String, List<Message>>> loadPossiblePinMessages(
    Iterable<Contact> contacts,
  ) async => const {};
  @override
  Future<Map<String, List<ChannelMessage>>> loadPossiblePinChannelMessages(
    Iterable<Channel> channels,
  ) async => const {};
  @override
  Stream<
    Map<String, ({ChannelMessage message, int sortUs, ChannelMessage? unread})>
  >
  watchChannelLatest() => const Stream.empty();

  void changed() => notifyListeners();

  int _readings = 0;

  /// A reading from the radio's GPS, a new value every time as the radio's
  /// are: two stamped in one tick of a coarse clock (Windows) would be equal,
  /// and an equal value doesn't notify.
  void read(double lat, double lon) => selfGps.value = (
    latitude: lat,
    longitude: lon,
    altitude: -86,
    at: DateTime.now().add(Duration(microseconds: ++_readings)),
  );
}

class _Trax extends TraxService {
  _Trax(super.connector);

  bool on = true;
  DateTime? since;
  LoRaParams params = const LoRaParams(
    freqKhz: 918000,
    bwHz: 62500,
    sf: 7,
    cr: 5,
  );

  @override
  bool get isOn => on;
  @override
  DateTime? get heardSince => since;
  @override
  LoRaParams? get current => params;

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
  @override
  Iterable<RadioAsk> get located => answered.values;

  void changed() => notifyListeners();
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

Uint8List _key(int b) => Uint8List(32)..fillRange(0, 32, b);

Contact _contact(String name, int b) => Contact(
  publicKey: _key(b),
  name: name,
  type: advTypeChat,
  flags: 0,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 1,
  lastSeen: DateTime.now(),
);

final _t0 = DateTime(2026, 11, 22, 9);
const _here = (lat: 36.4570, lon: -116.8660);

TraxReport _report(
  int b, {
  DateTime? sentAt,
  double lat = 36.4570,
  double lon = -116.8660,
  bool mayBeOld = false,
  String? name,
  TrackBlock? track,
  int? altitude,
  int? battery,
  double? heading,
  double? speed,
  Duration? stillFor,
  TraxMapIcon icon = TraxMapIcon.hike,
}) => TraxReport(
  seq: 0,
  senderPrefix: _key(b).sublist(0, 4),
  session: 7,
  sentAt: sentAt ?? _t0,
  lat: lat,
  lon: lon,
  mayBeOld: mayBeOld,
  requester: true,
  name: name,
  track: track,
  heading: heading,
  speed: speed,
  stillFor: stillFor,
  altitude: altitude,
  battery: battery,
  icon: icon,
);

ChannelDatagram _datagram(
  TraxReport report, {
  Channel? channel,
  int dataType = traxshareDataType,
  DateTime? receivedAt,
  bool fromBacklog = false,
}) => ChannelDatagram(
  channel: channel ?? _trip,
  dataType: dataType,
  payload: report.encode(),
  receivedAt: receivedAt ?? _t0,
  fromBacklog: fromBacklog,
);

/// A packet of a later TRAX version from [b]: the 9-byte header every
/// later version starts with, then [rest].
Uint8List _later(int b, {DateTime? sentAt, List<int> rest = const []}) {
  final out = Uint8List(TraxHeader.size + rest.length)
    ..[0] = 0x21
    ..setRange(1, 5, _key(b))
    ..setRange(TraxHeader.size, TraxHeader.size + rest.length, rest);
  final seconds = (sentAt ?? _t0).millisecondsSinceEpoch ~/ 1000;
  ByteData.sublistView(out).setUint32(5, seconds, Endian.little);
  return out;
}

ChannelDatagram _bytes(
  Uint8List payload, {
  Channel? channel,
  DateTime? receivedAt,
}) => ChannelDatagram(
  channel: channel ?? _trip,
  dataType: traxshareDataType,
  payload: payload,
  receivedAt: receivedAt ?? _t0,
  fromBacklog: false,
);

/// [metres] north of [_here].
TrailPoint _north(double metres) =>
    (lat: _here.lat + metres / 111320, lon: _here.lon);

/// One piece of a member's track, [points] oldest first, from [from] to
/// [to] minutes after [_t0].
TrackBlock _block(
  List<TrailPoint> points, {
  int from = -20,
  int to = 0,
  int gridM = 8,
  int keepHours = 48,
}) => TrackBlock(
  gridM: gridM,
  keepHours: keepHours,
  pieces: [
    TrackPiece(
      minute: TrackPiece.minuteOf(_t0) + from,
      endMinute: TrackPiece.minuteOf(_t0) + to,
      gridM: gridM,
      points: points,
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Radio radio;
  late _Trax trax;
  var now = _t0;
  DateTime clock() => now;
  final bo = _contact('Bo', 0x11);
  final cy = _contact('Cy', 0x22);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    now = _t0;
    radio = _Radio()..saved = [bo, cy];
    trax = _Trax(radio);
    await trax.updateSetup(
      TraxSetup(
        channelKey: _trip.idKey,
        until: _t0.add(const Duration(days: 2)),
      ),
    );
  });

  /// Zigzag north from [_here], a reading every 10 s, every point a
  /// corner: [steps] of them on from step [from].
  void zigzag(FakeAsync async, int steps, {int from = 0}) {
    for (var i = from; i < from + steps; i++) {
      radio.read(
        _north(20.0 * i).lat,
        _here.lon + (i.isEven ? 30 : -30) / 89550,
      );
      async.elapse(const Duration(seconds: 10));
    }
  }

  group('locations heard', () {
    late TripPositions positions;

    setUp(() {
      positions = TripPositions(radio, trax, clock: clock);
    });

    tearDown(() => positions.dispose());

    test('a report on the trip channel is that member\'s location', () {
      radio.datagrams.add(_datagram(_report(0x11, lat: 36.5, lon: -116.9)));

      final p = positions.of(bo)!;
      expect(p.lat, closeTo(36.5, 1e-9));
      expect(p.lon, closeTo(-116.9, 1e-9));
      expect(p.heardAt, _t0);
      expect(positions.of(cy), isNull);
    });

    test('other channels, other data and this radio\'s own are not', () {
      radio.datagrams
        ..add(_datagram(_report(0x11), channel: _other))
        ..add(_datagram(_report(0x11), dataType: 0x1234))
        ..add(_datagram(_report(0xAB)));

      expect(positions.all, isEmpty);
    });

    test('a later TRAX version says only who sent it and when: no location, '
        'and not from this radio or another channel', () {
      radio.datagrams
        ..add(_bytes(_later(0x22, rest: List.filled(30, 0xFF))))
        ..add(_bytes(_later(0x11), channel: _other))
        ..add(_bytes(_later(0xAB)));

      expect(positions.all, isEmpty);
      expect(positions.newer, {'22222222': _t0});
    });

    test('a report this app reads ends it, and it goes a day after they '
        'were last heard', () {
      fakeAsync((async) {
        final positions = TripPositions(
          radio,
          trax,
          clock: () => _t0.add(async.elapsed),
        );
        final minute = _t0.add(const Duration(minutes: 1));
        radio.datagrams
          ..add(_bytes(_later(0x11)))
          ..add(_bytes(_later(0x22)))
          ..add(_datagram(_report(0x11, sentAt: minute), receivedAt: minute));
        expect(positions.newer.keys, ['22222222']);
        expect(positions.of(bo), isNotNull);

        async.elapse(const Duration(hours: 23, minutes: 50));
        expect(positions.newer.keys, ['22222222']);
        async.elapse(const Duration(minutes: 15));
        expect(positions.newer, isEmpty);
        positions.dispose();
      });
    });

    test('an older report never replaces a newer one', () {
      radio.datagrams
        ..add(_datagram(_report(0x11, sentAt: _t0, lat: 36.5)))
        ..add(
          _datagram(
            _report(
              0x11,
              sentAt: _t0.subtract(const Duration(minutes: 1)),
              lat: 36.4,
            ),
          ),
        );

      expect(positions.of(bo)!.lat, closeTo(36.5, 1e-9));
    });

    test('from the backlog, it was heard when it was sent', () {
      final sent = _t0.subtract(const Duration(minutes: 10));
      radio.datagrams.add(
        _datagram(_report(0x11, sentAt: sent), fromBacklog: true),
      );

      expect(positions.of(bo)!.heardAt, sent);
    });

    test('their newest piece starts the line\'s tail again from its end; '
        'live positions extend it, and a gap starts a new part', () {
      radio.datagrams.add(
        _datagram(_report(0x11, track: _block([_north(-400), _north(-200)]))),
      );
      expect(positions.of(bo)!.track.pieces, hasLength(1));
      expect(positions.of(bo)!.line, hasLength(1));
      expect(positions.of(bo)!.line.single, hasLength(3), reason: 'and here');
      expect(
        positions.of(bo)!.line.single.first.lat,
        closeTo(_north(-400).lat, 1e-4),
      );

      DateTime at(int minutes) => _t0.add(Duration(minutes: minutes));
      void heard(int minutes, double north, {bool old = false}) =>
          radio.datagrams.add(
            _datagram(
              _report(
                0x11,
                sentAt: at(minutes),
                lat: _north(north).lat,
                mayBeOld: old,
              ),
              receivedAt: at(minutes),
            ),
          );

      heard(1, 100);
      expect(positions.of(bo)!.line.single, hasLength(4));
      heard(2, 110);
      expect(positions.of(bo)!.line.single, hasLength(4), reason: '10 m');
      heard(3, 900, old: true);
      expect(positions.of(bo)!.line.single, hasLength(4), reason: 'may be old');
      heard(30, 1500);
      expect(positions.of(bo)!.line, hasLength(2), reason: 'after a gap');
    });

    test('which way and how fast while moving; since when, once not', () {
      radio.datagrams.add(_datagram(_report(0x11, heading: 90, speed: 1.5)));
      final moving = positions.all.single;
      expect(moving.heading, 90);
      expect(moving.speed, 1.5);
      expect(moving.stillSince, isNull);
      final back = TripPosition.fromJson(
        moving.prefix,
        jsonDecode(jsonEncode(moving.toJson())),
      )!;
      expect((back.heading, back.speed), (90, 1.5));

      final later = _t0.add(const Duration(minutes: 1));
      radio.datagrams.add(
        _datagram(
          _report(0x11, sentAt: later, stillFor: const Duration(minutes: 80)),
          receivedAt: later,
        ),
      );
      final still = positions.all.single;
      expect(still.stillSince, later.subtract(const Duration(minutes: 80)));
      expect((still.heading, still.speed), (null, null));
    });

    test('their icon is their latest report\'s, kept across restarts; the '
        'hiker from a build before 243', () async {
      radio.datagrams.add(_datagram(_report(0x11, icon: TraxMapIcon.boat)));
      expect(positions.of(bo)!.icon, TraxMapIcon.boat);
      positions.dispose();
      positions = TripPositions(radio, trax, clock: clock);
      expect(positions.of(bo)!.icon, TraxMapIcon.boat, reason: 'restart');
      radio.datagrams.add(_datagram(_report(0x11)));
      expect(positions.of(bo)!.icon, TraxMapIcon.hike);
    });

    test('kept per radio across restarts, for 30 days', () async {
      radio.datagrams.add(
        _datagram(
          _report(
            0x11,
            name: 'Bo',
            track: _block([_north(-400), _north(-200)]),
          ),
        ),
      );
      positions.dispose();

      positions = TripPositions(radio, trax, clock: clock);
      expect(positions.of(bo)!.name, 'Bo');
      expect(positions.of(bo)!.track.pieces, hasLength(1), reason: 'track');
      expect(positions.of(bo)!.line.single, hasLength(3), reason: 'and tail');

      positions.dispose();
      now = _t0.add(const Duration(days: 31));
      positions = TripPositions(radio, trax, clock: clock);
      expect(positions.all, isEmpty);
    });

    test('pieces add up by their minute: one reaching later, or as far on '
        'a finer grid, takes its place; an older report brings its pieces, '
        'not its position', () {
      final minute = TrackPiece.minuteOf(_t0);
      void heard(TrackBlock block, {int seconds = 0, double north = 0}) =>
          radio.datagrams.add(
            _datagram(
              _report(
                0x11,
                sentAt: _t0.add(Duration(seconds: seconds)),
                lat: _north(north).lat,
                track: block,
              ),
            ),
          );
      TrackPiece only() => positions.of(bo)!.track.pieces.values.single;

      heard(_block([_north(-400), _north(-200)], to: -5, gridM: 24));
      heard(
        _block([_north(-400), _north(-200), _north(-100)], gridM: 24),
        seconds: 30,
      );
      expect((only().endMinute, only().gridM), (minute, 24), reason: 'later');
      heard(_block([_north(-400), _north(-150), _north(-100)]), seconds: 60);
      expect(only().gridM, 8, reason: 'finer');
      heard(_block([_north(-400), _north(-100)], gridM: 40), seconds: 90);
      expect(only().gridM, 8, reason: 'not a coarser one');

      heard(
        _block([_north(-3000), _north(-2500)], from: -90, to: -60),
        seconds: -600,
        north: -2500,
      );
      expect(positions.of(bo)!.track.pieces, hasLength(2));
      expect(positions.of(bo)!.lat, closeTo(_here.lat, 1e-6), reason: 'older');
    });

    test('each piece goes as many hours after its last point as its member '
        'keeps it, the positions since with it; their place stays', () {
      fakeAsync((async) {
        final positions = TripPositions(
          radio,
          trax,
          clock: () => _t0.add(async.elapsed),
        );
        radio.datagrams.add(
          _datagram(
            _report(
              0x11,
              track: _block([_north(-400), _north(-200)], keepHours: 6),
            ),
          ),
        );
        async.elapse(const Duration(hours: 5, minutes: 55));
        expect(positions.of(bo)!.track.pieces, hasLength(1));
        expect(positions.of(bo)!.line, isNotEmpty);
        async.elapse(const Duration(minutes: 15));
        expect(positions.of(bo)!.track.isEmpty, isTrue);
        expect(positions.of(bo)!.line, isEmpty, reason: 'the tail too');
        expect(positions.of(bo)!.lat, closeTo(_here.lat, 1e-6));
        positions.dispose();
      });
    });

    test('asking a member for their track: on the trip channel, with the '
        'pieces held at their finest', () async {
      final minute = TrackPiece.minuteOf(_t0);
      radio.datagrams
        ..add(
          _datagram(
            _report(
              0x11,
              track: _block([_north(-400), _north(-200)], from: -60, to: -40),
            ),
          ),
        )
        ..add(
          _datagram(
            _report(
              0x11,
              track: _block([_north(-200), _north(0)], from: -40, gridM: 24),
            ),
          ),
        );
      expect(positions.canAskTrack, isTrue);
      expect(await positions.askTrack('11111111'), isTrue);
      final (channel, type, payload) = radio.sends.single;
      expect((channel, type), (_trip, traxshareDataType));
      final ask = TraxAsk.decode(payload)!;
      expect(ask.target, _key(0x11).sublist(0, 4));
      expect(ask.senderPrefix, _key(0xAB).sublist(0, 4));
      expect(ask.have, [minute - 60], reason: 'not the coarse one');
      expect(positions.askedAt('11111111'), _t0);

      trax.on = false;
      expect(positions.canAskTrack, isFalse);
      expect(await positions.askTrack('11111111'), isFalse);
      expect(radio.sends, hasLength(1));
    });
  });

  group('the trip', () {
    late TripPositions positions;
    late _Asks asks;
    late TripService trip;

    setUp(() async {
      positions = TripPositions(radio, trax, clock: clock);
      asks = _Asks(radio);
      trip = TripService(radio, trax, asks, positions: positions, clock: clock);
    });

    tearDown(() {
      trip.dispose();
      positions.dispose();
    });

    test('whoever sends a location is a trip member, by contact or by the '
        'name in the report', () {
      radio.datagrams
        ..add(_datagram(_report(0x22)))
        ..add(_datagram(_report(0x55, name: 'Dee')));

      expect(trip.members.map((m) => (m.name, m.contact?.name)), [
        ('Cy', 'Cy'),
        ('Dee', null),
      ]);
    });

    test('a location counts as heard on TRAX', () {
      trax.since = _t0.subtract(const Duration(minutes: 5));
      expect(trip.onTrax(cy), isFalse);
      radio.datagrams.add(_datagram(_report(0x22)));
      expect(trip.onTrax(cy), isTrue);
    });

    test('every 30 s per person, stretched by a slower preset\'s airtime', () {
      radio.datagrams.add(_datagram(_report(0x22)));
      expect(trip.locationInterval, const Duration(minutes: 1));
      radio.datagrams
        ..add(_datagram(_report(0x11)))
        ..add(_datagram(_report(0x55, name: 'Dee')))
        ..add(_datagram(_report(0x66, name: 'Eve')));
      expect(trip.locationInterval, const Duration(seconds: 150));
      expect(
        TripService.reportAirtimeMs(trax.params),
        referenceReportAirtimeMs,
      );

      trax.params = const LoRaParams(
        freqKhz: 918000,
        bwHz: 250000,
        sf: 11,
        cr: 5,
      );
      expect(TripService.reportAirtimeMs(trax.params), 519);
      expect(trip.locationInterval.inSeconds, 363);
    });
  });

  test('a member silent for three intervals gets their radio asked, then '
      'every 10 minutes', () {
    fakeAsync((async) {
      now = _t0;
      DateTime fake() => _t0.add(async.elapsed);
      final positions = TripPositions(radio, trax, clock: fake);
      final asks = _Asks(radio);
      final trip = TripService(
        radio,
        trax,
        asks,
        positions: positions,
        clock: fake,
      );
      trax.since = _t0;
      radio.datagrams.add(_datagram(_report(0x22)));
      trax.changed();
      async.elapse(const Duration(minutes: 2, seconds: 50));
      expect(asks.asked, isEmpty, reason: '3 × 1 min not up');

      async.elapse(const Duration(seconds: 40));
      expect(asks.asked, ['Cy']);
      async.elapse(const Duration(minutes: 9));
      expect(asks.asked, ['Cy']);
      async.elapse(const Duration(minutes: 1, seconds: 30));
      expect(asks.asked, ['Cy', 'Cy']);

      radio.datagrams.add(
        _datagram(_report(0x22, sentAt: fake()), receivedAt: fake()),
      );
      async.elapse(const Duration(minutes: 2));
      expect(asks.asked, ['Cy', 'Cy'], reason: 'heard again');
      trip.dispose();
      positions.dispose();
    });
  });

  group('sending', () {
    test('in TRAX mode the radio\'s location goes to the trip channel, '
        'about every interval', () {
      fakeAsync((async) {
        DateTime fake() => _t0.add(async.elapsed);
        final positions = TripPositions(radio, trax, clock: fake);
        final trip = TripService(
          radio,
          trax,
          _Asks(radio),
          positions: positions,
          clock: fake,
        );
        radio.read(36.4570, -116.8660);
        radio.changedAt = _t0;
        final beacon = TraxBeaconService(
          radio,
          trax,
          trip,
          random: Random(1),
          clock: fake,
        );
        expect(beacon.state, TraxBeaconState.sending);
        async.elapse(const Duration(seconds: 9));
        expect(radio.sends, isEmpty, reason: 'not before 10 s');
        async.elapse(const Duration(seconds: 22));
        expect(radio.sends, hasLength(1));

        final (channel, type, payload) = radio.sends.single;
        expect(channel, _trip);
        expect(type, traxshareDataType);
        final r = TraxReport.decode(payload)!;
        expect(r.senderPrefix, _key(0xAB).sublist(0, 4));
        expect(r.lat, closeTo(36.4570, 1e-9));
        expect(r.altitude, -86);
        expect(r.battery, 81);
        expect(r.requester, isTrue);
        expect(r.mayBeOld, isFalse);
        expect(r.name, 'Trail Radio');

        // Two people: every minute, ±20 %.
        async.elapse(const Duration(seconds: 72));
        expect(radio.sends, hasLength(2));
        expect(TraxReport.decode(radio.sends.last.$3)!.name, isNull);

        trax.on = false;
        trax.changed();
        expect(beacon.state, TraxBeaconState.off);
        async.elapse(const Duration(minutes: 5));
        expect(radio.sends, hasLength(2));
        beacon.dispose();
        trip.dispose();
        positions.dispose();
      });
    });

    test('reports say which way and how fast, then how long since the last '
        'move', () {
      fakeAsync((async) {
        DateTime fake() => _t0.add(async.elapsed);
        final positions = TripPositions(radio, trax, clock: fake);
        final trip = TripService(
          radio,
          trax,
          _Asks(radio),
          positions: positions,
          clock: fake,
        );
        final beacon = TraxBeaconService(
          radio,
          trax,
          trip,
          random: Random(1),
          clock: fake,
        );
        var north = 0.0;
        void step(double metres) {
          north += metres;
          radio.read(_north(north).lat, _here.lon);
          async.elapse(const Duration(seconds: 10));
        }

        // North at 3 m/s.
        while (radio.sends.length < 2) {
          step(30);
        }
        final moving = TraxReport.decode(radio.sends.last.$3)!;
        expect(moving.heading, 0);
        expect(moving.speed, 3);
        expect(moving.stillFor, isNull);

        while (radio.sends.length < 5) {
          step(0);
        }
        final still = TraxReport.decode(radio.sends.last.$3)!;
        expect((still.heading, still.speed), (null, null));
        expect(still.stillFor!.inMinutes, greaterThanOrEqualTo(2));
        beacon.dispose();
        trip.dispose();
        positions.dispose();
      });
    });

    test('nothing goes without a location, or from older firmware', () {
      fakeAsync((async) {
        final trip = TripService(radio, trax, _Asks(radio));
        final beacon = TraxBeaconService(radio, trax, trip, random: Random(1));
        async.elapse(const Duration(seconds: 31));
        expect(beacon.state, TraxBeaconState.noLocation);
        expect(radio.sends, isEmpty);

        beacon.dispose();
        radio.datagramsWork = false;
        final old = TraxBeaconService(radio, trax, trip, random: Random(1));
        expect(old.state, TraxBeaconState.unsupported);
        async.elapse(const Duration(minutes: 2));
        expect(radio.sends, isEmpty);
        old.dispose();
        trip.dispose();
      });
    });

    test('the trail goes in the first report, then every 5th, no sooner '
        'than 10 minutes after the last', () {
      fakeAsync((async) {
        DateTime fake() => _t0.add(async.elapsed);
        final trip = TripService(radio, trax, _Asks(radio), clock: fake);
        var north = 0.0;
        // Walking north, read every 10 s.
        Timer.periodic(const Duration(seconds: 10), (_) {
          north += 30;
          radio.read(_north(north).lat, _here.lon);
        });
        final beacon = TraxBeaconService(
          radio,
          trax,
          trip,
          random: Random(2),
          clock: fake,
        );
        expect(radio.viewers, 1, reason: 'reading every 10 s');
        final trails = <int>[];
        for (var i = 0; i < 16; i++) {
          final before = radio.sends.length;
          while (radio.sends.length == before) {
            async.elapse(const Duration(seconds: 5));
          }
          final r = TraxReport.decode(radio.sends.last.$3)!;
          if (r.track case final track?) {
            trails.add(i);
            final points = track.pieces.single.points;
            expect(points.first.lat, lessThan(r.lat), reason: 'behind');
            expect(points.length, lessThanOrEqualTo(2), reason: 'DP');
          }
        }
        // The first report with a trail to send; in the first only when the
        // track already had one.
        expect(trails.first, lessThanOrEqualTo(1));
        expect(trails.length, greaterThanOrEqualTo(2));
        for (var i = 1; i < trails.length; i++) {
          expect(trails[i] - trails[i - 1], greaterThanOrEqualTo(5));
        }
        expect(
          radio.sends.every((s) => s.$3.length <= TraxReport.maxSize),
          isTrue,
        );
        beacon.dispose();
        expect(radio.viewers, 0);
        trip.dispose();
      });
    });

    test('between trails one older piece goes, halfway, alone and without '
        'the name', () {
      fakeAsync((async) {
        DateTime fake() => _t0.add(async.elapsed);
        final trip = TripService(radio, trax, _Asks(radio), clock: fake);
        final beacon = TraxBeaconService(
          radio,
          trax,
          trip,
          random: Random(2),
          clock: fake,
        );
        // Enough pieces that a trail carries two or more.
        zigzag(async, 180);
        radio.sends.clear();
        zigzag(async, 300, from: 180);
        DateTime? trailAt;
        var olderSince = 0;
        var older = 0;
        for (final (_, _, payload) in radio.sends) {
          final r = TraxReport.decode(payload)!;
          final pieces = r.track?.pieces.length ?? 0;
          if (pieces >= 2) {
            if (trailAt != null) expect(olderSince, 1, reason: 'one between');
            trailAt = r.sentAt;
            olderSince = 0;
          } else if (pieces == 1) {
            expect(r.name, isNull);
            if (trailAt != null) {
              expect(
                r.sentAt.difference(trailAt),
                greaterThanOrEqualTo(const Duration(minutes: 5)),
              );
            }
            olderSince++;
            older++;
          }
        }
        expect(older, greaterThanOrEqualTo(3));
        expect(
          radio.sends.every((s) => s.$3.length <= TraxReport.maxSize),
          isTrue,
        );
        beacon.dispose();
        trip.dispose();
      });
    });

    test('a member\'s ask: the trail within seconds, then each piece they '
        'lack, newest first, a tenth of the interval apart; not one heard '
        'while away, nor one for another radio', () {
      fakeAsync((async) {
        DateTime fake() => _t0.add(async.elapsed);
        final trip = TripService(radio, trax, _Asks(radio), clock: fake);
        final beacon = TraxBeaconService(
          radio,
          trax,
          trip,
          random: Random(2),
          clock: fake,
        );
        zigzag(async, 300);
        final minutes = beacon.track.missing(const []);
        expect(minutes.length, greaterThanOrEqualTo(3));
        void ask(int target, {List<int> have = const [], bool away = false}) =>
            radio.datagrams.add(
              ChannelDatagram(
                channel: _trip,
                dataType: traxshareDataType,
                payload: TraxAsk(
                  seq: 1,
                  senderPrefix: _key(0x11).sublist(0, 4),
                  session: 3,
                  sentAt: fake(),
                  target: _key(target).sublist(0, 4),
                  have: have,
                ).encode(),
                receivedAt: fake(),
                fromBacklog: away,
              ),
            );
        List<TraxReport> sent() => [
          for (final (_, _, payload) in radio.sends)
            if (TraxReport.decode(payload) case final r? when r.track != null)
              r,
        ];

        radio.sends.clear();
        ask(0x22);
        ask(0xAB, away: true);
        async.elapse(const Duration(seconds: 3));
        expect(sent(), isEmpty);

        ask(0xAB, have: [minutes.last]);
        async.elapse(const Duration(seconds: 3));
        expect(sent().single.track!.pieces.first.minute, minutes.first);
        async.elapse(const Duration(minutes: 2));
        final answers = sent().skip(1).toList();
        expect(
          [for (final r in answers) r.track!.pieces.single.minute],
          minutes.sublist(0, minutes.length - 1),
          reason: 'all but the one held, newest first',
        );
        for (var i = 1; i < answers.length; i++) {
          expect(
            answers[i].sentAt.difference(answers[i - 1].sentAt).inSeconds,
            greaterThanOrEqualTo(6),
          );
        }
        for (final r in answers) {
          expect(r.track!.gridM, TrackPiece.fineGridM);
          expect(r.name, isNull);
        }
        beacon.dispose();
        trip.dispose();
      });
    });

    test(
      'Keep my track comes from TRAX settings: 48 hours unless set',
      () async {
        expect(const TraxSetup().keepTrackHours, 48);
        TraxSetup back(Map<String, dynamic> json) =>
            TraxSetup.fromJson(jsonDecode(jsonEncode(json)));
        expect(
          back(const TraxSetup(keepTrackHours: 12).toJson()).keepTrackHours,
          12,
        );
        expect(back({'keep_track_hours': 5}).keepTrackHours, 48, reason: 'no');
        final trip = TripService(radio, trax, _Asks(radio));
        final beacon = TraxBeaconService(radio, trax, trip, random: Random(1));
        expect(beacon.track.keepHours, 48);
        await trax.updateSetup(trax.setup.copyWith(keepTrackHours: 168));
        expect(beacon.track.keepHours, 168);
        beacon.dispose();
        trip.dispose();
      },
    );

    test('Your icon comes from TRAX settings, the hiker unless set, and goes '
        'in every report', () async {
      expect(const TraxSetup().icon, TraxMapIcon.hike);
      TraxSetup back(Map<String, dynamic> json) =>
          TraxSetup.fromJson(jsonDecode(jsonEncode(json)));
      expect(
        back(const TraxSetup(icon: TraxMapIcon.boat).toJson()).icon,
        TraxMapIcon.boat,
      );
      expect(back({'icon': 'sled'}).icon, TraxMapIcon.hike);
      await trax.updateSetup(trax.setup.copyWith(icon: TraxMapIcon.vehicle));
      fakeAsync((async) {
        DateTime fake() => _t0.add(async.elapsed);
        final trip = TripService(radio, trax, _Asks(radio), clock: fake);
        radio.read(36.4570, -116.8660);
        final beacon = TraxBeaconService(
          radio,
          trax,
          trip,
          random: Random(1),
          clock: fake,
        );
        async.elapse(const Duration(minutes: 3));
        expect(radio.sends.length, greaterThanOrEqualTo(2));
        for (final (_, _, payload) in radio.sends) {
          expect(TraxReport.decode(payload)!.icon, TraxMapIcon.vehicle);
        }
        beacon.dispose();
        trip.dispose();
      });
    });
  });

  group('the track', () {
    test('a point every 25 m, a break after 2 minutes without a live '
        'reading or at a jump', () {
      fakeAsync((async) {
        final track = TraxTrack(radio, clock: () => _t0.add(async.elapsed))
          ..start();
        void walk(double north) {
          radio.read(_north(north).lat, _here.lon);
          async.elapse(const Duration(seconds: 10));
        }

        walk(0);
        walk(10);
        walk(30);
        walk(60);
        expect(track.recent.single, hasLength(3), reason: '0, 30, 60');
        expect(track.recent.single.last.lat, closeTo(_north(60).lat, 1e-9));

        radio.fresh = false;
        for (var i = 0; i < 13; i++) {
          walk(60);
        }
        radio.fresh = true;
        walk(500);
        walk(530);
        expect(track.recent, hasLength(2), reason: 'no live reading for 2 min');
        walk(5530);
        walk(5560);
        expect(track.recent, hasLength(3), reason: '500 m/s is a jump');
        expect(track.missing(const []), hasLength(3), reason: 'three pieces');
        track.dispose();
      });
    });

    test(
      'a piece closes once it would not fit a report at its finest, and '
      'the next starts where it ended; the trail starts with the open one',
      () {
        fakeAsync((async) {
          final track = TraxTrack(radio, clock: () => _t0.add(async.elapsed))
            ..start();
          zigzag(async, 300);
          final minutes = track.missing(const []);
          expect(minutes.length, greaterThanOrEqualTo(3));
          final here = radio.selfGps.value!;
          final anchor = wirePosition(here.latitude, here.longitude);
          final room = TraxReport.trackRoom();
          final pieces = [
            for (final m in minutes.reversed)
              track.piece(m, anchor, room)!.pieces.single,
          ];
          for (var i = 1; i < pieces.length; i++) {
            expect(pieces[i].points.first, pieces[i - 1].points.last);
            expect(pieces[i].minute, greaterThan(pieces[i - 1].minute));
          }
          for (final m in minutes.skip(1)) {
            final alone = track.piece(m, anchor, room)!;
            expect(alone.gridM, TrackPiece.fineGridM, reason: 'at its finest');
            expect(alone.encode(anchor).length, lessThanOrEqualTo(room));
          }
          expect(track.recent, hasLength(1), reason: 'one line');
          final trail = track.trail(
            anchor,
            TraxReport.trackRoom(name: 'Trail Radio'),
          )!;
          expect(trail.pieces.first.minute, minutes.first);
          expect(trail.pieces.length, greaterThanOrEqualTo(2));
          track.dispose();
        });
      },
    );

    test('each piece goes Keep my track\'s hours after its last point', () {
      fakeAsync((async) {
        final track = TraxTrack(radio, clock: () => _t0.add(async.elapsed))
          ..start();
        void walk(double north) {
          radio.read(_north(north).lat, _here.lon);
          async.elapse(const Duration(seconds: 10));
        }

        walk(0);
        walk(30);
        walk(60);
        radio.fresh = false;
        for (var i = 0; i < 13; i++) {
          walk(60);
        }
        radio.fresh = true;
        walk(500);
        walk(530);
        expect(track.missing(const []), hasLength(2));
        track.keepHours = 6;
        async.elapse(const Duration(hours: 5, minutes: 58));
        expect(track.missing(const []), hasLength(1), reason: 'the first');
        async.elapse(const Duration(minutes: 5));
        expect(track.missing(const []), isEmpty);
        expect(track.recent, isEmpty);
        track.dispose();
      });
    });

    test('kept across restarts in its pieces; an older app\'s points start '
        'it over', () {
      fakeAsync((async) {
        DateTime fake() => _t0.add(async.elapsed);
        var track = TraxTrack(radio, clock: fake)..start();
        zigzag(async, 200);
        final pieces = track.missing(const []);
        final line = track.recent.single;
        track.dispose();
        async.flushMicrotasks();

        track = TraxTrack(radio, clock: fake)..start();
        expect(track.missing(const []), pieces);
        expect(track.recent.single, hasLength(line.length));
        expect(track.recent.single.last.lat, closeTo(line.last.lat, 1e-5));
        track.dispose();
        async.flushMicrotasks();

        unawaited(
          PrefsManager.instance.setString(
            TraxTrack.keyFor(radio.selfPublicKeyHex),
            jsonEncode([
              [
                [36.457, -116.866, 0],
                [36.458, -116.866, 30000],
              ],
            ]),
          ),
        );
        async.flushMicrotasks();
        track = TraxTrack(radio, clock: fake)..start();
        expect(track.recent, isEmpty);
        track.dispose();
      });
    });

    test('heading and speed over 50 m or more while moving; how long since '
        'the last point once none was kept for 2 minutes', () {
      fakeAsync((async) {
        final track = TraxTrack(radio, clock: () => _t0.add(async.elapsed))
          ..start();
        void walk(double north) {
          radio.read(_north(north).lat, _here.lon);
          async.elapse(const Duration(seconds: 10));
        }

        walk(0);
        expect(track.motion(), (heading: null, speed: null, stillFor: null));
        walk(15);
        walk(30);
        walk(45);
        walk(60);
        // Kept at 0, 30 and 60 m; measured from 0 m, 40 s before.
        final moving = track.motion()!;
        expect(moving.heading, closeTo(0, 1e-6));
        expect(moving.speed, closeTo(1.5, 1e-6));
        expect(moving.stillFor, isNull);

        for (var i = 0; i < 12; i++) {
          walk(60);
        }
        expect(track.motion()!.stillFor, const Duration(seconds: 130));
        expect(track.motion()!.speed, isNull);
        track.dispose();
      });
    });

    test('nothing before the reading changes', () {
      fakeAsync((async) {
        radio.fresh = false;
        final track = TraxTrack(radio, clock: () => _t0.add(async.elapsed))
          ..start();
        radio.read(_here.lat, _here.lon);
        async.elapse(const Duration(seconds: 10));
        expect(track.recent, isEmpty);
        expect(track.missing(const []), isEmpty);
        track.dispose();
      });
    });
  });

  // Opened from the TRAX sheet on a member, the map shows their trail over
  // your own track, with their own marker as the pin; their info says when
  // they were last heard, which way they go, how fast and how high.
  group('on the map', () {
    late Directory tmp;
    late MapPacksService maps;
    late _Asks asks;
    late TripPositions positions;
    late TripService trip;
    late TraxBeaconService beacon;

    setUp(() async {
      tmp = await Directory.systemTemp.createTemp('traxtrails');
      maps = MapPacksService(
        manager: PackManager(Directory('${tmp.path}/packs')),
        downloader: _NoDownloads(),
        cacheDir: tmp,
        styles: StyleRegistry(MemoryStyles()),
      );
    });
    tearDown(() => tmp.delete(recursive: true));

    // Made in the test itself, so their timers run on its clock.
    void startServices() {
      asks = _Asks(radio);
      positions = TripPositions(radio, trax, clock: clock);
      trip = TripService(radio, trax, asks, positions: positions, clock: clock);
      beacon = TraxBeaconService(radio, trax, trip, clock: clock);
    }

    Future<void> stopServices(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      beacon.dispose();
      trip.dispose();
      positions.dispose();
      asks.dispose();
      await tester.pump(const Duration(seconds: 1));
    }

    Future<void> pumpApp(WidgetTester tester, Widget home) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MeshCoreConnector>.value(value: radio),
            ChangeNotifierProvider(
              create: (_) => AppSettingsService()..setMapShowRepeaters(true),
            ),
            ChangeNotifierProvider(create: (_) => UiViewStateService()),
            ChangeNotifierProvider<MapPacksService>.value(value: maps),
            ChangeNotifierProvider.value(value: PathGraphService()),
            ChangeNotifierProvider<TraxService>.value(value: trax),
            ChangeNotifierProvider<RadioAskService>.value(value: asks),
            ChangeNotifierProvider.value(value: positions),
            ChangeNotifierProvider.value(value: trip),
            ChangeNotifierProvider.value(value: beacon),
          ],
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: home,
          ),
        ),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    List<MapOverlay> overlays(WidgetTester tester) =>
        tester.widget<AppMap>(find.byType(AppMap)).overlays;
    MapMarker marker(WidgetTester tester, String id) =>
        overlays(tester).whereType<MapMarker>().firstWhere((o) => o.id == id);

    testWidgets('a member shown on the map: their card, their trail over '
        'your own track, their marker for the pin; the trail stays once the '
        'card is closed, and a tap on the marker opens it again', (
      tester,
    ) async {
      startServices();
      // Your own way: 300 m east, a reading every 30 s.
      for (var m = 0; m <= 300; m += 100) {
        now = now.add(const Duration(seconds: 30));
        radio.read(_here.lat, _here.lon + m / 89550);
        await tester.pump();
      }
      radio.datagrams.add(
        _datagram(
          _report(0x11, track: _block([_north(600), _north(300)])),
          receivedAt: now,
        ),
      );
      await pumpApp(
        tester,
        MapScreen(
          focus: MapFocusMember(
            bo.publicKeyHex.substring(0, 8),
            ll.LatLng(_here.lat, _here.lon),
          ),
        ),
      );

      MapLine? line(String id) =>
          overlays(tester)
              .whereType<MapLine>()
              .where((o) => o.id == id)
              .firstOrNull;
      final ids = [for (final o in overlays(tester)) o.id];
      expect(ids, isNot(contains('highlight')));
      expect(ids, contains('trip:11111111'));
      expect(marker(tester, 'trip:11111111').label, 'Bo', reason: 'name only');
      expect(line('trail:of:0')!.points, hasLength(3), reason: 'his trail');
      expect(line('trail:self:0')!.points, hasLength(4), reason: 'your way');

      final card = find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('Bo'),
      );
      expect(card, findsOneWidget);
      expect(overlays(tester).map((o) => o.id), isNot(contains('sheet-pin')));
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(card, findsNothing);
      expect(line('trail:of:0'), isNotNull);
      expect(line('trail:self:0'), isNotNull);

      marker(tester, 'trip:11111111').onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(card, findsOneWidget);
      expect(line('trail:of:0'), isNotNull);
      await stopServices(tester);
    });

    List<String> ids(WidgetTester tester) => [
      for (final o in overlays(tester)) o.id,
    ];

    testWidgets('a member has one pin, with their name, at the newest place '
        'known of them: no node or radio answer pin of their own', (
      tester,
    ) async {
      final boOnMap = bo.copyWith(
        latitude: 36.44,
        longitude: -116.88,
        lastSeen: _t0.subtract(const Duration(hours: 1)),
      );
      final cyOnMap = cy.copyWith(latitude: 36.45, longitude: -116.87);
      radio.saved = [boOnMap, cyOnMap];
      startServices();
      radio.datagrams.add(_datagram(_report(0x11), receivedAt: now));
      await pumpApp(tester, const MapScreen());

      double lat() => marker(tester, 'trip:11111111').position.latitude;
      expect(ids(tester), isNot(contains('node:${boOnMap.publicKeyHex}')));
      expect(marker(tester, 'trip:11111111').label, 'Bo');
      expect(lat(), closeTo(36.4570, 1e-6), reason: 'TRAX, newer than advert');
      expect(
        ids(tester),
        contains('node:${cyOnMap.publicKeyHex}'),
        reason: 'not in the group',
      );

      asks
        ..answered[boOnMap.publicKeyHex] = (RadioAsk(boOnMap)
          ..first = RadioAnswer(
            receivedAt: _t0.add(const Duration(minutes: 5)),
            position: (lat: 36.4610, lon: -116.8600, altitude: 120),
          ))
        ..changed();
      await tester.pump();
      expect(ids(tester), isNot(contains('ask:${boOnMap.publicKeyHex}')));
      expect(lat(), closeTo(36.4610, 1e-6), reason: 'his radio\'s answer');
      await stopServices(tester);
    });

    testWidgets('in TRAX mode a trip member\'s pin is theirs before their '
        'first TRAX location, at their advert; out of it, their node\'s', (
      tester,
    ) async {
      final cyOnMap = cy.copyWith(latitude: 36.45, longitude: -116.87);
      radio.saved = [bo, cyOnMap];
      await tester.runAsync(
        () => trax.updateSetup(
          TraxSetup(
            channelKey: _trip.idKey,
            until: _t0.add(const Duration(days: 2)),
            added: {cyOnMap.publicKeyHex},
          ),
        ),
      );
      startServices();
      await pumpApp(tester, const MapScreen());

      expect(ids(tester), isNot(contains('node:${cyOnMap.publicKeyHex}')));
      expect(marker(tester, 'trip:22222222').label, 'Cy');
      expect(
        marker(tester, 'trip:22222222').position.latitude,
        closeTo(36.45, 1e-6),
      );

      trax
        ..on = false
        ..changed();
      await tester.pump();
      expect(ids(tester), isNot(contains('trip:22222222')));
      expect(ids(tester), contains('node:${cyOnMap.publicKeyHex}'));
      await stopServices(tester);
    });

    group('the map follows', () {
      OfflineMapController map(WidgetTester tester) =>
          tester.widget<AppMap>(find.byType(AppMap)).controller!;

      Future<void> settle(WidgetTester tester) async {
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      // Where [p] is on the screen, and the middle of the map that a sheet
      // leaves, or of the whole map.
      (double, double) whereAndMiddle(WidgetTester tester, TrailPoint p) {
        final top = tester.getTopLeft(find.byType(AppMap)).dy;
        final sheet = find.byType(BottomSheet);
        final bottom = sheet.evaluate().isEmpty
            ? tester.getBottomLeft(find.byType(AppMap)).dy
            : tester.getTopLeft(sheet).dy;
        final at = map(tester).toScreen(LatLng(p.lat, p.lon))!;
        return (top + at.dy, (top + bottom) / 2);
      }

      Future<void> drag(WidgetTester tester) async {
        await tester.drag(find.byType(AppMap), const Offset(0, 120));
        await settle(tester);
      }

      testWidgets('you after My location, as you move, until the map is '
          'dragged; a sheet about something else holds it', (tester) async {
        startServices();
        radio
          ..lat = _here.lat
          ..lon = _here.lon;
        await pumpApp(tester, const MapScreen());
        Future<void> move(TrailPoint p) async {
          radio
            ..lat = p.lat
            ..lon = p.lon
            ..changed();
          await settle(tester);
        }

        bool following() =>
            tester.widget<MapControls>(find.byType(MapControls)).following;
        expect(following(), isFalse);
        await tester.tap(find.byTooltip('My location'));
        await settle(tester);
        expect(following(), isTrue);

        await move(_north(500));
        var (at, middle) = whereAndMiddle(tester, _north(500));
        expect(at, closeTo(middle, 1));

        // A sheet about a point low on the map moves the map to show it, and
        // holds it there even as you move; once it closes, the map is back.
        Future<void> sheetLow() async {
          final b = map(tester).visibleBounds!;
          tester.widget<AppMap>(find.byType(AppMap)).onLongPress!(
            LatLng(b.south + (b.north - b.south) * 0.1, (b.west + b.east) / 2),
          );
          await settle(tester);
          expect(find.text('Share marker here'), findsOneWidget);
        }

        Future<void> closeSheet() async {
          await tester.tap(find.text('Cancel'));
          await settle(tester);
        }

        await sheetLow();
        expect(
          whereAndMiddle(tester, _north(500)).$1,
          isNot(closeTo(whereAndMiddle(tester, _north(500)).$2, 1)),
          reason: 'moved to show the point',
        );
        await closeSheet();
        (at, middle) = whereAndMiddle(tester, _north(500));
        expect(at, closeTo(middle, 1), reason: 'back once it closed');

        await sheetLow();
        final held = map(tester).camera!.center;
        await move(_north(700));
        expect(map(tester).camera!.center, held, reason: 'held by the sheet');
        await closeSheet();
        (at, middle) = whereAndMiddle(tester, _north(700));
        expect(at, closeTo(middle, 1), reason: 'back where you are now');

        await drag(tester);
        expect(following(), isFalse);
        final left = map(tester).camera!.center;
        await move(_north(1000));
        expect(map(tester).camera!.center, left);
        await stopServices(tester);
      });

      // Martin, 2026-11-26: speed, altitude and heading in the lower left
      // while the map keeps you in the middle, gone once it is dragged.
      testWidgets('your speed while it follows you: above the group button, '
          'alone out of TRAX mode, gone while the reading may be old and '
          'after a drag', (tester) async {
        startServices();
        radio
          ..lat = _here.lat
          ..lon = _here.lon
          ..read(_here.lat, _here.lon);
        await pumpApp(tester, const MapScreen());
        double creditsLeft() =>
            tester.widget<AppMap>(find.byType(AppMap)).leftControlsWidth;
        expect(find.byType(SpeedCard), findsNothing);
        expect(creditsLeft(), MapControls.width);

        await tester.tap(find.byTooltip('My location'));
        await settle(tester);
        expect(find.byType(SpeedCard), findsOneWidget);
        expect(radio.speedViewers, 1);
        expect(creditsLeft(), MapControls.speedWidth);
        final card = find.byType(SpeedCard);
        // Not moving yet: just the altitude.
        expect(
          find.descendant(of: card, matching: find.text('-86 m')),
          findsOneWidget,
        );
        final group = find.byTooltip('TRAX group');
        expect(
          tester.getBottomLeft(card).dy,
          lessThan(tester.getTopLeft(group).dy),
        );
        expect(
          tester.getTopLeft(card).dx,
          closeTo(tester.getTopLeft(group).dx, 0.5),
        );

        // Martin: hidden rather than grey; the grey dot says it.
        radio
          ..fresh = false
          ..changed();
        await settle(tester);
        expect(card, findsNothing);
        expect(radio.speedViewers, 0);
        expect(creditsLeft(), MapControls.width);
        radio
          ..fresh = true
          ..changed();
        await settle(tester);
        expect(card, findsOneWidget);
        expect(radio.speedViewers, 1);

        trax
          ..on = false
          ..changed();
        await settle(tester);
        expect(group, findsNothing);
        expect(
          tester.getBottomLeft(card).dy,
          closeTo(tester.getBottomLeft(find.byTooltip('Map layers')).dy, 0.5),
        );
        expect(creditsLeft(), MapControls.speedWidth);

        await drag(tester);
        expect(find.byType(SpeedCard), findsNothing);
        expect(radio.speedViewers, 0);
        expect(creditsLeft(), 0);
        await stopServices(tester);
      });

      testWidgets('a tapped member as they move: above their card, then '
          'with it closed and their trail kept, until the map is dragged', (
        tester,
      ) async {
        startServices();
        radio.datagrams.add(_datagram(_report(0x11), receivedAt: now));
        await pumpApp(tester, const MapScreen());
        var sent = _t0;
        Future<void> report(TrailPoint p) async {
          sent = sent.add(const Duration(seconds: 30));
          now = now.add(const Duration(seconds: 30));
          radio.datagrams.add(
            _datagram(
              _report(0x11, sentAt: sent, lat: p.lat, lon: p.lon),
              receivedAt: now,
            ),
          );
          await settle(tester);
        }

        marker(tester, 'trip:11111111').onTap!();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Bo'), findsOneWidget);
        await report(_north(400));
        var (at, middle) = whereAndMiddle(tester, _north(400));
        expect(at, closeTo(middle, 1), reason: 'above the card');

        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Bo'), findsNothing);
        (at, middle) = whereAndMiddle(tester, _north(400));
        expect(at, closeTo(middle, 1), reason: 'the whole map\'s middle');
        await report(_north(800));
        (at, middle) = whereAndMiddle(tester, _north(800));
        expect(at, closeTo(middle, 1), reason: 'the card closed');
        expect(
          overlays(tester).map((o) => o.id),
          contains('trail:of:0'),
          reason: 'their trail',
        );

        await drag(tester);
        final left = map(tester).camera!.center;
        await report(_north(1200));
        expect(map(tester).camera!.center, left);
        await stopServices(tester);
      });

      testWidgets('the TRAX group, from a button at the bottom left in TRAX '
          'mode: by name, how far and when heard, those with no location '
          'last; a pick opens their card with the map on them', (
        tester,
      ) async {
        // "7m ago" counts by the phone's own clock.
        now = DateTime.now();
        DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
        await tester.runAsync(
          () => trax.updateSetup(
            TraxSetup(
              channelKey: _trip.idKey,
              until: now.add(const Duration(days: 2)),
              added: {cy.publicKeyHex},
            ),
          ),
        );
        radio
          ..saved = [bo.copyWith(lastSeen: ago(60)), cy]
          ..lat = _here.lat
          ..lon = _here.lon;
        startServices();
        const boAt = (lat: 36.4650, lon: -116.8560);
        radio.datagrams
          ..add(
            _datagram(
              _report(0x11, sentAt: ago(7), lat: boAt.lat, lon: boAt.lon),
              receivedAt: ago(7),
            ),
          )
          ..add(
            _datagram(
              _report(0x55, name: 'Dee', sentAt: ago(3), lat: 36.4480),
              receivedAt: ago(3),
            ),
          );
        await pumpApp(tester, const MapScreen());

        final button = find.byTooltip('TRAX group');
        final at = tester.getCenter(button);
        expect(at.dx, lessThan(100), reason: 'at the left');
        expect(
          tester.getBottomLeft(button).dy,
          closeTo(tester.getBottomLeft(find.byTooltip('Map layers')).dy, 0.5),
          reason: 'level with the layers button',
        );
        expect(
          tester.widget<AppMap>(find.byType(AppMap)).leftControlsWidth,
          MapControls.width,
          reason: 'the credits keep clear',
        );
        // The row the buttons share lets taps through to the map between.
        bool reachesMap(Offset at) {
          final result = HitTestResult();
          WidgetsBinding.instance.hitTestInView(result, at, tester.view.viewId);
          final mapBox = tester.renderObject(find.byType(AppMap));
          return result.path.any((e) => e.target == mapBox);
        }

        expect(reachesMap(Offset(400, at.dy)), isTrue);
        expect(reachesMap(at), isFalse);

        await tester.tap(button);
        await settle(tester);
        Finder inSheet(String text) => find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text(text),
        );
        expect(inSheet('TRAX group'), findsOneWidget);
        double y(String text) => tester.getTopLeft(inSheet(text)).dy;
        expect(y('Bo'), lessThan(y('Dee')));
        expect(y('Dee'), lessThan(y('Cy: no location yet')));
        expect(
          find.textContaining(RegExp(r'^\S+\s\S+ NE · 7m ago$')),
          findsOneWidget,
          reason: 'Bo',
        );
        expect(
          find.textContaining(RegExp(r'^\S+\s\S+ S · 3m ago$')),
          findsOneWidget,
          reason: 'Dee',
        );

        await tester.tap(inSheet('Bo'));
        await settle(tester);
        await settle(tester);
        expect(inSheet('TRAX group'), findsNothing);
        expect(inSheet('Bo'), findsOneWidget, reason: 'his card');
        expect(find.text('Chat'), findsOneWidget);
        final (y0, middle) = whereAndMiddle(tester, boAt);
        expect(y0, closeTo(middle, 1), reason: 'above his card');

        await tester.tapAt(const Offset(10, 10));
        await settle(tester);
        trax
          ..on = false
          ..changed();
        await settle(tester);
        expect(button, findsNothing);
        expect(
          tester.widget<AppMap>(find.byType(AppMap)).leftControlsWidth,
          0,
        );
        await stopServices(tester);
      });

      testWidgets('the TRAX group says whom a later TRAX version keeps off '
          'the map: Update MeshTrax to see them', (tester) async {
        now = DateTime.now();
        DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
        await tester.runAsync(
          () => trax.updateSetup(
            TraxSetup(
              channelKey: _trip.idKey,
              until: now.add(const Duration(days: 2)),
              added: {cy.publicKeyHex},
            ),
          ),
        );
        startServices();
        radio.datagrams
          ..add(_bytes(_later(0x22, sentAt: ago(2)), receivedAt: ago(2)))
          ..add(_bytes(_later(0x77, sentAt: ago(1)), receivedAt: ago(1)));
        await pumpApp(tester, const MapScreen());

        await tester.tap(find.byTooltip('TRAX group'));
        await settle(tester);
        expect(find.text('Update MeshTrax to see Cy'), findsOneWidget);
        expect(find.text('Cy: no location yet'), findsNothing);
        expect(find.text('2m ago'), findsOneWidget);
        expect(
          find.text('Update MeshTrax to see someone on this trip'),
          findsOneWidget,
        );
        expect(find.text('1m ago'), findsOneWidget);
        await stopServices(tester);
      });
    });

    testWidgets('a member\'s card: who and when heard, then which way, how '
        'fast or how long stopped, how high and their battery, each named on '
        'a long-press; Chat and Ask only for a contact', (tester) async {
      startServices();
      radio.datagrams
        ..add(
          _datagram(
            _report(0x11, heading: 90, speed: 1.5, altitude: 512, battery: 64),
            receivedAt: now,
          ),
        )
        // Dee isn't a contact on this radio: all there is, is what she sent.
        ..add(
          _datagram(
            _report(
              0x55,
              name: 'Dee',
              lat: 36.46,
              stillFor: const Duration(minutes: 12),
              altitude: 300,
              battery: 15,
            ),
            receivedAt: now,
          ),
        );
      await pumpApp(tester, const MapScreen());

      Future<void> open(String id) async {
        marker(tester, id).onTap!();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      Future<void> close() async {
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      await open('trip:11111111');
      for (final text in [
        'Bo',
        'E 90°',
        '5 km/h',
        '512 m',
        '64%',
        'Chat',
        'Ask Bo\'s radio',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      for (final label in ['Heading', 'Speed', 'Elevation', 'Radio battery']) {
        expect(find.byTooltip(label), findsOneWidget, reason: label);
      }
      expect(find.byTooltip('Not moving'), findsNothing);
      expect(find.byIcon(Icons.battery_alert), findsNothing);
      expect(find.byIcon(Icons.battery_4_bar), findsOneWidget, reason: '64%');
      await close();

      await open('trip:55555555');
      for (final text in ['Dee', '300 m', '15%']) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // Minutes by the phone's own clock, which this test doesn't set.
      expect(find.textContaining(RegExp(r'^Stopped \S+ min$')), findsOneWidget);
      expect(find.byTooltip('Not moving'), findsOneWidget);
      expect(find.byIcon(Icons.battery_alert), findsOneWidget, reason: 'low');
      expect(find.byTooltip('Heading'), findsNothing);
      expect(find.text('Chat'), findsNothing);
      expect(find.text('Ask Dee\'s radio'), findsNothing);
      await close();
      await stopServices(tester);
    });

    testWidgets('in TRAX mode an ask brings their track too: with their '
        'radio for a contact, alone on the card of a member who isn\'t one, '
        'and from the group for one with no location yet', (tester) async {
      await tester.runAsync(
        () => trax.updateSetup(trax.setup.copyWith(added: {cy.publicKeyHex})),
      );
      startServices();
      radio.datagrams.add(
        _datagram(_report(0x55, name: 'Dee', lat: 36.46), receivedAt: now),
      );
      await pumpApp(tester, const MapScreen());
      Future<void> settle() async {
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      TraxAsk lastAsk() => TraxAsk.decode(radio.sends.last.$3)!;

      marker(tester, 'trip:55555555').onTap!();
      await settle();
      expect(find.text('Ask Dee\'s radio'), findsNothing);
      await tester.tap(find.text('Ask for track'));
      await settle();
      expect(lastAsk().target, _key(0x55).sublist(0, 4));
      expect(find.textContaining('Track asked'), findsOneWidget);
      await tester.tapAt(const Offset(10, 10));
      await settle();

      await tester.tap(find.byTooltip('TRAX group'));
      await settle();
      await tester.tap(find.text('Cy: no location yet'));
      await settle();
      await settle();
      expect(asks.asked, ['Cy']);
      expect(lastAsk().target, _key(0x22).sublist(0, 4));
      expect(
        find.text(
          'Also asked their phone for their track; it shows on the map.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Close'));
      await settle();
      await stopServices(tester);
    });

    testWidgets('a member shows as the icon they picked: their pin, their '
        'card and the TRAX group', (tester) async {
      startServices();
      radio.datagrams.add(
        _datagram(
          _report(0x55, name: 'Dee', lat: 36.46, icon: TraxMapIcon.boat),
          receivedAt: now,
        ),
      );
      await pumpApp(tester, const MapScreen());
      Future<void> settle() async {
        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
      }

      final pin = marker(tester, 'trip:55555555');
      expect(
        ((pin.child! as Container).child! as Icon).icon,
        Icons.directions_boat,
      );
      final avatar = find.descendant(
        of: find.byType(CircleAvatar),
        matching: find.byIcon(Icons.directions_boat),
      );
      pin.onTap!();
      await settle();
      expect(avatar, findsOneWidget, reason: 'card');
      await tester.tapAt(const Offset(10, 10));
      await settle();
      await tester.tap(find.byTooltip('TRAX group'));
      await settle();
      expect(avatar, findsOneWidget, reason: 'list');
      await stopServices(tester);
    });

    testWidgets('Your icon in TRAX settings: the hiker unless picked, from '
        'seven', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      startServices();
      await pumpApp(tester, const TraxSettingsScreen());
      const hint = 'How the trip sees you on the map.';
      expect(find.text('Hike · $hint'), findsOneWidget);
      await tester.tap(find.text('Your icon'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      for (final name in [
        'Hike',
        'Vehicle',
        'Boat',
        'Motorcycle',
        'Bicycle',
        'Aircraft',
        'Camp',
      ]) {
        expect(find.text(name), findsOneWidget, reason: name);
      }
      await tester.tap(find.text('Boat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(trax.setup.icon, TraxMapIcon.boat);
      expect(find.text('Boat · $hint'), findsOneWidget);
      await stopServices(tester);
    });

    testWidgets('a person\'s info: last heard, which way, how fast, how high '
        'and their radio\'s battery; line of sight only for others', (
      tester,
    ) async {
      final hill = Contact(
        publicKey: _key(0x44),
        name: 'Hill',
        type: advTypeRepeater,
        flags: 0,
        pathLength: 0,
        path: Uint8List(0),
        pathHashSize: 1,
        latitude: 36.47,
        longitude: -116.85,
        lastSeen: DateTime.now(),
      );
      // Bo's advert has a place too, where line of sight used to be offered.
      final boOnMap = Contact(
        publicKey: _key(0x11),
        name: 'Bo',
        type: advTypeChat,
        flags: 0,
        pathLength: 0,
        path: Uint8List(0),
        pathHashSize: 1,
        latitude: 36.44,
        longitude: -116.88,
        lastSeen: _t0.subtract(const Duration(hours: 1)),
      );
      radio.saved = [boOnMap, cy, hill];
      startServices();
      radio.datagrams.add(
        _datagram(
          _report(0x11, heading: 90, speed: 1.5, altitude: 512, battery: 64),
          receivedAt: now,
        ),
      );
      await pumpApp(tester, const MapScreen());

      marker(tester, 'trip:11111111').onLongPress!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      for (final label in [
        'Last heard',
        'Heading',
        'Speed',
        'Elevation',
        'Radio battery',
      ]) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.text('E 90°'), findsOneWidget);
      expect(find.text('5 km/h'), findsOneWidget);
      expect(find.text('512 m'), findsOneWidget);
      expect(find.text('64%'), findsOneWidget);
      expect(find.text('Line of sight'), findsNothing);
      await tester.tap(find.text('Close'));
      await tester.pump(const Duration(milliseconds: 300));

      marker(tester, 'node:${hill.publicKeyHex}').onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Line of sight'), findsOneWidget);
      expect(find.text('Heading'), findsNothing);
      await tester.tap(find.text('Close'));
      await tester.pump(const Duration(milliseconds: 300));
      await stopServices(tester);
    });

    testWidgets('the TRAX sheet lists the trip: when each member was heard, '
        'how long ago and how far, with a tap to their trail; or why there '
        'is no location', (tester) async {
      // "7m ago" counts by the phone's own clock.
      now = DateTime.now();
      DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
      // Out of the test's own clock, as in setUp: the trip's end timer.
      await tester.runAsync(
        () => trax.updateSetup(
          TraxSetup(
            channelKey: _trip.idKey,
            until: now.add(const Duration(days: 2)),
            added: {cy.publicKeyHex},
          ),
        ),
      );
      trax.since = ago(30);
      radio
        ..lat = _here.lat
        ..lon = _here.lon;
      startServices();
      radio.datagrams
        ..add(
          _datagram(
            _report(
              0x11,
              sentAt: ago(7),
              lat: 36.4650,
              lon: -116.8560,
              mayBeOld: true,
            ),
            receivedAt: ago(7),
          ),
        )
        ..add(
          _datagram(
            _report(0x55, name: 'Dee', sentAt: ago(3), lat: 36.4480),
            receivedAt: ago(3),
          ),
        );
      await pumpApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTraxSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('2 of 3 on TRAX'), findsOneWidget);
      expect(
        find.textContaining(RegExp(r' · 7m ago · \S+\s\S+ NE · may be old$')),
        findsOneWidget,
        reason: 'Bo',
      );
      expect(
        find.textContaining(RegExp(r' · 3m ago · \S+\s\S+ S$')),
        findsOneWidget,
        reason: 'Dee, by the name in the report',
      );
      expect(find.text('Cy: not heard yet'), findsOneWidget);

      await tester.tap(find.text('Bo'));
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      // No map behind the sheet: a map opens over the screen.
      final map = tester.widget<MapScreen>(find.byType(MapScreen));
      expect(map.overScreen, isTrue);
      final focus = map.focus! as MapFocusMember;
      expect(focus.prefix, bo.publicKeyHex.substring(0, 8));
      expect(focus.place.latitude, closeTo(36.4650, 1e-4));
      expect(find.byType(TraxSheet), findsNothing);
      await stopServices(tester);
    });

    testWidgets('the TRAX sheet says whom a later TRAX version keeps off the '
        'map', (tester) async {
      now = DateTime.now();
      DateTime ago(int minutes) => now.subtract(Duration(minutes: minutes));
      await tester.runAsync(
        () => trax.updateSetup(
          TraxSetup(
            channelKey: _trip.idKey,
            until: now.add(const Duration(days: 2)),
            added: {cy.publicKeyHex},
          ),
        ),
      );
      startServices();
      radio.datagrams
        ..add(_bytes(_later(0x22, sentAt: ago(2)), receivedAt: ago(2)))
        ..add(_bytes(_later(0x77, sentAt: ago(1)), receivedAt: ago(1)));
      await pumpApp(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showTraxSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Update MeshTrax to see Cy'), findsOneWidget);
      expect(find.textContaining(RegExp(r' · 2m ago$')), findsOneWidget);
      expect(
        find.text('Update MeshTrax to see someone on this trip'),
        findsOneWidget,
      );
      expect(find.textContaining(RegExp(r' · 1m ago$')), findsOneWidget);
      await stopServices(tester);
    });

    // The sheet's member opened a second map over the map (Martin,
    // 2026-11-24): now their card, on the map the sheet was opened from.
    testWidgets('a member in the TRAX sheet over the map: their card on that '
        'map, not a second one', (tester) async {
      now = DateTime.now();
      await tester.runAsync(
        () => trax.updateSetup(
          TraxSetup(
            channelKey: _trip.idKey,
            until: now.add(const Duration(days: 2)),
          ),
        ),
      );
      trax.since = now.subtract(const Duration(minutes: 30));
      startServices();
      radio.datagrams.add(
        _datagram(
          _report(0x11, sentAt: now.subtract(const Duration(minutes: 2))),
          receivedAt: now.subtract(const Duration(minutes: 2)),
        ),
      );
      await pumpApp(tester, const MapScreen());
      unawaited(showTraxSheet(tester.element(find.byType(AppMap))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(
        find.descendant(of: find.byType(TraxSheet), matching: find.text('Bo')),
      );
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(MapScreen, skipOffstage: false), findsOneWidget);
      expect(find.byType(TraxSheet), findsNothing);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Bo'),
        ),
        findsOneWidget,
        reason: 'their card',
      );
      await stopServices(tester);
    });
  });
}
