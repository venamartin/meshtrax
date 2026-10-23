// The printed readout is the point of this opt-in replay.
// ignore_for_file: avoid_print

@Tags(['replay'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/reaction_helper.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/storage/message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Opt-in replay of a real database saved with Settings → Debug → Export
// message database. The file is private: never commit it. A temp copy is
// opened, so the export itself is never written.
//
// With the app's matcher, a reaction is looked up two ways: over every row
// that had arrived by then (the old full search), and over only the rows
// that arrived in the 48 h before it (the window). Every reaction a phone
// would send to every message, placed 1 min, 1 h and 47 h after the
// message arrived, must find the same target both ways. Parked reactions
// are re-run the same way. The window loader must return exactly the tail
// of the history; a reaction written with updatePayload must change only
// its target's payload. Opening an older export also runs the schema
// migration on real data.
//
//   MESHTRAX_DB=<export.sqlite> flutter test test/connector/reaction_replay_test.dart

const _window = Duration(hours: 48);
const _deltas = [Duration(minutes: 1), Duration(hours: 1), Duration(hours: 47)];

// Lookups run, so an export with nothing to replay cannot pass.
var _lookupsRun = 0;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final dbPath = Platform.environment['MESHTRAX_DB'];

  test(
    '48 h window finds the same reaction targets as the full history',
    () async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      final dir = await Directory.systemTemp.createTemp('meshtrax_replay_');
      final copy = '${dir.path}${Platform.pathSeparator}replay.sqlite';
      File(dbPath!).copySync(copy);
      AppDatabase.useFileForTesting(copy);
      final db = AppDatabase.instance;
      var differences = 0;
      try {
        final indexes = await _strings(
          db,
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name IN ('idx_channel_arrival', 'idx_contact_arrival')",
        );
        print('== arrival indexes after opening: $indexes');
        expect(indexes.toSet(), {'idx_channel_arrival', 'idx_contact_arrival'});
        final scopes = await _strings(
          db,
          'SELECT node_scope FROM channel_message_rows '
          'UNION SELECT node_scope FROM contact_message_rows',
        );
        for (final scope in scopes) {
          print('== node $scope');
          final channelStore = ChannelMessageStore()..publicKeyHex = scope;
          final channelKeys = await _strings(
            db,
            'SELECT DISTINCT channel_id_key FROM channel_message_rows '
            'WHERE node_scope = ?',
            [scope],
          );
          for (final idKey in channelKeys) {
            final sw = Stopwatch()..start();
            final rows = await channelStore.loadChannelMessages(idKey);
            final loadMs = sw.elapsedMilliseconds;
            differences += _replay<ChannelMessage>(
              label: 'channel ${idKey.substring(0, 8)}',
              rows: rows,
              arrivalUs: await _arrivals(
                db,
                'channel_message_rows',
                'channel_id_key',
                scope,
                idKey,
              ),
              id: (m) => m.messageId,
              isStub: (m) => _isStub(m.isOutgoing, m.text),
              reactionCount: (m) => m.reactions.values.fold(0, (a, b) => a + b),
              reactions: (m) => [
                MeshCoreConnector.channelReactionText(m, '👍'),
                ReactionHelper.encodeReaction(
                  ReactionHelper.computeReactionHash(
                    m.timestamp.millisecondsSinceEpoch ~/ 1000,
                    m.senderName,
                    m.text,
                  ),
                  '00',
                ),
              ],
              stubText: (m) => m.text,
              find: MeshCoreConnector.channelReactionTargetIndex,
            );
            differences += await _tailCheck(
              rows.map((m) => m.messageId).toList(),
              await _arrivals(
                db,
                'channel_message_rows',
                'channel_id_key',
                scope,
                idKey,
              ),
              (since) async => [
                for (final m in await channelStore
                    .loadChannelMessagesArrivedSince(idKey, since))
                  m.messageId,
              ],
            );
            differences +=
                await _timeChannel(db, channelStore, idKey, rows, loadMs);
          }

          // Rooms only: 1:1 DMs keep their whole history either way.
          final messageStore = MessageStore()..publicKeyHex = scope;
          final roomKeys = await _strings(
            db,
            'SELECT DISTINCT m.contact_key FROM contact_message_rows m '
            'JOIN contact_rows c ON c.node_scope = m.node_scope '
            'AND lower(c.public_key_hex) = lower(m.contact_key) '
            "WHERE m.node_scope = ? AND json_extract(c.payload, '\$.type') = ?",
            [scope, advTypeRoom],
          );
          for (final key in roomKeys) {
            final sw = Stopwatch()..start();
            final rows = await messageStore.loadMessages(key);
            final loadMs = sw.elapsedMilliseconds;
            differences += _replay<Message>(
              label: 'room ${key.substring(0, 8)} (load $loadMs ms)',
              rows: rows,
              arrivalUs: await _arrivals(
                db,
                'contact_message_rows',
                'contact_key',
                scope,
                key,
              ),
              id: (m) => m.messageId,
              isStub: (m) => _isStub(m.isOutgoing, m.text),
              reactionCount: (m) => m.reactions.values.fold(0, (a, b) => a + b),
              reactions: (m) => [
                MeshCoreConnector.contactReactionText(m, '👍'),
                ReactionHelper.encodeReaction(
                  ReactionHelper.computeReactionHash(
                    m.timestamp.millisecondsSinceEpoch ~/ 1000,
                    null,
                    m.text,
                  ),
                  '00',
                ),
              ],
              stubText: (m) => m.text,
              // Room author names need the live contact list; both sides
              // use the same getters, so the comparison holds without them.
              find: (list, info) => ReactionHelper.findTargetIndex<Message>(
                messages: list,
                reactionInfo: info,
                shouldSkip: (_) => false,
                getTimestampSecs: (m) => m.timestamp.millisecondsSinceEpoch ~/ 1000,
                getWireTimestampSecs: (m) =>
                    MeshCoreConnector.contactWireSecsCandidates(m, roomSkewSecs: 0),
                getMessageTextVariants: (m) =>
                    MeshCoreConnector.mc1TextVariants(m.text),
                getSenderName: (_) => null,
                getMessageText: (m) => m.text,
              ),
            );
            differences += await _tailCheck(
              rows.map((m) => m.messageId).toList(),
              await _arrivals(
                db,
                'contact_message_rows',
                'contact_key',
                scope,
                key,
              ),
              (since) async => [
                for (final m
                    in await messageStore.loadMessagesArrivedSince(key, since))
                  m.messageId,
              ],
            );
          }
        }
      } finally {
        await db.close();
        AppDatabase.useInMemoryForTesting();
        await dir.delete(recursive: true);
      }
      expect(_lookupsRun, greaterThan(0), reason: 'nothing was replayed');
      expect(differences, 0, reason: 'targets the window would change');
    },
    skip: dbPath == null ? 'set MESHTRAX_DB to an exported database' : false,
    timeout: const Timeout(Duration(minutes: 60)),
  );
}

bool _isStub(bool isOutgoing, String text) =>
    !isOutgoing && ReactionHelper.parseMeshCoreOneReaction(text) != null;

/// The window loader must return exactly the tail of the full history, for
/// cutoffs across the whole span. Returns how many cutoffs did not.
Future<int> _tailCheck(
  List<String> fullIds,
  Map<String, int> arrivalUs,
  Future<List<String>> Function(DateTime since) arrivedSince,
) async {
  if (fullIds.isEmpty) return 0;
  var bad = 0;
  for (var q = 0; q <= 10; q++) {
    final cutoff = arrivalUs[fullIds[(fullIds.length - 1) * q ~/ 10]]!;
    final want = [
      for (final id in fullIds)
        if (arrivalUs[id]! >= cutoff) id,
    ];
    final got = await arrivedSince(DateTime.fromMicrosecondsSinceEpoch(cutoff));
    final tail = fullIds.sublist(fullIds.length - got.length);
    if (got.join('|') != want.join('|') || got.join('|') != tail.join('|')) {
      bad++;
      print('   DIFF window loader at cutoff $q/10: ${got.length} rows, '
          'expected ${want.length}');
    }
  }
  return bad;
}

/// Returns how many lookups the window answered differently.
int _replay<T>({
  required String label,
  required List<T> rows,
  required Map<String, int> arrivalUs,
  required String Function(T) id,
  required bool Function(T) isStub,
  required int Function(T) reactionCount,
  required List<String> Function(T) reactions,
  required String Function(T) stubText,
  required int Function(List<T>, ReactionInfo) find,
}) {
  if (rows.isEmpty) return 0;
  final arrival = [for (final m in rows) arrivalUs[id(m)]!];
  final windowUs = _window.inMicroseconds;

  // Rows arrived by [nowUs] (today's search) and within the window of it.
  int arrivedBy(int nowUs) => _upperBound(arrival, nowUs);
  int windowStart(int nowUs) => _lowerBound(arrival, nowUs - windowUs);

  final windowSizes = [
    for (var i = 0; i < rows.length; i++)
      i + 1 - windowStart(arrival[i]),
  ]..sort();
  final stubs = rows.where(isStub).length;
  final withReactions = rows.where((m) => reactionCount(m) > 0).length;
  final spanDays = (arrival.last - arrival.first) / Duration.microsecondsPerDay;
  print(
    '-- $label: ${rows.length} rows over ${spanDays.toStringAsFixed(1)} days, '
    '$withReactions with reactions, $stubs parked reactions; '
    '48 h window: median ${windowSizes[windowSizes.length ~/ 2]}, '
    'max ${windowSizes.last} rows',
  );

  var lookups = 0;
  var selfFound = 0;
  final diffs = <String>[];
  final sw = Stopwatch()..start();
  for (var i = 0; i < rows.length; i++) {
    if (isStub(rows[i])) continue;
    for (final (form, text) in reactions(rows[i]).indexed) {
      final info = ReactionHelper.parseIncomingReaction(text)!;
      for (final delta in _deltas) {
        final nowUs = arrival[i] + delta.inMicroseconds;
        final end = arrivedBy(nowUs);
        final full = find(rows.sublist(0, end), info);
        final start = windowStart(nowUs);
        final win = find(rows.sublist(start, end), info);
        final fullId = full < 0 ? null : id(rows[full]);
        final winId = win < 0 ? null : id(rows[start + win]);
        lookups++;
        _lookupsRun++;
        if (form == 0 && fullId == id(rows[i])) selfFound++;
        if (fullId != winId) {
          diffs.add(
            '${form == 0 ? "MC1" : "r:"} to ${id(rows[i])} at +$delta: '
            'full $fullId, window $winId',
          );
        }
      }
    }
  }

  // Parked reactions, looked up at the moment each arrived (before its own
  // row existed).
  var parkedDiffs = 0;
  var parkedFound = 0;
  for (var i = 0; i < rows.length; i++) {
    if (!isStub(rows[i])) continue;
    final info = ReactionHelper.parseIncomingReaction(stubText(rows[i]))!;
    final end = _lowerBound(arrival, arrival[i]);
    final full = find(rows.sublist(0, end), info);
    final start = windowStart(arrival[i]);
    final win = find(rows.sublist(start, end), info);
    if (full >= 0) parkedFound++;
    if ((full < 0 ? null : id(rows[full])) !=
        (win < 0 ? null : id(rows[start + win]))) {
      parkedDiffs++;
      diffs.add('parked ${id(rows[i])}: full $full, window $win');
    }
  }

  final mc1Lookups = lookups ~/ 2;
  print(
    '   $lookups lookups in ${sw.elapsedMilliseconds} ms; '
    'MC1 reaction found its own message $selfFound/$mc1Lookups; '
    'parked: $parkedFound of $stubs would match today, $parkedDiffs differ; '
    '${diffs.length} differences',
  );
  for (final d in diffs.take(20)) {
    print('   DIFF $d');
  }
  return diffs.length;
}

/// The new path on real rows: load the last 48 h, react to its newest
/// message with updatePayload, and check that only that row's payload
/// changed. Then today's cost: a rewrite of every row. Timed on the temp
/// copy; returns how many rows the write disturbed.
Future<int> _timeChannel(
  AppDatabase db,
  ChannelMessageStore store,
  String idKey,
  List<ChannelMessage> rows,
  int loadMs,
) async {
  if (rows.length < 200) return 0;
  Future<Map<String, String>> snapshot() async => {
        for (final r in await db
            .customSelect(
              'SELECT id, message_id, received_at_us, unread_eligible, payload '
              'FROM channel_message_rows WHERE node_scope = ? '
              'AND channel_id_key = ?',
              variables: [
                Variable.withString(store.publicKeyHex),
                Variable.withString(idKey),
              ],
            )
            .get())
          r.read<String>('message_id'): jsonEncode(r.data),
      };

  final before = await snapshot();
  final newestUs = (await db
          .customSelect(
            'SELECT MAX(received_at_us) AS m FROM channel_message_rows '
            'WHERE node_scope = ? AND channel_id_key = ?',
            variables: [
              Variable.withString(store.publicKeyHex),
              Variable.withString(idKey),
            ],
          )
          .getSingle())
      .read<int>('m');
  final sw = Stopwatch()..start();
  final window = await store.loadChannelMessagesArrivedSince(
    idKey,
    DateTime.fromMicrosecondsSinceEpoch(newestUs - _window.inMicroseconds),
  );
  final windowMs = sw.elapsedMilliseconds;
  final target = window.lastWhere((m) => !_isStub(m.isOutgoing, m.text));
  sw.reset();
  await store.updatePayload(
    idKey,
    target.messageId,
    (m) => m.copyWith(reactions: {...m.reactions, '🧪': 1}),
  );
  final oneRowMs = sw.elapsedMilliseconds;

  final after = await snapshot();
  var disturbed = 0;
  for (final id in before.keys) {
    final changed = before[id] != after[id];
    if (changed != (id == target.messageId)) {
      disturbed++;
      print('   DIFF write: row $id ${changed ? "changed" : "unchanged"}');
    }
  }
  final was = jsonDecode(before[target.messageId]!) as Map;
  final now = jsonDecode(after[target.messageId]!) as Map;
  for (final column in ['id', 'received_at_us', 'unread_eligible']) {
    if (was[column] != now[column]) {
      disturbed++;
      print('   DIFF write: target $column ${was[column]} -> ${now[column]}');
    }
  }

  sw.reset();
  await store.upsertMessages(idKey, rows);
  final rewriteMs = sw.elapsedMilliseconds;
  print(
    '   timing: today load $loadMs ms + rewrite ${rows.length} rows '
    '$rewriteMs ms; window load ${window.length} rows $windowMs ms + one row '
    '$oneRowMs ms (desktop; a phone is ~3x slower); '
    'other rows disturbed by the write: $disturbed',
  );
  return disturbed;
}

Future<List<String>> _strings(
  AppDatabase db,
  String sql, [
  List<Object> args = const [],
]) async {
  final rows = await db
      .customSelect(
        sql,
        variables: [
          for (final a in args)
            a is int ? Variable.withInt(a) : Variable.withString('$a'),
        ],
      )
      .get();
  return [for (final r in rows) r.data.values.first as String];
}

Future<Map<String, int>> _arrivals(
  AppDatabase db,
  String table,
  String keyColumn,
  String scope,
  String key,
) async {
  final rows = await db
      .customSelect(
        'SELECT message_id, received_at_us FROM $table '
        'WHERE node_scope = ? AND $keyColumn = ?',
        variables: [Variable.withString(scope), Variable.withString(key)],
      )
      .get();
  return {
    for (final r in rows)
      r.read<String>('message_id'): r.read<int>('received_at_us'),
  };
}

/// First index whose value is >= [x] in ascending [a].
int _lowerBound(List<int> a, int x) {
  var lo = 0, hi = a.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (a[mid] < x) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}

/// First index whose value is > [x] in ascending [a].
int _upperBound(List<int> a, int x) {
  var lo = 0, hi = a.length;
  while (lo < hi) {
    final mid = (lo + hi) >> 1;
    if (a[mid] <= x) {
      lo = mid + 1;
    } else {
      hi = mid;
    }
  }
  return lo;
}
