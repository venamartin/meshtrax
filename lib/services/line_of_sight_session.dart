import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:traxlos/traxlos.dart';

import '../models/app_settings.dart';
import '../utils/app_logger.dart';
import 'app_settings_service.dart';
import 'line_of_sight.dart';
import 'map_packs_service.dart';

/// The antenna heights to choose from at each end.
enum AntennaKind { handHeld, vehicle, raised }

/// One end's antenna: a preset, or raised to a height typed in.
class Antenna {
  final AntennaKind kind;

  /// The raised antenna's height, metres.
  final double raisedM;

  const Antenna(this.kind, {required this.raisedM});

  static const handHeldM = 1.5;
  static const vehicleM = 2.5;

  /// A raised antenna starts at 20 ft, or 6 m.
  static double defaultRaisedM(UnitSystem units) =>
      units == UnitSystem.imperial ? 20 * 0.3048 : 6;

  double get metres => switch (kind) {
    AntennaKind.handHeld => handHeldM,
    AntennaKind.vehicle => vehicleM,
    AntennaKind.raised => raisedM,
  };

  Antenna withKind(AntennaKind kind) => Antenna(kind, raisedM: raisedM);

  @override
  bool operator ==(Object other) =>
      other is Antenna && other.kind == kind && other.raisedM == raisedM;

  @override
  int get hashCode => Object.hash(kind, raisedM);
}

enum LosPlaceKind { me, contact, point }

/// How your position came to be: the radio's GPS, the position the radio
/// had before its GPS read anything this connection, or one set by hand.
enum MyPosition { gps, notYetGps, byHand }

/// One end of a line, or the middle of a radio reach.
class LosPlace {
  final LosPlaceKind kind;
  final LatLng position;

  /// A contact's or a place's name; a point without one shows its
  /// position.
  final String? name;

  /// A contact's public key.
  final String? key;
  final bool repeater;

  /// Set for a contact whose position is only a guess, from the repeaters
  /// it was heard through (their names): line of sight leaves it out.
  final List<String>? guessedVia;

  /// When the position was last heard (a contact) or read from the GPS
  /// (you).
  final DateTime? seenAt;
  final MyPosition? source;

  /// The ground under you, from the radio's GPS altitude.
  final double? groundM;

  const LosPlace.me(
    this.position, {
    required this.source,
    this.seenAt,
    this.groundM,
  }) : kind = LosPlaceKind.me,
       name = null,
       key = null,
       repeater = false,
       guessedVia = null;

  const LosPlace.contact(
    this.position, {
    required String this.name,
    required String this.key,
    this.repeater = false,
    this.seenAt,
    this.guessedVia,
  }) : kind = LosPlaceKind.contact,
       source = null,
       groundM = null;

  const LosPlace.point(this.position, {this.name})
    : kind = LosPlaceKind.point,
      key = null,
      repeater = false,
      seenAt = null,
      source = null,
      groundM = null,
      guessedVia = null;

  bool get isMe => kind == LosPlaceKind.me;
  bool get guessed => guessedVia != null;

  LinkEnd end(Antenna antenna) =>
      LinkEnd(geoOf(position), antennaM: antenna.metres, groundM: groundM);
}

enum LosMode { line, reach }

/// What the line of sight sheet shows and works out: a line from one place
/// to another, or the radio reach around one place.
///
/// Nothing runs until there is somewhere to look: a line waits for its To.
/// Every change works the answer out again; while it runs the last answer
/// stays.
class LineOfSightSession extends ChangeNotifier {
  final LosWorker _worker;
  final MapPacksService _maps;
  final AppSettingsService _settings;

  /// The connected radio's, or 915 MHz.
  final double frequencyMHz;

  /// The places with a position, for the reach list.
  final List<LosPlace> Function() _people;

  LineOfSightSession({
    required this._worker,
    required this._maps,
    required this._settings,
    required this._mode,
    required this.frequencyMHz,
    required this._people,
    LosPlace? from,
    LosPlace? to,
  }) : _from = from,
       _to = to {
    _fromAntenna = from == null || from.isMe || from.kind == LosPlaceKind.point
        ? myAntenna
        : _defaultAntenna(from);
    _toAntenna = to == null ? _handHeld : _defaultAntenna(to);
    _packsKey = _packs.key;
    _maps.addListener(_onMaps);
    _run();
  }

  LosMode _mode;
  LosPlace? _from, _to;
  late Antenna _fromAntenna, _toAntenna;
  var _closed = false;
  String _packsKey = '';

  LosMode get mode => _mode;

  /// Where the line starts, or the reach's middle; null until your
  /// position is known or a tap sets it.
  LosPlace? get from => _from;
  LosPlace? get to => _to;
  Antenna get fromAntenna => _fromAntenna;
  Antenna get toAntenna => _toAntenna;

  /// The line's answer, kept while the next one is worked out.
  LineOfSight? get line => _line;
  LineOfSight? _line;

  /// The answer for the ends as they are now.
  LineOfSight? get currentLine {
    final r = _line, from = _from, to = _to;
    if (r == null || from == null || to == null) return null;
    return r.from == geoOf(from.position) && r.to == geoOf(to.position)
        ? r
        : null;
  }

  Reach? get reach => _reach;
  Reach? _reach;

  /// The places [reach] answered for, in its order.
  List<LosPlace> get reachPeople => _reachPeople;
  List<LosPlace> _reachPeople = const [];

  /// The places in [listRadiusM] with only a guessed position: listed, with
  /// no answer.
  List<LosPlace> get reachGuessed => _reachGuessed;
  List<LosPlace> _reachGuessed = const [];

  /// How far out the reach lists people: 60 mi, or 100 km. Past the shaded
  /// circle each gets the answer for its own line.
  double get listRadiusM => _settings.settings.unitSystem == UnitSystem.imperial
      ? 60 * 1609.344
      : 100000;

  /// The sweep's radius: 20 km, then 30 km after [lookFurther].
  double get reachRadiusM => _radiusM;
  double _radiusM = nearRadiusM;
  static const nearRadiusM = 20000.0;
  static const farRadiusM = 30000.0;

  bool get busy => _lineBusy || _sweepBusy;
  bool _lineBusy = false;
  bool _sweepBusy = false;

  /// How much of the sweep is done, 0 to 1, while it runs.
  double? get progress => _progress;
  double? _progress;

  /// Set when the last question failed.
  bool get failed => _failed;
  bool _failed = false;

  /// A line opened from the reach list: [backToReach] goes back.
  bool get canGoBack => _savedReach != null;
  ({
    LosPlace from,
    Antenna antenna,
    Reach? reach,
    List<LosPlace> people,
    List<LosPlace> guessed,
  })?
  _savedReach;

  /// Bumps when the ends move, so the map can show them.
  int get endsVersion => _endsVersion;
  int _endsVersion = 0;

  Antenna get myAntenna {
    final s = _settings.settings;
    final kind =
        AntennaKind.values.asNameMap()[s.losAntenna] ?? AntennaKind.handHeld;
    return Antenna(
      kind,
      raisedM: s.losRaisedM ?? Antenna.defaultRaisedM(s.unitSystem),
    );
  }

  Antenna get _handHeld => Antenna(
    AntennaKind.handHeld,
    raisedM: Antenna.defaultRaisedM(_settings.settings.unitSystem),
  );

  /// Repeaters start raised, everyone else hand-held.
  Antenna _defaultAntenna(LosPlace p) =>
      p.repeater ? _handHeld.withKind(AntennaKind.raised) : _handHeld;

  LosPacks get _packs => losPacksFrom(_maps, _settings.settings.unitSystem);

  /// A tap on the map or a person. A line moves its To (or sets its From,
  /// while your position isn't known); a reach opens the line from its
  /// middle to there.
  void tap(LosPlace place) {
    if (_from == null) {
      _from = place;
      _fromAntenna = place.kind == LosPlaceKind.contact
          ? _defaultAntenna(place)
          : myAntenna;
      _endsVersion++;
      _run();
      return;
    }
    if (_mode == LosMode.reach) {
      openLine(place);
      return;
    }
    _to = place;
    _toAntenna = _defaultAntenna(place);
    _endsVersion++;
    _run();
  }

  /// The line from the reach's middle to [place].
  void openLine(LosPlace place) {
    final center = _from;
    if (center == null) return;
    _worker.stop();
    _savedReach = (
      from: center,
      antenna: _fromAntenna,
      reach: _reach,
      people: _reachPeople,
      guessed: _reachGuessed,
    );
    _mode = LosMode.line;
    _to = place;
    _toAntenna = _defaultAntenna(place);
    _line = null;
    _endsVersion++;
    _run();
  }

  void backToReach() {
    final saved = _savedReach;
    if (saved == null) return;
    _savedReach = null;
    _mode = LosMode.reach;
    _from = saved.from;
    _fromAntenna = saved.antenna;
    _to = null;
    _reach = saved.reach;
    _reachPeople = saved.people;
    _reachGuessed = saved.guessed;
    _endsVersion++;
    if (_reach == null) {
      _run();
    } else {
      notifyListeners();
    }
  }

  void setFromAntenna(Antenna antenna) {
    if (antenna == _fromAntenna) return;
    _fromAntenna = antenna;
    if (_from?.isMe ?? true) {
      final raised = antenna.kind == AntennaKind.raised
          ? antenna.raisedM
          : null;
      _settings.setLosAntenna(antenna.kind.name, raisedM: raised);
    }
    _run();
  }

  void setToAntenna(Antenna antenna) {
    if (antenna == _toAntenna) return;
    _toAntenna = antenna;
    _run();
  }

  /// Sweeps again out to 30 km.
  void lookFurther() {
    if (_radiusM >= farRadiusM) return;
    _radiusM = farRadiusM;
    _run();
  }

  void _onMaps() {
    final key = _packs.key;
    if (key == _packsKey) return;
    _packsKey = key;
    _run();
  }

  void _run() {
    _failed = false;
    switch (_mode) {
      case LosMode.line:
        _runLine();
      case LosMode.reach:
        _sweep();
    }
    notifyListeners();
  }

  /// Asked again while a line was being worked out: the answer that comes
  /// back is for ends or antennas that changed since.
  var _again = false;

  Future<void> _runLine() async {
    final from = _from, to = _to;
    if (from == null || to == null) return;
    if (_lineBusy) {
      _again = true;
      return;
    }
    _lineBusy = true;
    try {
      final r = await _worker.line(
        _packs,
        from.end(_fromAntenna),
        to.end(_toAntenna),
        frequencyMHz: frequencyMHz,
      );
      if (_closed) return;
      if (!_again) _line = r;
    } on Object catch (e) {
      if (_closed) return;
      appLogger.warn('Line of sight failed: $e', tag: 'LOS');
      if (!_again) _failed = true;
    }
    _lineBusy = false;
    if (_again) {
      _again = false;
      return _runLine();
    }
    notifyListeners();
  }

  int _sweeps = 0;

  Future<void> _sweep() async {
    final center = _from;
    if (center == null) return;
    _worker.stop();
    final sweep = ++_sweeps;
    final radius = _radiusM;
    final c = geoOf(center.position);
    final listRadius = listRadiusM;
    final near = [
      for (final p in _people())
        if (!(p.isMe && center.isMe) &&
            (p.key == null || p.key != center.key) &&
            distanceM(c, geoOf(p.position)) <= listRadius)
          p,
    ];
    final people = [
      for (final p in near)
        if (!p.guessed) p,
    ];
    final guessed = [
      for (final p in near)
        if (p.guessed) p,
    ];
    _sweepBusy = true;
    _progress = 0;
    // Swept again from the same place: the last shade stays meanwhile.
    if (_reach?.center != c) _reach = null;
    try {
      final r = await _worker.reach(
        _packs,
        center.end(_fromAntenna),
        radiusM: radius,
        rays: radius > nearRadiusM ? 720 : 360,
        targets: [for (final p in people) p.end(_defaultAntenna(p))],
        frequencyMHz: frequencyMHz,
        onProgress: (done) {
          if (_closed || sweep != _sweeps) return;
          _progress = done;
          notifyListeners();
        },
      );
      if (_closed || sweep != _sweeps) return;
      _reach = r;
      _reachPeople = people;
      _reachGuessed = guessed;
    } on Object catch (e) {
      if (_closed || sweep != _sweeps) return;
      appLogger.warn('Radio reach failed: $e', tag: 'LOS');
      _failed = true;
    }
    _sweepBusy = false;
    _progress = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _closed = true;
    _maps.removeListener(_onMaps);
    _worker.stop();
    super.dispose();
  }
}
