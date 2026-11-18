import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/structured_message.dart';
import '../models/channel.dart';
import '../models/channel_message.dart';
import '../models/contact.dart';
import '../models/radio_settings.dart';
import '../models/trax.dart';
import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';
import 'background_service.dart';
import 'notification_service.dart';

/// What a switch or a leave is doing, for the sheet.
enum TraxStep { telling, switching, checking, leaving }

enum TraxOutcome {
  ok,

  /// Switched or left, but the radio didn't confirm in time that it sent
  /// the TRAX message.
  sentUnconfirmed,
  notConnected,

  /// The firmware can't repeat (ver code under 9).
  unsupported,

  /// The radio is still syncing, or another switch is running.
  busy,

  /// No trip end in the future.
  noEnd,

  /// Tell the group with no trip channel on this radio.
  noChannel,

  /// The radio can't repeat on that frequency.
  notAllowed,

  /// The radio didn't take the settings; nothing changed.
  refused,

  /// Leave: this phone saved nothing for this radio.
  needPreset,
}

/// Something TRAX mode asks the user, once, when it happens.
sealed class TraxPrompt {
  const TraxPrompt();
}

/// A member's TRAX message on a private channel: switch too?
class TraxFollowPrompt extends TraxPrompt {
  final String sender;
  final TraxMessage message;
  final Channel channel;

  const TraxFollowPrompt(this.sender, this.message, this.channel);

  @override
  bool operator ==(Object other) =>
      other is TraxFollowPrompt &&
      other.sender == sender &&
      other.channel.idKey == channel.idKey &&
      other.message.toWire() == message.toWire();

  @override
  int get hashCode => Object.hash(sender, channel.idKey, message.toWire());
}

/// A member is leaving TRAX mode: leave too?
class TraxLeavePrompt extends TraxPrompt {
  final String sender;

  const TraxLeavePrompt(this.sender);

  @override
  bool operator ==(Object other) =>
      other is TraxLeavePrompt && other.sender == sender;

  @override
  int get hashCode => sender.hashCode;
}

/// The trip has ended with the radio still in TRAX mode: at the end itself
/// while connected, or at a connect after it.
class TraxStillOnPrompt extends TraxPrompt {
  const TraxStillOnPrompt();
}

/// TRAX mode: one tap moves the radio to the group's off-grid frequency
/// with Off-Grid Repeat on, so every radio relays for the others, and one
/// tap puts it back. The radio's settings from before are saved on this
/// phone per radio key, so Leave restores them after a restart or another
/// radio in between. A member's TRAX message only ever asks: nothing
/// retunes a radio without a tap.
class TraxService extends ChangeNotifier {
  TraxService(
    this._connector, {
    this.background,
    DateTime Function()? clock,
    this.sendPoll = const Duration(milliseconds: 500),
    this.sendTimeout = const Duration(seconds: 20),
    this.sendMargin = const Duration(milliseconds: 300),
    this.syncTimeout = const Duration(seconds: 30),
  }) : _clock = clock ?? DateTime.now {
    _setup = _loadSetup();
    _connector.addListener(_onConnector);
    _messages = _connector.channelMessagesIn.listen(_onChannelMessage);
    _onConnector();
  }

  final MeshCoreConnector _connector;

  /// Android's foreground service, whose notification says when TRAX mode
  /// is on.
  final BackgroundService? background;
  final DateTime Function() _clock;

  /// How often, and how long, a TRAX message is watched until the radio
  /// has sent it; then a little longer for the last bytes on air.
  final Duration sendPoll;
  final Duration sendTimeout;
  final Duration sendMargin;
  final Duration syncTimeout;

  static const _setupKey = 'trax_setup';
  static String sessionKeyFor(String radioKey) => 'trax_radio_$radioKey';

  late TraxSetup _setup;
  late final StreamSubscription<({ChannelMessage message, bool fromBacklog})>
  _messages;
  final _prompts = StreamController<TraxPrompt>.broadcast();

  String? _radioKey;
  RepeatRanges? _allowed;
  DateTime? _heardSince;
  TraxStep? _step;
  Object? _shown;

  /// The trip's end while TRAX mode is on, and the reminder's timer for it.
  DateTime? _timedEnd;
  Timer? _endTimer;

  /// Notification texts, in the app's language (set by the app).
  String notificationTitle = 'TRAX mode is on';
  String notificationText = "The regular mesh can't hear you.";

  TraxSetup get setup => _setup;
  Stream<TraxPrompt> get prompts => _prompts.stream;
  TraxStep? get step => _step;
  bool get busy => _step != null;

  /// The radio can repeat (firmware ver code 9+).
  bool get supported => supportedBy(_connector);

  /// [supported], for a check that has only the connector.
  static bool supportedBy(MeshCoreConnector connector) =>
      connector.clientRepeat != null;

  /// The connected radio is on a TRAX preset, whichever phone switched it.
  bool get isOn =>
      _connector.isConnected &&
      Trax.isOn(
        clientRepeat: _connector.clientRepeat,
        freqKhz: _connector.currentFreqHz,
        allowed: _allowed,
      );

  /// What the connected radio is on now; null until it has said.
  LoRaParams? get current {
    final c = _connector;
    final f = c.currentFreqHz, b = c.currentBwHz, s = c.currentSf;
    final r = c.currentCr;
    if (f == null || b == null || s == null || r == null) return null;
    return LoRaParams(freqKhz: f, bwHz: b, sf: s, cr: r <= 4 ? r + 4 : r);
  }

  /// Where TRAX mode would move the radio, by TRAX settings.
  LoRaParams? get plannedPreset {
    final now = current;
    if (now == null) return null;
    return Trax.presetFor(
      now,
      _setup.preset,
      allowed: _allowed,
      firmwareVerCode: _connector.firmwareVerCode,
    );
  }

  /// This radio's TRAX mode as this phone switched it.
  TraxSession? get session {
    final key = _connector.selfPublicKeyHex;
    return key.isEmpty ? null : sessionFor(key);
  }

  static TraxSession? sessionFor(String radioKey) {
    final raw = PrefsManager.instance.getString(sessionKeyFor(radioKey));
    if (raw == null) return null;
    try {
      return TraxSession.fromJson(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  /// The trip's end: the one this phone switched with, else TRAX settings'.
  DateTime? get until => session?.until ?? _setup.until;

  /// Channels a TRAX message may go to and come from.
  List<Channel> get privateChannels => [
    for (final c in _connector.channels)
      if (!c.isEmpty && c.isPrivate) c,
  ];

  Channel? get tripChannel {
    final key = _setup.channelKey;
    if (key == null) return null;
    for (final c in privateChannels) {
      if (c.idKey == key) return c;
    }
    return null;
  }

  /// Everyone this radio has heard since TRAX mode began, by name.
  List<Contact> get heard {
    final since = _heardSince;
    if (since == null || !isOn) return const [];
    final out = <Contact>[
      for (final c in _connector.allContacts)
        if (_connector.getLocalDiscoveredTime(c.publicKeyHex) case final t?
            when !t.isBefore(since))
          c,
    ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return out;
  }

  /// Asks the radio which frequencies it repeats on, once per connection.
  Future<void> loadAllowed() async {
    if (_allowed != null || !_connector.isConnected || !supported) return;
    final allowed = await _connector.getAllowedRepeatFrequencies();
    if (allowed == null || !_connector.isConnected) return;
    _allowed = allowed;
    notifyListeners();
  }

  Future<void> updateSetup(TraxSetup setup) async {
    final moved = setup.until != _setup.until;
    _setup = setup;
    await PrefsManager.instance.setString(
      _setupKey,
      jsonEncode(setup.toJson()),
    );
    // A new end in TRAX settings is this radio's too, while it is on.
    final session = this.session;
    if (moved && isOn && session != null) {
      await _saveSession(
        _connector.selfPublicKeyHex,
        TraxSession(
          saved: session.saved,
          switchedAt: session.switchedAt,
          until: setup.until,
        ),
      );
    }
    _syncEndTimer();
    notifyListeners();
  }

  static TraxSetup _loadSetup() {
    final raw = PrefsManager.instance.getString(_setupKey);
    if (raw == null) return const TraxSetup();
    try {
      return TraxSetup.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const TraxSetup();
    }
  }

  void setNotificationTexts({required String title, required String text}) {
    if (title == notificationTitle && text == notificationText) return;
    notificationTitle = title;
    notificationText = text;
    _syncNotification(force: true);
  }

  /// One tap: save the radio's settings on this phone, tell the group and
  /// wait until the radio has sent it, move the radio in one settings
  /// write with repeat on, then send one flood advert for the group check.
  /// [preset] and [until] come from a member's TRAX message when following.
  Future<TraxOutcome> start({
    LoRaParams? preset,
    DateTime? until,
    bool? tellGroup,
  }) async {
    final c = _connector;
    if (busy) return TraxOutcome.busy;
    if (!c.isConnected) return TraxOutcome.notConnected;
    if (!supported) return TraxOutcome.unsupported;
    if (isOn) return TraxOutcome.ok;
    final end = until ?? _setup.until;
    if (end == null || !end.isAfter(_clock())) return TraxOutcome.noEnd;
    final tell = tellGroup ?? _setup.tellGroup;
    final trip = tell ? tripChannel : null;
    if (tell && trip == null) return TraxOutcome.noChannel;
    _setStep(TraxStep.switching);
    try {
      if (!await c.waitUntilSynced(timeout: syncTimeout)) {
        return TraxOutcome.busy;
      }
      if (trip != null && !c.channelsVerified) return TraxOutcome.busy;
      final key = c.selfPublicKeyHex;
      final f = c.currentFreqHz, b = c.currentBwHz, s = c.currentSf;
      final r = c.currentCr;
      if (key.isEmpty || f == null || b == null || s == null || r == null) {
        return TraxOutcome.busy;
      }
      final saved = TraxSavedRadio(
        freqKhz: f,
        bwHz: b,
        sf: s,
        cr: r,
        txPowerDbm: c.currentTxPower ?? 20,
        repeat: c.clientRepeat ?? false,
      );
      await loadAllowed();
      final target =
          preset ??
          Trax.presetFor(
            saved.params,
            _setup.preset,
            allowed: _allowed,
            firmwareVerCode: c.firmwareVerCode,
          );
      if (!target.isValid ||
          !Trax.isRepeatFrequency(target.freqKhz, _allowed)) {
        return TraxOutcome.notAllowed;
      }
      final switchedAt = _clock();
      // Saved before anything moves: whatever happens next, Leave knows
      // where the radio came from.
      await _saveSession(
        key,
        TraxSession(saved: saved, switchedAt: switchedAt, until: end),
      );
      var confirmed = true;
      if (trip != null) {
        _setStep(TraxStep.telling);
        confirmed = await _postAndWaitUntilSent(
          trip,
          TraxMessage.switching(until: end, preset: target).toWire(),
        );
      }
      _setStep(TraxStep.switching);
      final cr = r <= 4 ? target.cr - 4 : target.cr;
      if (!await c.setRadioParams(
        target.freqKhz,
        target.bwHz,
        target.sf,
        cr,
        clientRepeat: true,
      )) {
        appLogger.warn('Radio did not take the TRAX settings', tag: 'Trax');
        unawaited(c.refreshRadioSettings());
        return TraxOutcome.refused;
      }
      c.noteRadioSettingsSaved(
        freqKhz: target.freqKhz,
        bwHz: target.bwHz,
        sf: target.sf,
        cr: cr,
        txPower: saved.txPowerDbm,
        clientRepeat: true,
      );
      c.rememberNonRepeatRadioState(_snapshot(saved));
      _radioKey = key;
      _heardSince = switchedAt;
      appLogger.info(
        'TRAX mode on: ${saved.params} -> $target, repeat on',
        tag: 'Trax',
      );
      _setStep(TraxStep.checking);
      await c.waitForRadio();
      await c.sendSelfAdvert(flood: true);
      unawaited(c.refreshRadioSettings());
      return confirmed ? TraxOutcome.ok : TraxOutcome.sentUnconfirmed;
    } finally {
      _setStep(null);
    }
  }

  /// "Switch too": a member's TRAX message, followed with one tap. The
  /// group has been told, so nothing is posted; the trip channel and end
  /// become this phone's too.
  Future<TraxOutcome> follow(TraxMessage message, Channel channel) async {
    if (!message.on || message.preset == null || message.until == null) {
      return TraxOutcome.notAllowed;
    }
    final outcome = await start(
      preset: message.preset,
      until: message.until!.toLocal(),
      tellGroup: false,
    );
    if (outcome == TraxOutcome.ok) {
      await updateSetup(
        _setup.copyWith(
          channelKey: () => channel.idKey,
          until: () => message.until!.toLocal(),
        ),
      );
    }
    return outcome;
  }

  /// One flood advert on the TRAX frequency. Every member's radio relays
  /// it, and theirs show in [heard] as they advert.
  Future<void> groupCheck() async {
    if (!isOn || busy) return;
    _setStep(TraxStep.checking);
    try {
      await _connector.sendSelfAdvert(flood: true);
    } finally {
      _setStep(null);
    }
  }

  /// The settings Leave writes for a regular [preset], in the radio's own
  /// coding-rate count.
  TraxSavedRadio savedFromPreset(RadioSettings preset) {
    final deviceCr = _connector.currentCr ?? 5;
    return TraxSavedRadio(
      freqKhz: preset.frequencyHz,
      bwHz: preset.bandwidthHz,
      sf: preset.sf,
      cr: deviceCr <= 4 ? preset.cr - 4 : preset.cr,
      txPowerDbm: preset.txPowerDbm,
      repeat: false,
    );
  }

  /// Tells the group first, if set up, then puts back the saved settings
  /// with repeat off. With nothing saved on this phone, [returnTo] says
  /// where to go ([TraxOutcome.needPreset] until it does).
  Future<TraxOutcome> leave({TraxSavedRadio? returnTo, bool? tellGroup}) async {
    final c = _connector;
    if (busy) return TraxOutcome.busy;
    if (!c.isConnected) return TraxOutcome.notConnected;
    if (!isOn) return TraxOutcome.ok;
    final key = c.selfPublicKeyHex;
    final target = returnTo ?? session?.saved;
    if (target == null) return TraxOutcome.needPreset;
    final trip = (tellGroup ?? _setup.tellGroup) ? tripChannel : null;
    _setStep(TraxStep.leaving);
    try {
      var confirmed = true;
      // Leaving never waits on the group: without a trip channel, or with
      // the channels still loading, the radio leaves untold.
      if (trip != null && c.channelsVerified) {
        _setStep(TraxStep.telling);
        confirmed = await _postAndWaitUntilSent(
          trip,
          const TraxMessage.leaving().toWire(),
        );
        _setStep(TraxStep.leaving);
      }
      if (!await c.setRadioParams(
        target.freqKhz,
        target.bwHz,
        target.sf,
        target.cr,
        clientRepeat: false,
      )) {
        appLogger.warn('Radio did not take its saved settings', tag: 'Trax');
        unawaited(c.refreshRadioSettings());
        return TraxOutcome.refused;
      }
      var tx = c.currentTxPower ?? target.txPowerDbm;
      if (tx != target.txPowerDbm) {
        await c.waitForRadio();
        await c.sendFrame(buildSetRadioTxPowerFrame(target.txPowerDbm));
        tx = target.txPowerDbm;
      }
      c.noteRadioSettingsSaved(
        freqKhz: target.freqKhz,
        bwHz: target.bwHz,
        sf: target.sf,
        cr: target.cr,
        txPower: tx,
        clientRepeat: false,
      );
      await PrefsManager.instance.remove(sessionKeyFor(key));
      _heardSince = null;
      appLogger.info('TRAX mode off: back on ${target.params}', tag: 'Trax');
      unawaited(c.refreshRadioSettings());
      return confirmed ? TraxOutcome.ok : TraxOutcome.sentUnconfirmed;
    } finally {
      _setStep(null);
    }
  }

  /// Posts [text] on [channel] and waits until the radio has sent it: its
  /// send queue empty and one more flood sent than before. A retune with
  /// the message still queued would send it on the new frequency.
  Future<bool> _postAndWaitUntilSent(Channel channel, String text) async {
    final before = await _connector.readSendCounters();
    await _connector.sendChannelMessage(channel, text);
    if (before == null) {
      // No counters from this radio: give it the time a send takes.
      await Future<void>.delayed(sendTimeout ~/ 4);
      return false;
    }
    final polls = sendTimeout.inMilliseconds ~/ sendPoll.inMilliseconds;
    for (var i = 0; i < polls && _connector.isConnected; i++) {
      await Future<void>.delayed(sendPoll);
      final now = await _connector.readSendCounters();
      if (now != null &&
          now.queued == 0 &&
          now.floodsSent > before.floodsSent) {
        await Future<void>.delayed(sendMargin);
        return true;
      }
    }
    appLogger.warn(
      'The radio did not confirm sending the TRAX message',
      tag: 'Trax',
    );
    return false;
  }

  Future<void> _saveSession(String radioKey, TraxSession session) =>
      PrefsManager.instance.setString(
        sessionKeyFor(radioKey),
        jsonEncode(session.toJson()),
      );

  static MeshCoreRadioStateSnapshot _snapshot(TraxSavedRadio s) =>
      MeshCoreRadioStateSnapshot(
        freqHz: s.freqKhz,
        bwHz: s.bwHz,
        sf: s.sf,
        cr: s.cr,
        txPowerDbm: s.txPowerDbm,
      );

  /// What TRAX mode asks about a member's [message], if anything: a TRAX
  /// message heard live on a private channel, and only what fits this
  /// radio now.
  TraxPrompt? _promptFor(ChannelMessage message, {bool fromBacklog = false}) {
    if (fromBacklog || busy) return null;
    final parsed = StructuredMessage.parse(message.text);
    if (parsed is! TraxMessage) return null;
    final index = message.channelIndex;
    final channel = _connector.channels
        .where((c) => c.index == index)
        .firstOrNull;
    // Public, hashtag and other channels anyone can read never ask.
    if (channel == null || !channel.isPrivate) return null;
    if (parsed.on) {
      final end = parsed.until;
      if (isOn || end == null || !end.isAfter(_clock())) return null;
      return TraxFollowPrompt(message.senderName, parsed, channel);
    }
    return isOn ? TraxLeavePrompt(message.senderName) : null;
  }

  /// Switch too or Leave too on [message]'s notification, where TRAX mode
  /// asks about it ([MeshCoreConnector.traxActionFor]).
  String? notificationAction(
    ChannelMessage message, {
    required bool fromBacklog,
  }) => switch (_promptFor(message, fromBacklog: fromBacklog)) {
    TraxFollowPrompt() => NotificationService.traxFollowAction,
    TraxLeavePrompt() => NotificationService.traxLeaveAction,
    _ => null,
  };

  /// The latest TRAX message heard live on each channel.
  final _latest = <int, ChannelMessage>{};

  /// What the latest TRAX message on channel [index] asks now, for its
  /// notification's button: null once it no longer fits.
  TraxPrompt? askedOn(int index) {
    final message = _latest[index];
    return message == null ? null : _promptFor(message);
  }

  void _onChannelMessage(({ChannelMessage message, bool fromBacklog}) e) {
    final m = e.message;
    if (e.fromBacklog || StructuredMessage.parse(m.text) is! TraxMessage) {
      return;
    }
    if (m.channelIndex case final index?) _latest[index] = m;
    final prompt = _promptFor(m);
    if (prompt is TraxFollowPrompt) {
      _ask(prompt, 'on ${prompt.sender} ${prompt.message.toWire()}');
    } else if (prompt is TraxLeavePrompt) {
      _ask(prompt, 'off ${prompt.sender}');
    }
  }

  final _asked = <String, DateTime>{};

  /// Each question once in ten minutes: a resent message, or a radio that
  /// drops and reconnects, doesn't stack the same question.
  void _ask(TraxPrompt prompt, String key) {
    final now = _clock();
    _asked.removeWhere((_, at) => now.difference(at) > _askAgainAfter);
    if (_asked.containsKey(key)) return;
    _asked[key] = now;
    _prompts.add(prompt);
  }

  static const _askAgainAfter = Duration(minutes: 10);

  void _onConnector() {
    final c = _connector;
    if (!c.isConnected) {
      _radioKey = null;
      _allowed = null;
      _heardSince = null;
      _latest.clear();
    } else {
      final key = c.selfPublicKeyHex;
      if (key.isNotEmpty &&
          key != _radioKey &&
          c.firmwareVerCode != null &&
          c.currentFreqHz != null &&
          !busy) {
        _radioKey = key;
        _allowed = null;
        _onConnected(key);
      }
    }
    _syncNotification();
    _syncEndTimer();
    final shown = (isOn, _radioKey, isOn ? heard.length : 0);
    if (shown != _shown) {
      _shown = shown;
      notifyListeners();
    }
  }

  /// Once per connection, when the radio has said what it is on.
  void _onConnected(String key) {
    final saved = sessionFor(key);
    if (!isOn) {
      if (saved != null && supported) {
        // Left TRAX mode elsewhere: another phone, or the radio settings.
        appLogger.info(
          'Radio is off TRAX mode; forgetting its saved settings',
          tag: 'Trax',
        );
        unawaited(PrefsManager.instance.remove(sessionKeyFor(key)));
      }
      return;
    }
    _heardSince = saved?.switchedAt ?? _clock();
    if (saved != null) {
      _connector.rememberNonRepeatRadioState(_snapshot(saved.saved));
    }
    final end = saved?.until ?? _setup.until;
    if (end != null && !end.isAfter(_clock())) {
      _ask(const TraxStillOnPrompt(), 'still $key');
    }
  }

  /// The reminder's question while it still fits: the trip has ended and
  /// the radio is still in TRAX mode.
  TraxPrompt? get tripEndedPrompt {
    final end = until;
    return isOn && end != null && !end.isAfter(_clock())
        ? const TraxStillOnPrompt()
        : null;
  }

  /// While TRAX mode is on and the phone stays connected, the trip's end
  /// brings a notification and the question a connect after it asks. An
  /// end already past when set brings none: that connect asked.
  void _syncEndTimer() {
    final end = isOn ? until : null;
    if (end == _timedEnd) return;
    _timedEnd = end;
    _endTimer?.cancel();
    _endTimer = null;
    if (end != null && end.isAfter(_clock())) {
      _endTimer = Timer(end.difference(_clock()), _onTripEnd);
    }
  }

  void _onTripEnd() {
    final end = _timedEnd;
    if (end == null || !isOn) return;
    final left = end.difference(_clock());
    if (left > Duration.zero) {
      // The phone's clock was set back meanwhile.
      _endTimer = Timer(left, _onTripEnd);
      return;
    }
    _endTimer = null;
    appLogger.info('Trip ended in TRAX mode', tag: 'Trax');
    unawaited(NotificationService().showTraxEndedNotification());
    _ask(const TraxStillOnPrompt(), 'still ${_connector.selfPublicKeyHex}');
  }

  bool? _noteShown;

  void _syncNotification({bool force = false}) {
    final background = this.background;
    if (background == null) return;
    final on = isOn;
    if (!force && on == _noteShown) return;
    _noteShown = on;
    unawaited(
      background.setTraxNote(
        on ? (title: notificationTitle, text: notificationText) : null,
      ),
    );
  }

  void _setStep(TraxStep? step) {
    _step = step;
    notifyListeners();
  }

  @override
  void dispose() {
    _endTimer?.cancel();
    _connector.removeListener(_onConnector);
    unawaited(_messages.cancel());
    unawaited(_prompts.close());
    super.dispose();
  }
}
