import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/structured_message.dart';
import '../models/channel.dart';
import '../models/channel_message.dart';
import '../storage/prefs_manager.dart';
import 'notification_service.dart';

/// What the SOS dialog asks for in a channel.
class SosRequest {
  final SosMessage message;

  /// A copy to Public with the first message, never with the repeats.
  final bool alsoPublic;

  /// Repeats carry the radio's latest position. False when the user typed
  /// or picked a position over the radio's own: the repeats keep theirs.
  final bool followRadio;

  const SosRequest({
    required this.message,
    this.alsoPublic = false,
    this.followRadio = true,
  });
}

enum SosPhase {
  /// Sent, and sent again on its schedule.
  active,

  /// Restored after the app was closed for longer than
  /// [SosService.resumeWithin]: nothing goes out until the user says so.
  stopped,

  /// Cancelled; the cancel goes out once the radio is connected.
  cancelling,
}

/// The user's own SOS, while it lasts.
@immutable
class ActiveSos {
  final String channelIdKey;
  final String channelName;

  /// The row it was first sent from, and sent again from; null until the
  /// first message went out (the radio was not connected).
  final String? messageId;

  /// The copy that went to Public with the first message, if any.
  final String? publicIdKey;
  final String? publicMessageId;
  final bool alsoPublic;

  final String text;
  final String? note;
  final bool followRadio;

  /// The position last sent.
  final LatLng position;
  final DateTime startedAt;
  final DateTime? lastSentAt;
  final SosPhase phase;

  /// Who answered it, in the order their first reply came.
  final List<String> gotIt;

  const ActiveSos({
    required this.channelIdKey,
    required this.channelName,
    this.messageId,
    this.publicIdKey,
    this.publicMessageId,
    this.alsoPublic = false,
    required this.text,
    this.note,
    this.followRadio = true,
    required this.position,
    required this.startedAt,
    this.lastSentAt,
    this.phase = SosPhase.active,
    this.gotIt = const [],
  });

  SosMessage message([LatLng? at]) =>
      SosMessage(position: at ?? position, text: text, note: note);

  ActiveSos copyWith({
    String? messageId,
    String? publicIdKey,
    String? publicMessageId,
    String? text,
    String? note,
    bool? followRadio,
    LatLng? position,
    DateTime? lastSentAt,
    SosPhase? phase,
    List<String>? gotIt,
  }) => ActiveSos(
    channelIdKey: channelIdKey,
    channelName: channelName,
    messageId: messageId ?? this.messageId,
    publicIdKey: publicIdKey ?? this.publicIdKey,
    publicMessageId: publicMessageId ?? this.publicMessageId,
    alsoPublic: alsoPublic,
    text: text ?? this.text,
    note: note ?? this.note,
    followRadio: followRadio ?? this.followRadio,
    position: position ?? this.position,
    startedAt: startedAt,
    lastSentAt: lastSentAt ?? this.lastSentAt,
    phase: phase ?? this.phase,
    gotIt: gotIt ?? this.gotIt,
  );

  Map<String, Object?> toJson() => {
    'channelIdKey': channelIdKey,
    'channelName': channelName,
    'messageId': messageId,
    'publicIdKey': publicIdKey,
    'publicMessageId': publicMessageId,
    'alsoPublic': alsoPublic,
    'text': text,
    'note': note,
    'followRadio': followRadio,
    'lat': position.latitude,
    'lon': position.longitude,
    'startedAt': startedAt.millisecondsSinceEpoch,
    'lastSentAt': lastSentAt?.millisecondsSinceEpoch,
    'phase': phase.name,
    'gotIt': gotIt,
  };

  static ActiveSos? fromJson(Map<String, Object?> json) {
    try {
      DateTime? time(Object? ms) =>
          ms is int ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
      return ActiveSos(
        channelIdKey: json['channelIdKey'] as String,
        channelName: json['channelName'] as String? ?? '',
        messageId: json['messageId'] as String?,
        publicIdKey: json['publicIdKey'] as String?,
        publicMessageId: json['publicMessageId'] as String?,
        alsoPublic: json['alsoPublic'] as bool? ?? false,
        text: json['text'] as String? ?? '',
        note: json['note'] as String?,
        followRadio: json['followRadio'] as bool? ?? true,
        position: LatLng(
          (json['lat'] as num).toDouble(),
          (json['lon'] as num).toDouble(),
        ),
        startedAt: time(json['startedAt'])!,
        lastSentAt: time(json['lastSentAt']),
        phase: SosPhase.values.byName(json['phase'] as String? ?? 'active'),
        gotIt: (json['gotIt'] as List<Object?>? ?? const [])
            .whereType<String>()
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }
}

/// The user's own SOS in a channel: sent, then sent again every
/// [firstInterval] with the radio's latest position until cancelled, every
/// [slowInterval] once someone answered it. It lives here, not in a
/// screen, so leaving the chat never stops it, and is saved, so an app the
/// phone closed picks it up again ([restore]).
class SosService extends ChangeNotifier {
  SosService(this._connector, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final MeshCoreConnector _connector;
  final DateTime Function() _now;

  static const firstInterval = Duration(minutes: 2);
  static const slowInterval = Duration(minutes: 5);

  /// After a restart, an SOS last sent longer ago than this waits for the
  /// user instead of going out again by itself: it may be a test left on,
  /// or long over.
  static const resumeWithin = Duration(minutes: 30);

  static const _tickEvery = Duration(seconds: 5);
  static const _prefsKey = 'active_sos';

  ActiveSos? _sos;
  Timer? _ticker;
  bool _busy = false;
  bool _viewingPosition = false;
  final Map<String, StreamSubscription<List<ChannelMessage>>> _watches = {};
  final Map<String, List<String>> _answers = {};

  /// The chats a cancel already went to, so a retry skips them.
  final Set<String> _cancelSent = {};

  ActiveSos? get current => _sos;

  bool activeIn(String channelIdKey) =>
      _sos != null &&
      _sos!.channelIdKey == channelIdKey &&
      _sos!.phase != SosPhase.cancelling;

  Duration get interval =>
      _sos == null || _sos!.gotIt.isEmpty ? firstInterval : slowInterval;

  /// When the next repeat is due, or null when none is.
  DateTime? get nextSendAt {
    final sos = _sos;
    if (sos == null || sos.phase != SosPhase.active) return null;
    final last = sos.lastSentAt;
    return last == null ? _now() : last.add(interval);
  }

  /// Picks up an SOS saved by an earlier run of the app.
  Future<void> restore() async {
    final raw = PrefsManager.instance.getString(_prefsKey);
    if (raw == null) return;
    final saved = ActiveSos.fromJson(jsonDecode(raw) as Map<String, Object?>);
    if (saved == null) {
      await PrefsManager.instance.remove(_prefsKey);
      return;
    }
    final last = saved.lastSentAt ?? saved.startedAt;
    final stale = _now().difference(last) > resumeWithin;
    _sos = saved.phase == SosPhase.active && stale
        ? saved.copyWith(phase: SosPhase.stopped)
        : saved;
    _run();
    notifyListeners();
  }

  /// Starts an SOS in [channel]. An SOS already active there takes the new
  /// words and goes out again now; one in another chat is cancelled first.
  /// In Public it only goes once ([sendOnce]).
  Future<void> start(Channel channel, SosRequest request) async {
    if (channel.isPublicChannel) {
      await sendOnce(channel, request);
      return;
    }
    final old = _sos;
    if (old != null &&
        old.channelIdKey == channel.idKey &&
        old.phase != SosPhase.cancelling) {
      _sos = old.copyWith(
        text: request.message.text,
        note: request.message.note ?? '',
        followRadio: request.followRadio,
        position: request.message.position,
        phase: SosPhase.active,
      );
      await _save();
      _run();
      notifyListeners();
      await _repeat(now: true);
      return;
    }
    if (old != null) await cancel();
    _sos = ActiveSos(
      channelIdKey: channel.idKey,
      channelName: channel.displayName,
      alsoPublic: request.alsoPublic && !channel.isPublicChannel,
      text: request.message.text,
      note: request.message.note,
      followRadio: request.followRadio,
      position: request.message.position,
      startedAt: _now(),
    );
    _answers.clear();
    await _save();
    _run();
    notifyListeners();
    await _sendFirst();
  }

  /// An SOS in Public goes once, like any message there (Martin,
  /// 2026-11-17): it is not repeated, saved or cancelled, and an SOS active
  /// in another channel carries on untouched. False when it was not sent
  /// (the radio not connected).
  Future<bool> sendOnce(Channel channel, SosRequest request) async =>
      await _connector.sendChannelMessage(channel, request.message.toWire()) !=
      null;

  /// Sends a stopped SOS again, and keeps sending it.
  Future<void> resume() async {
    final sos = _sos;
    if (sos == null || sos.phase != SosPhase.stopped) return;
    _sos = sos.copyWith(phase: SosPhase.active);
    await _save();
    _run();
    notifyListeners();
    await _repeat(now: true);
  }

  /// Stops the repeats and tells everyone it got to: [SosMessage.cancelText]
  /// in its chat, and in Public too when a copy went there. Waits for the
  /// radio when it is not connected.
  Future<void> cancel() async {
    final sos = _sos;
    if (sos == null) return;
    _sos = sos.copyWith(phase: SosPhase.cancelling);
    await _save();
    notifyListeners();
    await _sendCancel();
  }

  /// A receiver's Got it: a reply to [sos] using the app's reply format.
  /// Its alert stops at once, even mid-sound.
  Future<void> sendGotIt(Channel channel, ChannelMessage sos) async {
    unawaited(NotificationService().cancelSos(channel.idKey, sos.senderName));
    final maxBytes = maxChannelMessageBytes(_connector.selfName);
    final wire = ChannelMessage.buildReplyWireText(
      targetName: sos.senderName,
      quoteText: sos.text,
      body: SosMessage.gotItText,
      fits: (candidate) =>
          utf8
              .encode(
                _connector.prepareChannelOutboundText(channel.index, candidate),
              )
              .length <=
          maxBytes,
    );
    if (wire == null) return;
    await _connector.sendChannelMessage(channel, wire, replyTarget: sos);
  }

  /// The Got it on an SOS notification: card [messageId] in [channel],
  /// unless it is mine or was cancelled since.
  Future<void> gotItFor(Channel channel, String messageId) async {
    final rows = await _connector.loadChannelMessagesFor(channel);
    final sos = rows.where((m) => m.messageId == messageId).firstOrNull;
    if (sos == null || sos.isOutgoing || sos.sosCancelledAt != null) return;
    await sendGotIt(channel, sos);
  }

  /// Who answered the SOS rows [ids] among [rows]: the senders of replies
  /// to them, mine left out, each once.
  static List<String> answeredBy(
    Iterable<ChannelMessage> rows,
    Set<String> ids,
  ) {
    final names = <String>[];
    for (final m in rows) {
      if (m.isOutgoing || !ids.contains(m.replyToMessageId)) continue;
      if (!names.contains(m.senderName)) names.add(m.senderName);
    }
    return names;
  }

  /// Who replied to each message among [rows], by the id replied to, me
  /// as well: what a card shows.
  static Map<String, List<String>> repliesTo(Iterable<ChannelMessage> rows) {
    final out = <String, List<String>>{};
    for (final m in rows) {
      final target = m.replyToMessageId;
      if (target == null) continue;
      final names = out.putIfAbsent(target, () => []);
      if (!names.contains(m.senderName)) names.add(m.senderName);
    }
    return out;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  // -------------------------------------------------------------------

  void _run() {
    _ticker ??= Timer.periodic(_tickEvery, (_) => unawaited(_tick()));
    final sos = _sos;
    final want = sos != null && sos.phase == SosPhase.active;
    if (want && !_viewingPosition) {
      _connector.addSelfPositionViewer();
      _viewingPosition = true;
    } else if (!want && _viewingPosition) {
      _connector.removeSelfPositionViewer();
      _viewingPosition = false;
    }
    _watchAnswers();
  }

  void _stop() {
    _ticker?.cancel();
    _ticker = null;
    if (_viewingPosition) {
      _connector.removeSelfPositionViewer();
      _viewingPosition = false;
    }
    for (final sub in _watches.values) {
      unawaited(sub.cancel());
    }
    _watches.clear();
  }

  Channel? _channel(String? idKey) {
    if (idKey == null) return null;
    for (final c in _connector.channels) {
      if (c.idKey == idKey) return c;
    }
    return null;
  }

  Future<void> _tick() async {
    final sos = _sos;
    if (sos == null) return;
    _watchAnswers();
    switch (sos.phase) {
      case SosPhase.cancelling:
        await _sendCancel();
      case SosPhase.active:
        if (sos.messageId == null) {
          await _sendFirst();
        } else {
          await _repeat();
        }
      case SosPhase.stopped:
        break;
    }
  }

  Future<void> _sendFirst() async {
    final sos = _sos;
    if (sos == null || sos.messageId != null || _busy) return;
    final channel = _channel(sos.channelIdKey);
    if (channel == null || !_connector.isConnected) return;
    _busy = true;
    try {
      final position = _position(sos);
      final wire = sos.message(position).toWire();
      final id = await _connector.sendChannelMessage(channel, wire);
      if (id == null) return;
      var next = _sos!.copyWith(
        messageId: id,
        position: position,
        lastSentAt: _now(),
      );
      final public = sos.alsoPublic
          ? _connector.channels.where((c) => c.isPublicChannel).firstOrNull
          : null;
      if (public != null) {
        final publicId = await _connector.sendChannelMessage(public, wire);
        if (publicId != null) {
          next = next.copyWith(
            publicIdKey: public.idKey,
            publicMessageId: publicId,
          );
        }
      }
      _sos = next;
      await _save();
      _watchAnswers();
      notifyListeners();
    } finally {
      _busy = false;
    }
  }

  Future<void> _repeat({bool now = false}) async {
    final sos = _sos;
    if (sos == null || sos.phase != SosPhase.active || _busy) return;
    final id = sos.messageId;
    if (id == null) return _sendFirst();
    final due = nextSendAt;
    if (!now && due != null && _now().isBefore(due)) return;
    final channel = _channel(sos.channelIdKey);
    if (channel == null) return;
    _busy = true;
    try {
      final position = _position(sos);
      final sent = await _connector.repeatChannelMessage(
        channel,
        id,
        sos.message(position).toWire(),
      );
      if (!sent || _sos?.phase != SosPhase.active) return;
      _sos = _sos!.copyWith(position: position, lastSentAt: _now());
      await _save();
      notifyListeners();
    } finally {
      _busy = false;
    }
  }

  Future<void> _sendCancel() async {
    final sos = _sos;
    if (sos == null || sos.phase != SosPhase.cancelling || _busy) return;
    if (sos.messageId == null) {
      // Nothing went out: nothing to take back.
      await _clear();
      return;
    }
    if (!_connector.isConnected) return;
    final targets = {
      sos.channelIdKey: sos.messageId!,
      if (sos.publicIdKey != null && sos.publicMessageId != null)
        sos.publicIdKey!: sos.publicMessageId!,
    };
    _busy = true;
    try {
      for (final MapEntry(key: idKey, value: messageId) in targets.entries) {
        if (_cancelSent.contains(idKey)) continue;
        final channel = _channel(idKey);
        if (channel == null) return;
        final id = await _connector.sendChannelMessage(
          channel,
          SosMessage.cancelText,
        );
        if (id == null) return;
        _cancelSent.add(idKey);
        await _connector.markSosCancelled(channel, messageId);
      }
      await _clear();
    } finally {
      _busy = false;
    }
  }

  Future<void> _clear() async {
    _sos = null;
    _answers.clear();
    _cancelSent.clear();
    _stop();
    await PrefsManager.instance.remove(_prefsKey);
    notifyListeners();
  }

  LatLng _position(ActiveSos sos) {
    final lat = _connector.selfLatitude;
    final lon = _connector.selfLongitude;
    if (sos.followRadio && _connector.hasValidLocation(lat, lon)) {
      return LatLng(lat!, lon!);
    }
    return sos.position;
  }

  /// Follows the chats the SOS went to for replies to it.
  void _watchAnswers() {
    final sos = _sos;
    if (sos == null) return;
    final wanted = {
      if (sos.messageId != null) sos.channelIdKey,
      if (sos.publicMessageId != null) sos.publicIdKey!,
    };
    for (final key in wanted) {
      if (_watches.containsKey(key)) continue;
      final channel = _channel(key);
      if (channel == null) continue;
      _watches[key] = _connector
          .watchChannelMessages(channel, limit: 200)
          .listen((rows) => _onRows(key, rows));
    }
  }

  void _onRows(String idKey, List<ChannelMessage> rows) {
    final sos = _sos;
    if (sos == null) return;
    final ids = {?sos.messageId, ?sos.publicMessageId};
    _answers[idKey] = answeredBy(rows, ids);
    final names = <String>[...sos.gotIt];
    for (final list in _answers.values) {
      for (final name in list) {
        if (!names.contains(name)) names.add(name);
      }
    }
    if (listEquals(names, sos.gotIt)) return;
    _sos = sos.copyWith(gotIt: names);
    unawaited(_save());
    notifyListeners();
  }

  Future<void> _save() async {
    final sos = _sos;
    if (sos == null) {
      await PrefsManager.instance.remove(_prefsKey);
      return;
    }
    await PrefsManager.instance.setString(_prefsKey, jsonEncode(sos.toJson()));
  }
}
