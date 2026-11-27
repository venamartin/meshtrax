import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:traxshare/traxshare.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../models/channel_datagram.dart';
import '../models/contact.dart';
import '../storage/prefs_manager.dart';
import 'trax_service.dart';

/// A trip member's latest location, from the reports their MeshTrax sends
/// on the trip channel in TRAX mode.
class TripPosition {
  const TripPosition({
    required this.prefix,
    required this.lat,
    required this.lon,
    required this.sentAt,
    required this.heardAt,
    this.altitude,
    this.battery,
    this.heading,
    this.speed,
    this.stillSince,
    this.mayBeOld = false,
    this.name,
    this.icon = TraxMapIcon.hike,
    required this.track,
    this.tail = const [],
  });

  /// The first 4 bytes of the sender's key, as 8 hex digits.
  final String prefix;
  final double lat;
  final double lon;
  final int? altitude;
  final int? battery;

  /// Degrees clockwise from north, and metres a second, while moving.
  final double? heading;
  final double? speed;

  /// When they last moved, by this phone's clock, while not moving.
  final DateTime? stillSince;

  /// The sender's radio reading hadn't changed lately: it may be a stored
  /// position, not a live fix.
  final bool mayBeOld;

  /// By the sender's clock.
  final DateTime sentAt;

  /// When this radio heard it, by this phone's clock.
  final DateTime heardAt;

  /// The sender's radio name, from the reports that carry it.
  final String? name;

  /// How they show on the map, as they picked it.
  final TraxMapIcon icon;

  /// The pieces of their track this phone has.
  final MemberTrack track;

  /// The positions reported since the newest piece, each part oldest first.
  /// A part ends where reports stopped.
  final List<List<TrailPoint>> tail;

  /// The way they came, each part oldest first: their track, then the
  /// positions reported since, on from where it ends.
  List<List<TrailPoint>> get line {
    final lines = trackLines(track.inOrder);
    for (final part in tail) {
      if (lines.isNotEmpty &&
          part.isNotEmpty &&
          lines.last.last == part.first) {
        lines.last.addAll(part.skip(1));
      } else {
        lines.add([...part]);
      }
    }
    return lines;
  }

  Uint8List get prefixBytes => Uint8List.fromList([
    for (var i = 0; i < 8; i += 2)
      int.parse(prefix.substring(i, i + 2), radix: 16),
  ]);

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lon': lon,
    'sent': sentAt.millisecondsSinceEpoch,
    'heard': heardAt.millisecondsSinceEpoch,
    'alt': ?altitude,
    'batt': ?battery,
    'hdg': ?heading,
    'spd': ?speed,
    'still': ?stillSince?.millisecondsSinceEpoch,
    if (mayBeOld) 'old': true,
    'name': ?name,
    if (icon != TraxMapIcon.hike) 'icon': icon.name,
    if (!track.isEmpty)
      'track': {
        'keep': track.keepHours,
        'pieces': [
          for (final p in track.inOrder)
            [p.minute, p.endMinute, p.gridM, _points(p.points)],
        ],
      },
    if (tail.isNotEmpty) 'tail': [for (final part in tail) _points(part)],
  };

  static List<List<double>> _points(List<TrailPoint> points) => [
    for (final p in points) [_round(p.lat), _round(p.lon)],
  ];

  static List<TrailPoint> _readPoints(Object? json) => [
    if (json is List)
      for (final p in json)
        if (p case [final num lat, final num lon])
          (lat: lat.toDouble(), lon: lon.toDouble()),
  ];

  static double _round(double v) => (v * 1e5).round() / 1e5;

  static TripPosition? fromJson(String prefix, Object? json) {
    if (json is! Map || prefix.length != 8) return null;
    final lat = json['lat'], lon = json['lon'];
    final sent = json['sent'], heard = json['heard'];
    if (lat is! num || lon is! num || sent is! int || heard is! int) {
      return null;
    }
    final alt = json['alt'], batt = json['batt'], name = json['name'];
    final hdg = json['hdg'], spd = json['spd'], still = json['still'];
    return TripPosition(
      prefix: prefix,
      lat: lat.toDouble(),
      lon: lon.toDouble(),
      sentAt: DateTime.fromMillisecondsSinceEpoch(sent),
      heardAt: DateTime.fromMillisecondsSinceEpoch(heard),
      altitude: alt is int ? alt : null,
      battery: batt is int ? batt : null,
      heading: hdg is num ? hdg.toDouble() : null,
      speed: spd is num ? spd.toDouble() : null,
      stillSince: still is int
          ? DateTime.fromMillisecondsSinceEpoch(still)
          : null,
      mayBeOld: json['old'] == true,
      name: name is String ? name : null,
      icon:
          TraxMapIcon.values.where((i) => i.name == json['icon']).firstOrNull ??
          TraxMapIcon.hike,
      track: switch (json['track']) {
        {'keep': final int keep, 'pieces': final List pieces} => MemberTrack(
          keepHours: keep,
          pieces: {
            for (final p in pieces)
              if (p case [
                final int minute,
                final int end,
                final int grid,
                final List points,
              ])
                minute: TrackPiece(
                  minute: minute,
                  endMinute: end,
                  gridM: grid,
                  points: _readPoints(points),
                ),
          },
        ),
        _ => MemberTrack(),
      },
      tail: [
        if (json['tail'] case final List parts)
          for (final part in parts) _readPoints(part),
      ],
    );
  }
}

/// The trip members' locations, as their MeshTrax sends them to the trip
/// channel in TRAX mode: the latest from each sender, kept per radio for 30
/// days, so a member's last known place stays after their reports stop.
/// Their track is kept as long as their phone says ("Keep my track").
class TripPositions extends ChangeNotifier {
  TripPositions(
    this._connector,
    this._trax, {
    DateTime Function()? clock,
    Random? random,
  }) : _clock = clock ?? DateTime.now,
       _session = (random ?? Random()).nextInt(0x10000) {
    _datagrams = _connector.channelDatagrams.listen(_onDatagram);
    _connector.addListener(_onConnector);
    _expiry = Timer.periodic(_expireEvery, (_) => _expire());
    _onConnector();
  }

  final MeshCoreConnector _connector;
  final TraxService _trax;
  final DateTime Function() _clock;
  final int _session;
  late final StreamSubscription<ChannelDatagram> _datagrams;
  late final Timer _expiry;

  static const keepFor = Duration(days: 30);

  /// Out of TRAX mode, the map shows locations heard this recently.
  static const showFor = Duration(hours: 24);

  /// A report never replaces one sent this much later.
  static const _slack = Duration(seconds: 2);

  /// Reports further apart than this aren't joined on the map.
  static const lineGap = Duration(minutes: 15);

  /// A reported position this close to the line's end isn't added.
  static const _gateM = 25.0;
  static const _maxTailPoints = 1000;

  /// Per member, the oldest pieces going first.
  static const _maxTrackPoints = 5000;
  static const _saveEvery = Duration(seconds: 30);
  static const _expireEvery = Duration(minutes: 5);

  static String keyFor(String radioKey) => 'trip_positions_$radioKey';

  final _byPrefix = <String, TripPosition>{};
  final _askedAt = <String, DateTime>{};
  final _newer = <String, DateTime>{};
  String _radioKey = '';
  Timer? _saveTimer;
  int _seq = 0;

  Iterable<TripPosition> get all => _byPrefix.values;

  /// What the map shows: all of them in TRAX mode, else the last day's.
  Iterable<TripPosition> get shown {
    if (_trax.isOn) return all;
    final since = _clock().subtract(showFor);
    return all.where((p) => p.heardAt.isAfter(since));
  }

  /// Who sends a newer TRAX than this app reads, by the first 4 bytes of
  /// their key, with when they were last heard: their location can't be
  /// shown until this app is updated.
  Map<String, DateTime> get newer => Map.unmodifiable(_newer);

  TripPosition? of(Contact contact) => contact.publicKey.length < 4
      ? null
      : _byPrefix[pubKeyToHex(contact.publicKey.sublist(0, 4))];

  /// Whether this phone can ask a member's MeshTrax for their track: in TRAX
  /// mode, with a trip channel.
  bool get canAskTrack => _trax.isOn && _trax.tripChannel != null;

  /// When this phone last asked [prefix]'s MeshTrax for their track.
  DateTime? askedAt(String prefix) => _askedAt[prefix];

  /// Asks the MeshTrax of [prefix] (8 hex digits), on the trip channel, for
  /// their trail and the pieces of their track this phone lacks; true when
  /// the radio took it.
  Future<bool> askTrack(String prefix) async {
    final trip = _trax.tripChannel;
    final self = _connector.selfPublicKey;
    if (!canAskTrack ||
        trip == null ||
        self == null ||
        self.length < 4 ||
        prefix.length != 8) {
      return false;
    }
    final ask = TraxAsk(
      seq: _seq,
      senderPrefix: Uint8List.fromList(self.sublist(0, 4)),
      session: _session,
      sentAt: _clock(),
      target: Uint8List.fromList([
        for (var i = 0; i < 8; i += 2)
          int.parse(prefix.substring(i, i + 2), radix: 16),
      ]),
      have: _byPrefix[prefix]?.track.held() ?? const [],
    );
    _seq = (_seq + 1) & 0xFF;
    if (!await _connector.sendChannelData(
      trip,
      traxshareDataType,
      ask.encode(),
    )) {
      return false;
    }
    _askedAt[prefix] = _clock();
    notifyListeners();
    return true;
  }

  void _onConnector() {
    final key = _connector.selfPublicKeyHex;
    if (key.isEmpty || key == _radioKey) return;
    // The last radio's latest reports go under its own key first.
    if (_saveTimer?.isActive ?? false) unawaited(_save());
    _saveTimer?.cancel();
    _saveTimer = null;
    _radioKey = key;
    _byPrefix.clear();
    _askedAt.clear();
    _newer.clear();
    final raw = PrefsManager.instance.getString(keyFor(key));
    if (raw != null) {
      try {
        final json = jsonDecode(raw);
        if (json is Map<String, dynamic>) {
          for (final MapEntry(:key, :value) in json.entries) {
            if (TripPosition.fromJson(key, value) case final p?) {
              _byPrefix[key] = p;
            }
          }
        }
      } catch (_) {}
    }
    _prune();
    _expire(notify: false);
    notifyListeners();
  }

  void _onDatagram(ChannelDatagram d) {
    if (d.dataType != traxshareDataType) return;
    final trip = _trax.tripChannel;
    if (trip == null || d.channel.idKey != trip.idKey) return;
    final report = TraxReport.decode(d.payload);
    if (report == null) return _heardNewer(d);
    if (_isMine(report.senderPrefix)) return;
    final prefix = pubKeyToHex(report.senderPrefix);
    final before = _byPrefix[prefix];
    final now = _clock();
    final track = before?.track ?? MemberTrack();
    final block = report.track;
    final grew = block != null && track.add(block);
    if (grew) _trim(track);
    final expired = track.expire(now);
    // Its pieces count, but not its position.
    if (before != null && before.sentAt.isAfter(report.sentAt.add(_slack))) {
      if (grew || expired) _changed();
      return;
    }
    // From the backlog, the radio heard it some time before it was read: the
    // sender's clock says when, unless that is later than now.
    final heardAt = d.fromBacklog && report.sentAt.isBefore(d.receivedAt)
        ? report.sentAt.toLocal()
        : d.receivedAt;
    if (_newer[prefix] case final at? when !at.isAfter(heardAt)) {
      _newer.remove(prefix);
    }
    _byPrefix[prefix] = TripPosition(
      track: track,
      tail: _tail(before, report, track, heardAt),
      prefix: prefix,
      lat: report.lat,
      lon: report.lon,
      sentAt: report.sentAt.toLocal(),
      heardAt: heardAt,
      altitude: report.altitude,
      battery: report.battery,
      heading: report.heading,
      speed: report.speed,
      stillSince: switch (report.stillFor) {
        final still? => heardAt.subtract(still),
        null => null,
      },
      mayBeOld: report.mayBeOld,
      name: report.name ?? before?.name,
      icon: report.icon,
    );
    _prune();
    _changed();
  }

  /// A TRAX version this app doesn't read: only who sent it and when, from
  /// the header every later version starts with.
  void _heardNewer(ChannelDatagram d) {
    final header = TraxHeader.decode(d.payload);
    if (header == null || _isMine(header.senderPrefix)) return;
    final heardAt = d.fromBacklog && header.sentAt.isBefore(d.receivedAt)
        ? header.sentAt.toLocal()
        : d.receivedAt;
    final prefix = pubKeyToHex(header.senderPrefix);
    if (_newer[prefix]?.isAfter(heardAt) ?? false) return;
    _newer[prefix] = heardAt;
    notifyListeners();
  }

  bool _isMine(Uint8List prefix) {
    final self = _connector.selfPublicKey;
    return self != null &&
        self.length >= 4 &&
        listEquals(self.sublist(0, 4), prefix);
  }

  void _changed() {
    _saveTimer ??= Timer(_saveEvery, () {
      _saveTimer = null;
      unawaited(_save());
    });
    notifyListeners();
  }

  /// A report with their newest piece starts the tail again, from that
  /// piece's end; a live position extends it, or starts a new part after a
  /// gap. A position that may be old is left out of it.
  static List<List<TrailPoint>> _tail(
    TripPosition? before,
    TraxReport report,
    MemberTrack track,
    DateTime heardAt,
  ) {
    final here = (lat: report.lat, lon: report.lon);
    final newest = track.inOrder.lastOrNull;
    if (newest != null && report.track?.pieces.first.minute == newest.minute) {
      return [
        if (!report.mayBeOld) [newest.points.last, here],
      ];
    }
    final tail = before?.tail ?? const <List<TrailPoint>>[];
    if (report.mayBeOld) return tail;
    final last = tail.lastOrNull?.lastOrNull;
    final List<List<TrailPoint>> out;
    if (last == null ||
        before == null ||
        before.mayBeOld ||
        heardAt.difference(before.heardAt) > lineGap) {
      out = [
        ...tail,
        [here],
      ];
    } else if (_metres(last, here) < _gateM) {
      return tail;
    } else {
      out = [
        ...tail.sublist(0, tail.length - 1),
        [...tail.last, here],
      ];
    }
    var count = out.fold(0, (n, part) => n + part.length);
    while (count > _maxTailPoints && out.isNotEmpty) {
      count -= out.first.length;
      out.removeAt(0);
    }
    return out;
  }

  static void _trim(MemberTrack track) {
    final pieces = track.inOrder;
    var count = pieces.fold(0, (n, p) => n + p.points.length);
    for (final p in pieces) {
      if (count <= _maxTrackPoints) break;
      track.pieces.remove(p.minute);
      count -= p.points.length;
    }
  }

  /// Each piece goes as long after its last point as its member keeps it,
  /// and the positions since with it once they were heard that long ago.
  void _expire({bool notify = true}) {
    final now = _clock();
    final heardNewer = _newer.length;
    _newer.removeWhere((_, at) => now.difference(at) > showFor);
    var changed = _newer.length != heardNewer;
    for (final MapEntry(:key, :value) in _byPrefix.entries.toList()) {
      changed |= value.track.expire(now);
      final keep = Duration(hours: value.track.keepHours);
      if (value.tail.isNotEmpty && now.difference(value.heardAt) > keep) {
        _byPrefix[key] = TripPosition(
          prefix: value.prefix,
          lat: value.lat,
          lon: value.lon,
          sentAt: value.sentAt,
          heardAt: value.heardAt,
          altitude: value.altitude,
          battery: value.battery,
          heading: value.heading,
          speed: value.speed,
          stillSince: value.stillSince,
          mayBeOld: value.mayBeOld,
          name: value.name,
          icon: value.icon,
          track: value.track,
        );
        changed = true;
      }
    }
    if (changed && notify) _changed();
  }

  static double _metres(TrailPoint a, TrailPoint b) {
    const m = 111320.0;
    final dy = (a.lat - b.lat) * m;
    final dx = (a.lon - b.lon) * m * cos(a.lat * pi / 180);
    return sqrt(dx * dx + dy * dy);
  }

  void _prune() {
    final since = _clock().subtract(keepFor);
    _byPrefix.removeWhere((_, p) => p.heardAt.isBefore(since));
  }

  Future<void> _save() async {
    if (_radioKey.isEmpty) return;
    await PrefsManager.instance.setString(
      keyFor(_radioKey),
      jsonEncode({
        for (final MapEntry(:key, :value) in _byPrefix.entries)
          key: value.toJson(),
      }),
    );
  }

  @override
  void dispose() {
    if (_saveTimer?.isActive ?? false) unawaited(_save());
    _saveTimer?.cancel();
    _expiry.cancel();
    unawaited(_datagrams.cancel());
    _connector.removeListener(_onConnector);
    super.dispose();
  }
}
