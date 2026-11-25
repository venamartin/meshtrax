import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:traxshare/traxshare.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../models/channel_message.dart';
import '../models/contact.dart';
import '../models/radio_settings.dart';
import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';
import 'radio_ask_service.dart';
import 'trax_service.dart';
import 'trip_positions.dart';

/// A trip member: a contact on this radio, or a name posted on the trip
/// channel that no single contact has ([contact] null).
typedef TripMember = ({String name, Contact? contact});

/// What Trip setup changed on one radio, so it can put it back: each
/// member's permissions from before, and the radio's own settings it
/// turned on.
class TripGrants {
  TripGrants({
    required this.modeBase,
    required this.modeLoc,
    this.modesSet = false,
    this.gpsSet = false,
    Map<String, ({bool base, bool loc})>? contacts,
  }) : contacts = contacts ?? {};

  final int modeBase;
  final int modeLoc;
  bool modesSet;
  bool gpsSet;
  final Map<String, ({bool base, bool loc})> contacts;

  Map<String, dynamic> toJson() => {
    'mode_base': modeBase,
    'mode_loc': modeLoc,
    'modes_set': modesSet,
    'gps_set': gpsSet,
    'contacts': {
      for (final MapEntry(:key, :value) in contacts.entries)
        key: [value.base, value.loc],
    },
  };

  static TripGrants? fromJson(Object? json) {
    if (json is! Map) return null;
    final base = json['mode_base'], loc = json['mode_loc'];
    if (base is! int || loc is! int) return null;
    final contacts = <String, ({bool base, bool loc})>{};
    if (json['contacts'] case final Map<String, dynamic> map) {
      for (final MapEntry(:key, :value) in map.entries) {
        if (value case [final bool b, final bool l]) {
          contacts[key] = (base: b, loc: l);
        }
      }
    }
    return TripGrants(
      modeBase: base,
      modeLoc: loc,
      modesSet: json['modes_set'] == true,
      gpsSet: json['gps_set'] == true,
      contacts: contacts,
    );
  }
}

/// Trip setup, with nothing to set up: everyone who posts on the trip
/// channel or sends a location there is a trip member, and may ask this
/// radio where it is as soon as the trip channel is picked. Each member
/// gets location by contact and a favourite's place, and the radio's GPS
/// goes on. Leaving TRAX mode after the trip's end puts it all back, except
/// the favourites.
///
/// In TRAX mode, two minutes after a group check, the radios of members
/// not heard on TRAX are asked, one at a time; so are those of members
/// whose locations stop coming.
class TripService extends ChangeNotifier {
  TripService(
    this._connector,
    this._trax,
    this._asks, {
    this._positions,
    DateTime Function()? clock,
    this.askAfter = const Duration(minutes: 2),
  }) : _clock = clock ?? DateTime.now {
    _connector.addListener(_onChange);
    _trax.addListener(_onChange);
    _positions?.addListener(_onChange);
    _messages = _connector.channelMessagesIn.listen(_onMessage);
    _left = _trax.left.listen(_onLeft);
    _onChange();
  }

  final MeshCoreConnector _connector;
  final TraxService _trax;
  final RadioAskService _asks;
  final TripPositions? _positions;
  final DateTime Function() _clock;

  /// How long after a group check a member counts as not heard.
  final Duration askAfter;

  /// Posts older than this don't make anyone a member.
  static const postsWindow = Duration(days: 30);

  /// A member whose location hasn't come for this many intervals gets
  /// their radio asked, again every [askSilentEvery] while it stays away.
  static const silentIntervals = 3;
  static const askSilentEvery = Duration(minutes: 10);

  static String grantsKeyFor(String radioKey) => 'trip_grants_$radioKey';

  /// The trip's end whose grants a Leave after it took back: they stay
  /// off until the trip's end changes.
  static const endedKey = 'trip_grants_ended';

  late final StreamSubscription<({ChannelMessage message, bool fromBacklog})>
  _messages;
  late final StreamSubscription<DateTime?> _left;

  /// Who posted on the trip channel, by lower-case name: the name as
  /// posted, and the latest post.
  final _posters = <String, ({String name, DateTime at})>{};
  Object? _postersFor;
  Object? _applied;
  Future<void> _applying = Future.value();
  DateTime? _askedFor;
  Timer? _askTimer;
  Timer? _silentTimer;
  final _silentAsked = <String, DateTime>{};
  bool _disposed = false;

  /// The trip members: the trip channel's posters, plus those added by
  /// hand, less those removed. Empty without a trip channel.
  List<TripMember> get members {
    if (_trax.tripChannel == null) return const [];
    final setup = _trax.setup;
    final saved = [
      for (final c in _connector.contacts)
        if (c.type == advTypeChat) c,
    ];
    // A post carries only a name: the contact of that name when exactly one
    // has it, as the @ list does.
    final byName = <String, Contact?>{};
    for (final c in saved) {
      final key = c.name.toLowerCase();
      byName[key] = byName.containsKey(key) ? null : c;
    }
    final out = <String, TripMember>{};
    for (final MapEntry(:key, value: (:name, at: _)) in _posters.entries) {
      final contact = byName[key];
      if (contact == null) {
        out['name:$key'] = (name: name, contact: null);
      } else if (!setup.removed.contains(contact.publicKeyHex)) {
        out[contact.publicKeyHex] = (name: contact.name, contact: contact);
      }
    }
    for (final p in _positions?.all ?? const <TripPosition>[]) {
      final found = _connector.contactByKeyPrefix4(p.prefixBytes);
      final contact = saved.where((c) => c == found).firstOrNull;
      if (contact == null) {
        final name = p.name ?? found?.name ?? p.prefix.toUpperCase();
        out.putIfAbsent(
          'name:${name.toLowerCase()}',
          () => (name: name, contact: null),
        );
      } else if (!setup.removed.contains(contact.publicKeyHex)) {
        out[contact.publicKeyHex] = (name: contact.name, contact: contact);
      }
    }
    for (final key in setup.added) {
      final contact = saved.where((c) => c.publicKeyHex == key).firstOrNull;
      if (contact != null) out[key] = (name: contact.name, contact: contact);
    }
    return out.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  /// The members who are contacts on this radio.
  List<Contact> get memberContacts => [for (final m in members) ?m.contact];

  /// Members may ask this radio now, as far as Trip setup goes.
  bool get active =>
      _connector.isConnected &&
      PrefsManager.instance.getString(
            grantsKeyFor(_connector.selfPublicKeyHex),
          ) !=
          null;

  /// The radio's privacy settings stop every location answer: Share my
  /// location is off.
  bool get blockedBySharing =>
      _connector.telemetryModeBase == teleModeDeny ||
      _connector.telemetryModeLoc == teleModeDeny;

  /// [contact] has been heard on TRAX since it began: an advert, a post or
  /// a location on the trip channel, or an answer from its radio.
  bool onTrax(Contact contact) {
    final since = _trax.heardSince;
    final last = _lastHeard(contact);
    return since != null && last != null && !last.isBefore(since);
  }

  DateTime? _lastHeard(Contact contact) {
    DateTime? last;
    for (final t in [
      _connector.getLocalDiscoveredTime(contact.publicKeyHex),
      _posters[contact.name.toLowerCase()]?.at,
      _asks.askFor(contact)?.latest?.receivedAt,
      _positions?.of(contact)?.heardAt,
    ]) {
      if (t != null && (last == null || t.isAfter(last))) last = t;
    }
    return last;
  }

  /// How often each member's MeshTrax sends its location in TRAX mode: by
  /// the trip's size, and the air a report takes on the radio's settings.
  Duration get locationInterval => beaconInterval(
    members: members.length + 1,
    reportAirtimeMs: switch (_trax.current) {
      final p? => reportAirtimeMs(p),
      null => referenceReportAirtimeMs,
    },
  );

  /// A report's time on air: 37 bytes, with the firmware's preamble
  /// (RadioLibWrappers.h preambleLengthForSF) and RadioLib's automatic low
  /// data rate optimisation.
  static int reportAirtimeMs(LoRaParams p) => calculateLoRaAirtime(
    payloadBytes: 37,
    spreadingFactor: p.sf,
    bandwidthHz: p.bwHz,
    codingRate: p.cr - 4,
    preambleSymbols: p.sf <= 8 ? 32 : 16,
    lowDataRateOptimize: (1 << p.sf) / (p.bwHz / 1000) > 16,
  );

  void addMember(Contact contact) {
    final setup = _trax.setup;
    final key = contact.publicKeyHex;
    unawaited(
      _trax.updateSetup(
        setup.copyWith(
          added: {...setup.added, key},
          removed: {...setup.removed}..remove(key),
        ),
      ),
    );
  }

  void removeMember(Contact contact) {
    final setup = _trax.setup;
    final key = contact.publicKeyHex;
    unawaited(
      _trax.updateSetup(
        setup.copyWith(
          added: {...setup.added}..remove(key),
          removed: {...setup.removed, key},
        ),
      ),
    );
  }

  /// Grants are wanted: asking is on, there is a trip channel, and no Leave
  /// after this trip's end has taken them back.
  bool get _wanted {
    final setup = _trax.setup;
    final until = setup.until;
    final ended = PrefsManager.instance.getInt(endedKey);
    return setup.askMyRadio &&
        _trax.tripChannel != null &&
        (until == null || ended != until.millisecondsSinceEpoch);
  }

  void _onChange() {
    if (_disposed) return;
    final c = _connector;
    final ready = c.isConnected && c.isSynced && c.channelsVerified;
    final channel = _trax.tripChannel;
    final key = c.selfPublicKeyHex;

    // Not on [ready]: it flickers with every queue sync.
    final postersFor = c.isConnected && channel != null && key.isNotEmpty
        ? (key, channel.idKey)
        : null;
    if (postersFor != _postersFor) {
      _postersFor = postersFor;
      _posters.clear();
      if (postersFor != null) unawaited(_loadPosters(postersFor));
    }

    if (ready && key.isNotEmpty) {
      final setup = _trax.setup;
      final state = (
        key,
        _wanted,
        {for (final m in memberContacts) m.publicKeyHex},
        setup.added,
        setup.removed,
      );
      if (!_sameState(state, _applied)) {
        _applied = state;
        _applying = _applying.then((_) => _apply()).catchError((Object e) {
          appLogger.warn('Trip setup: $e', tag: 'Trip');
        });
      }
    } else if (!c.isConnected) {
      _applied = null;
    }

    _syncAskTimer();
    _syncSilentTimer();
  }

  static bool _sameState(Object? a, Object? b) {
    if (a is! (String, bool, Set<String>, Set<String>, Set<String>) ||
        b is! (String, bool, Set<String>, Set<String>, Set<String>)) {
      return false;
    }
    return a.$1 == b.$1 &&
        a.$2 == b.$2 &&
        setEquals(a.$3, b.$3) &&
        setEquals(a.$4, b.$4) &&
        setEquals(a.$5, b.$5);
  }

  Future<void> _loadPosters(Object loadingFor) async {
    final channel = _trax.tripChannel;
    if (channel == null) return;
    final since = _clock().subtract(postsWindow);
    final messages = await _connector.loadChannelMessagesFor(channel);
    if (_disposed || _postersFor != loadingFor) return;
    for (final m in messages) {
      if (!m.timestamp.isBefore(since)) _notePoster(m);
    }
    notifyListeners();
    _onChange();
  }

  void _onMessage(({ChannelMessage message, bool fromBacklog}) e) {
    final channel = _trax.tripChannel;
    if (channel == null || e.message.channelIndex != channel.index) return;
    if (_notePoster(e.message)) {
      notifyListeners();
      _onChange();
    }
  }

  /// True when [m] adds a poster, or a later post by one.
  bool _notePoster(ChannelMessage m) {
    if (m.isOutgoing) return false;
    final name = m.senderName.trim();
    if (name.isEmpty || name == _connector.selfName) return false;
    final key = name.toLowerCase();
    final seen = _posters[key];
    if (seen != null && !m.timestamp.isAfter(seen.at)) return false;
    _posters[key] = (name: name, at: m.timestamp);
    return true;
  }

  /// Leaving TRAX mode after the trip's end takes the grants back.
  void _onLeft(DateTime? until) {
    if (until == null || until.isAfter(_clock())) return;
    unawaited(
      PrefsManager.instance
          .setInt(endedKey, until.millisecondsSinceEpoch)
          .then((_) => _onChange()),
    );
    _applied = null;
  }

  Future<void> _apply() async {
    final c = _connector;
    if (_disposed || !c.isConnected || !c.isSynced) return;
    final key = c.selfPublicKeyHex;
    if (key.isEmpty) return;
    var grants = _load(key);
    if (!_wanted) {
      if (grants != null) await _revoke(key, grants);
      return;
    }
    if (grants == null) {
      grants = TripGrants(
        modeBase: c.telemetryModeBase,
        modeLoc: c.telemetryModeLoc,
      );
      // Saved first: whatever happens next, it can be put back.
      await _save(key, grants);
      final base = c.telemetryModeBase == teleModeDeny
          ? teleModeAllowFlags
          : c.telemetryModeBase;
      final loc = c.telemetryModeLoc == teleModeDeny
          ? teleModeAllowFlags
          : c.telemetryModeLoc;
      if (base != c.telemetryModeBase || loc != c.telemetryModeLoc) {
        await c.setTelemetryModeBase(
          base,
          loc,
          c.telemetryModeEnv,
          c.advertLocationPolicy,
        );
        grants.modesSet = true;
      }
      if (!c.gpsOn) {
        await c.setGps(true);
        grants.gpsSet = true;
      } else {
        // Older app versions left 900 s, which makes a live fix look frozen
        // for 15 minutes. Tracker boards refuse it and refresh anyway.
        await c.setCustomVar('gps_interval:0');
      }
      appLogger.info('Trip setup: members may ask this radio', tag: 'Trip');
    }
    final members = {for (final m in memberContacts) m.publicKeyHex: m};
    for (final m in members.values) {
      grants.contacts[m.publicKeyHex] ??= (
        base: m.teleBaseEnabled,
        loc: m.teleLocEnabled,
      );
      if (m.teleBaseEnabled && m.teleLocEnabled && m.isFavorite) continue;
      await c.setContactFlags(
        m,
        isFavorite: true,
        teleBase: true,
        teleLoc: true,
      );
    }
    for (final hex in [...grants.contacts.keys]) {
      if (members.containsKey(hex)) continue;
      final before = grants.contacts.remove(hex)!;
      final contact = _saved(hex);
      if (contact != null) {
        await c.setContactFlags(
          contact,
          teleBase: before.base,
          teleLoc: before.loc,
        );
      }
    }
    await _save(key, grants);
    notifyListeners();
  }

  /// Puts back what [_apply] changed, except the favourites.
  Future<void> _revoke(String key, TripGrants grants) async {
    final c = _connector;
    for (final MapEntry(key: hex, value: before) in grants.contacts.entries) {
      final contact = _saved(hex);
      if (contact == null) continue;
      await c.setContactFlags(
        contact,
        teleBase: before.base,
        teleLoc: before.loc,
      );
    }
    if (grants.modesSet) {
      // Only what is still as Trip setup left it.
      int back(int now, int before) => now == teleModeAllowFlags ? before : now;
      await c.setTelemetryModeBase(
        back(c.telemetryModeBase, grants.modeBase),
        back(c.telemetryModeLoc, grants.modeLoc),
        c.telemetryModeEnv,
        c.advertLocationPolicy,
      );
    }
    if (grants.gpsSet && c.gpsOn) await c.setGps(false);
    await PrefsManager.instance.remove(grantsKeyFor(key));
    appLogger.info('Trip setup: members may no longer ask', tag: 'Trip');
    notifyListeners();
  }

  Contact? _saved(String hex) =>
      _connector.contacts.where((c) => c.publicKeyHex == hex).firstOrNull;

  TripGrants? _load(String radioKey) {
    final raw = PrefsManager.instance.getString(grantsKeyFor(radioKey));
    if (raw == null) return null;
    try {
      return TripGrants.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  Future<void> _save(String radioKey, TripGrants grants) => PrefsManager
      .instance
      .setString(grantsKeyFor(radioKey), jsonEncode(grants.toJson()));

  /// Two minutes after each group check, the radios of members not heard
  /// on TRAX are asked, one at a time.
  void _syncAskTimer() {
    final checked = _trax.checkedAt;
    if (checked == _askedFor) return;
    _askedFor = checked;
    _askTimer?.cancel();
    _askTimer = null;
    if (checked == null) return;
    final wait = askAfter - _clock().difference(checked);
    _askTimer = Timer(wait.isNegative ? Duration.zero : wait, _askNotHeard);
  }

  void _askNotHeard() {
    if (_disposed || !_trax.isOn) return;
    for (final m in memberContacts) {
      if (!onTrax(m)) _asks.ask(m);
    }
  }

  void _syncSilentTimer() {
    final on = _positions != null && _trax.isOn;
    if (on == (_silentTimer != null)) return;
    _silentTimer?.cancel();
    _silentTimer = on
        ? Timer.periodic(const Duration(seconds: 30), (_) => _askSilent())
        : null;
    if (!on) _silentAsked.clear();
  }

  /// Asks the radios of members not heard for [silentIntervals] location
  /// intervals, counted from when TRAX mode began at the earliest.
  void _askSilent() {
    final since = _trax.heardSince;
    if (_disposed || !_trax.isOn || since == null) return;
    final now = _clock();
    final silentAfter = locationInterval * silentIntervals;
    if (now.difference(since) < silentAfter) return;
    for (final m in memberContacts) {
      final last = _lastHeard(m);
      if (last != null && now.difference(last) < silentAfter) continue;
      final asked = _silentAsked[m.publicKeyHex];
      if (asked != null && now.difference(asked) < askSilentEvery) continue;
      _silentAsked[m.publicKeyHex] = now;
      _asks.ask(m);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _askTimer?.cancel();
    _silentTimer?.cancel();
    _connector.removeListener(_onChange);
    _trax.removeListener(_onChange);
    _positions?.removeListener(_onChange);
    unawaited(_messages.cancel());
    unawaited(_left.cancel());
    super.dispose();
  }
}
