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
    this.line = const [],
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

  /// The way they came, each part oldest first: their latest trail, then
  /// the positions reported since. A part ends where reports stopped.
  final List<List<TrailPoint>> line;

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
    if (line.isNotEmpty)
      'line': [
        for (final part in line)
          [
            for (final p in part) [_round(p.lat), _round(p.lon)],
          ],
      ],
  };

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
      line: [
        if (json['line'] case final List parts)
          for (final part in parts)
            if (part is List)
              [
                for (final p in part)
                  if (p case [final num lat, final num lon])
                    (lat: lat.toDouble(), lon: lon.toDouble()),
              ],
      ],
    );
  }
}

/// The trip members' locations, as their MeshTrax sends them to the trip
/// channel in TRAX mode: the latest from each sender, kept per radio for 30
/// days, so a member's last known place stays after their reports stop.
class TripPositions extends ChangeNotifier {
  TripPositions(this._connector, this._trax, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    _datagrams = _connector.channelDatagrams.listen(_onDatagram);
    _connector.addListener(_onConnector);
    _onConnector();
  }

  final MeshCoreConnector _connector;
  final TraxService _trax;
  final DateTime Function() _clock;
  late final StreamSubscription<ChannelDatagram> _datagrams;

  static const keepFor = Duration(days: 30);

  /// Out of TRAX mode, the map shows locations heard this recently.
  static const showFor = Duration(hours: 24);

  /// A report never replaces one sent this much later.
  static const _slack = Duration(seconds: 2);

  /// Reports further apart than this aren't joined on the map.
  static const lineGap = Duration(minutes: 15);

  /// A reported position this close to the line's end isn't added.
  static const _gateM = 25.0;
  static const _maxLinePoints = 1000;
  static const _saveEvery = Duration(seconds: 30);

  static String keyFor(String radioKey) => 'trip_positions_$radioKey';

  final _byPrefix = <String, TripPosition>{};
  String _radioKey = '';
  Timer? _saveTimer;

  Iterable<TripPosition> get all => _byPrefix.values;

  /// What the map shows: all of them in TRAX mode, else the last day's.
  Iterable<TripPosition> get shown {
    if (_trax.isOn) return all;
    final since = _clock().subtract(showFor);
    return all.where((p) => p.heardAt.isAfter(since));
  }

  TripPosition? of(Contact contact) => contact.publicKey.length < 4
      ? null
      : _byPrefix[pubKeyToHex(contact.publicKey.sublist(0, 4))];

  void _onConnector() {
    final key = _connector.selfPublicKeyHex;
    if (key.isEmpty || key == _radioKey) return;
    // The last radio's latest reports go under its own key first.
    if (_saveTimer?.isActive ?? false) unawaited(_save());
    _saveTimer?.cancel();
    _saveTimer = null;
    _radioKey = key;
    _byPrefix.clear();
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
    notifyListeners();
  }

  void _onDatagram(ChannelDatagram d) {
    if (d.dataType != traxshareDataType) return;
    final trip = _trax.tripChannel;
    if (trip == null || d.channel.idKey != trip.idKey) return;
    final report = TraxReport.decode(d.payload);
    if (report == null) return;
    final self = _connector.selfPublicKey;
    if (self != null &&
        self.length >= 4 &&
        listEquals(self.sublist(0, 4), report.senderPrefix)) {
      return;
    }
    final prefix = pubKeyToHex(report.senderPrefix);
    final before = _byPrefix[prefix];
    if (before != null && before.sentAt.isAfter(report.sentAt.add(_slack))) {
      return;
    }
    // From the backlog, the radio heard it some time before it was read: the
    // sender's clock says when, unless that is later than now.
    final heardAt = d.fromBacklog && report.sentAt.isBefore(d.receivedAt)
        ? report.sentAt.toLocal()
        : d.receivedAt;
    _byPrefix[prefix] = TripPosition(
      line: _line(before, report, heardAt),
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
    );
    _prune();
    _saveTimer ??= Timer(_saveEvery, () {
      _saveTimer = null;
      unawaited(_save());
    });
    notifyListeners();
  }

  /// A trail replaces the line; a live position extends it, or starts a
  /// new part after a gap. A position that may be old is left out of it.
  static List<List<TrailPoint>> _line(
    TripPosition? before,
    TraxReport report,
    DateTime heardAt,
  ) {
    final here = (lat: report.lat, lon: report.lon);
    if (report.trail case final trail?) {
      return [
        [...trail.points.reversed, here],
      ];
    }
    final line = before?.line ?? const <List<TrailPoint>>[];
    if (report.mayBeOld) return line;
    final last = line.lastOrNull?.lastOrNull;
    final List<List<TrailPoint>> out;
    if (last == null ||
        before == null ||
        before.mayBeOld ||
        heardAt.difference(before.heardAt) > lineGap) {
      out = [
        ...line,
        [here],
      ];
    } else if (_metres(last, here) < _gateM) {
      return line;
    } else {
      out = [
        ...line.sublist(0, line.length - 1),
        [...line.last, here],
      ];
    }
    var count = out.fold(0, (n, part) => n + part.length);
    while (count > _maxLinePoints && out.isNotEmpty) {
      count -= out.first.length;
      out.removeAt(0);
    }
    return out;
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
    unawaited(_datagrams.cancel());
    _connector.removeListener(_onConnector);
    super.dispose();
  }
}
