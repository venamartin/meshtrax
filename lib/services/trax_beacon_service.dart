import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:traxshare/traxshare.dart';

import '../connector/meshcore_connector.dart';
import '../models/channel_datagram.dart';
import '../utils/app_logger.dart';
import 'trax_service.dart';
import 'trax_track.dart';
import 'trip_service.dart';

enum TraxBeaconState {
  /// Not in TRAX mode, or no trip channel.
  off,

  /// The radio's firmware can't send it.
  unsupported,

  /// The radio has no location to send.
  noLocation,
  sending,
}

/// In TRAX mode, sends this radio's location to the trip channel every
/// [TripService.locationInterval], so the trip sees everyone without
/// asking: with the trail behind it in every 5th report, one older piece of
/// its [track] halfway between trails, and the pieces a member asks for
/// ([TraxAsk]). Only while this phone is connected: the radio sends nothing
/// on its own. On the regular mesh, locations are only asked for.
class TraxBeaconService extends ChangeNotifier {
  TraxBeaconService(
    this._connector,
    this._trax,
    this._trip, {
    Random? random,
    DateTime Function()? clock,
  }) : _random = random ?? Random(),
       _clock = clock ?? DateTime.now {
    track = TraxTrack(_connector, clock: _clock, random: _random)
      ..addListener(notifyListeners);
    _asks = _connector.channelDatagrams.listen(_onDatagram);
    _connector.addListener(_sync);
    _trax.addListener(_sync);
    _sync();
  }

  /// This radio's own way while TRAX mode is on.
  late final TraxTrack track;

  final MeshCoreConnector _connector;
  final TraxService _trax;
  final TripService _trip;
  final Random _random;
  final DateTime Function() _clock;
  late final StreamSubscription<ChannelDatagram> _asks;

  /// The radio's name goes in the first report, then this often.
  static const nameEvery = Duration(minutes: 30);

  /// A reading this recent is sent as it is; an older one is read again.
  static const _readAfter = Duration(seconds: 20);

  /// The trail goes in the first report, then in every [trailEvery]th, and
  /// no sooner than [trailAfter] after the last.
  static const trailEvery = 5;
  static const trailAfter = Duration(minutes: 10);

  /// The pieces an ask wants go a tenth of [interval] apart, or this.
  static const _answerSpacing = Duration(seconds: 3);

  TraxBeaconState _state = TraxBeaconState.off;
  Timer? _timer;
  bool _running = false;
  bool _sending = false;
  bool _disposed = false;
  int _session = 0;
  int _seq = 0;
  DateTime? _nameSentAt;
  DateTime? _sentAt;
  DateTime? _trailSentAt;
  int _sinceTrail = 0;
  bool _olderSent = false;
  bool _trailAsked = false;

  /// The pieces asked for, newest first.
  final _answer = <int>[];

  TraxBeaconState get state => _state;

  /// The latest report the radio took.
  DateTime? get sentAt => _sentAt;

  Duration get interval => _trip.locationInterval;

  void _sync() {
    if (_disposed) return;
    track.keepHours = _trax.setup.keepTrackHours;
    if (_trax.isOn) {
      track.start();
    } else {
      track.stop();
    }
    final c = _connector;
    final wanted =
        _trax.isOn &&
        _trax.tripChannel != null &&
        c.isConnected &&
        c.channelsVerified;
    if (wanted && c.supportsChannelData) {
      if (_running) return;
      _running = true;
      _session = _random.nextInt(0x10000);
      _seq = 0;
      _nameSentAt = null;
      _trailSentAt = null;
      _sinceTrail = 0;
      _olderSent = false;
      // Not with the rest of the trip, as they all reconnect after a switch.
      _schedule(Duration(seconds: 10 + _random.nextInt(21)));
      _setState(TraxBeaconState.sending);
      return;
    }
    _running = false;
    _timer?.cancel();
    _timer = null;
    _trailAsked = false;
    _answer.clear();
    _setState(wanted ? TraxBeaconState.unsupported : TraxBeaconState.off);
  }

  /// A member's ask for this radio's track: the trail soon, then each piece
  /// they lack. One heard while this app was away isn't answered: they ask
  /// again.
  void _onDatagram(ChannelDatagram d) {
    if (!_running || d.fromBacklog || d.dataType != traxshareDataType) return;
    final trip = _trax.tripChannel;
    final key = _connector.selfPublicKey;
    if (trip == null || d.channel.idKey != trip.idKey || key == null) return;
    final ask = TraxAsk.decode(d.payload);
    if (ask == null ||
        key.length < 4 ||
        !listEquals(ask.target, key.sublist(0, 4))) {
      return;
    }
    for (final m in track.missing(ask.have)) {
      if (!_answer.contains(m)) _answer.add(m);
    }
    _answer.sort((a, b) => b.compareTo(a));
    _trailAsked = true;
    if (!_sending) {
      _schedule(Duration(milliseconds: 500 + _random.nextInt(2000)));
    }
  }

  void _schedule(Duration after) {
    _timer?.cancel();
    _timer = Timer(after, () => unawaited(_tick()));
  }

  Future<void> _tick() async {
    if (!_running || _sending) return;
    _sending = true;
    var sent = false;
    try {
      sent = await _send();
    } catch (e) {
      appLogger.warn('TRAX location: $e', tag: 'Trax');
    } finally {
      _sending = false;
    }
    if (!_running || _disposed) return;
    if (sent && (_trailAsked || _answer.isNotEmpty)) {
      final tenth = interval ~/ 10;
      _schedule(tenth > _answerSpacing ? tenth : _answerSpacing);
      return;
    }
    final jitter = 0.8 + 0.4 * _random.nextDouble();
    _schedule(
      Duration(milliseconds: (interval.inMilliseconds * jitter).round()),
    );
  }

  /// True when the radio took a report.
  Future<bool> _send() async {
    final c = _connector;
    final channel = _trax.tripChannel;
    final key = c.selfPublicKey;
    if (channel == null || key == null || key.length < 4) return false;
    await _readPosition();
    final gps = c.gpsOn ? c.selfGps.value : null;
    if (gps == null || !c.hasValidLocation(gps.latitude, gps.longitude)) {
      _setState(TraxBeaconState.noLocation);
      return false;
    }
    final now = _clock();
    final changed = c.selfGpsChangedAt;
    final trailDue =
        _trailAsked ||
        _trailSentAt == null ||
        (_sinceTrail + 1 >= trailEvery &&
            now.difference(_trailSentAt!) >= trailAfter);
    final answering = !trailDue && _answer.isNotEmpty;
    final olderDue =
        !trailDue &&
        !answering &&
        !_olderSent &&
        _sinceTrail + 1 >= (trailEvery + 1) ~/ 2 &&
        now.difference(_trailSentAt!) >= trailAfter ~/ 2;
    // A piece alone goes without the name, to go at its finest.
    final nameDue =
        !answering &&
        !olderDue &&
        (_nameSentAt == null || now.difference(_nameSentAt!) >= nameEvery);
    final name = nameDue ? c.selfName : null;
    final anchor = wirePosition(gps.latitude, gps.longitude);
    final room = TraxReport.trackRoom(name: name);
    final block = trailDue
        ? track.trail(anchor, room)
        : answering
        ? track.piece(_answer.first, anchor, room)
        : olderDue
        ? track.nextOlder(anchor, room)
        : null;
    final motion = track.motion();
    final report = TraxReport(
      seq: _seq,
      senderPrefix: Uint8List.fromList(key.sublist(0, 4)),
      session: _session,
      sentAt: now,
      lat: gps.latitude,
      lon: gps.longitude,
      // Exactly 0 is a radio that has had no fix.
      altitude: gps.altitude == 0 ? null : gps.altitude.round(),
      heading: motion?.heading,
      speed: motion?.speed,
      stillFor: motion?.stillFor,
      fixAge: changed == null ? null : now.difference(changed),
      battery: c.batteryPercent,
      mayBeOld: !c.selfGpsIsFresh,
      requester: true,
      name: name,
      track: block,
    );
    _seq = (_seq + 1) & 0xFF;
    if (!await c.sendChannelData(channel, traxshareDataType, report.encode())) {
      appLogger.warn('TRAX location: the radio did not take it', tag: 'Trax');
      return false;
    }
    _sentAt = now;
    if (nameDue) _nameSentAt = now;
    if (answering) {
      _answer.removeAt(0);
    } else if (trailDue && block != null) {
      _trailAsked = false;
      _trailSentAt = now;
      _sinceTrail = 0;
      _olderSent = false;
      // What it carried at its finest isn't sent again for an ask.
      if (block.gridM == TrackPiece.fineGridM) {
        _answer.removeWhere((m) => block.pieces.any((p) => p.minute == m));
      }
    } else {
      _trailAsked = false;
      _sinceTrail++;
      if (olderDue) _olderSent = true;
    }
    _setState(TraxBeaconState.sending);
    return true;
  }

  /// A fresh reading from the radio, unless the GPS poll just brought one.
  Future<void> _readPosition() async {
    final c = _connector;
    final at = c.selfGps.value?.at;
    if (!c.canAskSelfPosition ||
        (at != null && DateTime.now().difference(at) < _readAfter)) {
      return;
    }
    final read = Completer<void>();
    void onReading() {
      if (!read.isCompleted) read.complete();
    }

    c.selfGps.addListener(onReading);
    try {
      await c.requestSelfPosition();
      await read.future.timeout(const Duration(seconds: 3), onTimeout: () {});
    } finally {
      c.selfGps.removeListener(onReading);
    }
  }

  void _setState(TraxBeaconState state) {
    if (_state == state) return;
    _state = state;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    unawaited(_asks.cancel());
    track.dispose();
    _connector.removeListener(_sync);
    _trax.removeListener(_sync);
    super.dispose();
  }
}
