@Tags(['replay'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';
import 'package:test/test.dart';

// Opt-in replay of a real session checkpoint (never committed: it is
// private). Every route answer the module gives, at several clocks, is
// written to a snapshot or compared against one, so a change that should
// only make lookups faster can prove it changed no answer.
//
//   PATH_GRAPH_SESSION=<session.json>
//   PATH_GRAPH_SNAPSHOT_OUT=<file>  write the answers
//   PATH_GRAPH_SNAPSHOT=<file>      compare the answers
//
//   dart test test/session_replay_test.dart -t replay

const _minute = 60 * 1000;
const _offsets = [0, 60 * _minute, 2 * 24 * 60 * _minute];

void main() {
  final sessionPath = Platform.environment['PATH_GRAPH_SESSION'];

  test('session replay gives the same answers', () async {
    final session =
        jsonDecode(File(sessionPath!).readAsStringSync()) as Map<String, dynamic>;
    final savedAt = DateTime.parse(session['saved_at'] as String);
    var nowMillis = savedAt.millisecondsSinceEpoch;
    final graph = PathGraph(NativeDatabase.memory(),
        now: () => DateTime.fromMillisecondsSinceEpoch(nowMillis));
    await graph.init();
    await graph.loadSession(session);

    final contacts = {
      ...graph.contactsWithIngress(),
      for (final c in (session['contacts'] as List? ?? const []))
        ((c as Map)['pubkey'] as String).toLowerCase(),
    }.toList()
      ..sort();
    // Every 20th repeater: a route to each costs as much as one to a
    // contact, and thousands of them would take hours on the old search.
    final allRepeaters = [
      for (final n in (session['nodes'] as List? ?? const []))
        (n as Map)['hash'] as String,
    ]..sort();
    final repeaters = [
      for (var i = 0; i < allRepeaters.length; i += 20) allRepeaters[i],
    ];
    print('nodes ${allRepeaters.length}, edges ${(session['edges'] as List).length}, '
        'ingress rows ${(session['ingress'] as List).length}, '
        'contacts ${contacts.length}');

    final lines = <String>[];
    for (final offset in _offsets) {
      nowMillis = savedAt.millisecondsSinceEpoch + offset;
      lines.add('# clock +${offset ~/ _minute} min');

      for (final c in graph.egressCandidates()) {
        lines.add('egress ${_candidate(c)} hold=${graph.doorstepHold(c)?.name}');
      }

      // The app's lookup (PathGraphService.candidatesFor), timed.
      final sw = Stopwatch()..start();
      var slowest = 0;
      var slowestKey = '';
      final answers = <String>[];
      for (final key in contacts) {
        final one = Stopwatch()..start();
        final best = graph.findPath(key);
        final alternatives = graph.findAlternatives(key, count: 3);
        one.stop();
        if (one.elapsedMicroseconds > slowest) {
          slowest = one.elapsedMicroseconds;
          slowestKey = key;
        }
        answers.add('route $key ${_result(best)} | '
            '${alternatives.map(_result).join(' | ')}');
      }
      sw.stop();
      print('clock +${offset ~/ _minute} min: ${contacts.length} lookups in '
          '${sw.elapsedMilliseconds} ms, '
          'avg ${(sw.elapsedMicroseconds / contacts.length / 1000).toStringAsFixed(1)} ms, '
          'slowest ${(slowest / 1000).toStringAsFixed(1)} ms ($slowestKey)');
      lines.addAll(answers);

      for (final key in contacts) {
        final ingress = graph.ingressCandidates(key);
        if (ingress.isEmpty) continue;
        lines.add('ingress $key ${ingress.map(_candidate).join(' ')}');
      }

      final rsw = Stopwatch()..start();
      for (final hash in repeaters) {
        lines.add('repeater $hash ${_result(graph.findPathToRepeater(hash))} | '
            '${graph.findAlternativesToRepeater(hash, count: 3).map(_result).join(' | ')}');
      }
      rsw.stop();
      print('clock +${offset ~/ _minute} min: ${repeaters.length} repeater '
          'lookups in ${rsw.elapsedMilliseconds} ms');
    }
    await graph.dispose();

    final out = Platform.environment['PATH_GRAPH_SNAPSHOT_OUT'];
    if (out != null) File(out).writeAsStringSync('${lines.join('\n')}\n');
    final expected = Platform.environment['PATH_GRAPH_SNAPSHOT'];
    if (expected != null) {
      final want = File(expected).readAsLinesSync();
      expect(lines.length, want.length, reason: 'answer count');
      for (var i = 0; i < want.length; i++) {
        expect(lines[i], want[i], reason: 'line ${i + 1}');
      }
    }
  },
      skip: sessionPath == null ? 'set PATH_GRAPH_SESSION' : false,
      timeout: const Timeout(Duration(minutes: 30)));
}

String _result(PathResult r) => switch (r) {
      DirectResult() => 'direct',
      FloodResult(:final reason) => 'flood:${reason.name}',
      RouteResult r => 'route:${r.pathBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}'
          ' p=${r.estDelivery} hops=${r.hopProbabilities.join(',')}'
          ' proven=${r.egressProven}/${r.ingressProven}',
    };

String _candidate(Candidate c) => '${c.repeaterHash}:w=${c.weight}'
    ':${c.tier.name}:p=${c.proven}:h=${c.heard}:f=${c.finalCount}'
    ':pen=${c.penultimateCount}:pc=${c.provenCount}:pa=${c.provenAt}'
    ':ls=${c.lastSeen}:fs=${c.failedSinceProof}'
    ':up=${c.uplinkSnr}:down=${c.downlinkSnr}';
