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
// With today's matcher, a reaction is looked up two ways: over every row
// that had arrived by then (today), and over only the rows that arrived in
// the 48 h before it (the proposed window). Every reaction a phone would
// send to every message, placed 1 min, 1 h and 47 h after the message
// arrived, must find the same target both ways. Parked reactions are
// re-run the same way. Timings compare today's load + rewrite with a
// window load + one-row write.
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
              find: (list, info) => ReactionHelper.findTargetIndex<ChannelMessage>(
                messages: list,
                reactionInfo: info,
                shouldSkip: (_) => false,
                getTimestampSecs: (m) => m.timestamp.millisecondsSinceEpoch ~/ 1000,
                getWireTimestampSecs: _channelStamps,
                getMessageTextVariants: (m) =>
                    MeshCoreConnector.mc1TextVariants(m.text, m.wireText),
                getSenderName: (m) => m.senderName,
                getMessageText: (m) => m.text,
              ),
            );
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

/// The connector's _channelWireSecsCandidates, rebuilt from public parts.
List<int> _channelStamps(ChannelMessage m) {
  final secs = MeshCoreConnector.wireTimestampMs(m) ~/ 1000;
  if (!m.isOutgoing) return {secs, ...m.sentWireSecs}.toList();
  return {secs, secs + 1, secs + 2, secs + 3, ...m.sentWireSecs}.toList();
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

/// Today's cost (full load + rewrite of every row) against the window's
/// (rows arrived in the last 48 h + one row written), on the temp copy.
Future<void> _timeChannel(
  AppDatabase db,
  ChannelMessageStore store,
  String idKey,
  List<ChannelMessage> rows,
  int loadMs,
) async {
  if (rows.length < 200) return;
  final sw = Stopwatch()..start();
  await store.upsertMessages(idKey, rows);
  final rewriteMs = sw.elapsedMilliseconds;

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
  sw.reset();
  final window = await db
      .customSelect(
        'SELECT payload FROM channel_message_rows '
        'WHERE node_scope = ? AND channel_id_key = ? AND received_at_us >= ? '
        'ORDER BY received_at_us, id',
        variables: [
          Variable.withString(store.publicKeyHex),
          Variable.withString(idKey),
          Variable.withInt(newestUs - _window.inMicroseconds),
        ],
      )
      .get();
  for (final row in window) {
    jsonDecode(row.read<String>('payload'));
  }
  final windowMs = sw.elapsedMilliseconds;
  sw.reset();
  await store.upsertMessage(idKey, rows.last);
  final oneRowMs = sw.elapsedMilliseconds;
  print(
    '   timing: today load $loadMs ms + rewrite ${rows.length} rows '
    '$rewriteMs ms; window load ${window.length} rows $windowMs ms + one row '
    '$oneRowMs ms (desktop; a phone is ~3x slower)',
  );
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
