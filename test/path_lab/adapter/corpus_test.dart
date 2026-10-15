import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'corpus.dart';

// A raw-RX push (0x88) carrying a 2-hop stride-2 path A277→1312:
// [push][snr][rssi][header route=1 type=0][path_len 0x42][path×4][payload]
String frameLine(int t, String payloadHex) => jsonEncode({
      't': t,
      'f': '8820000142A2771312$payloadHex',
    });

const metaLine =
    '{"meta":{"format":"path-lab-corpus-v1","self":"abababab","stride":2,'
    '"started":"2026-08-14T12:00:00"}}';

Future<File> corpusFile(List<String> lines) async {
  final dir = await Directory.systemTemp.createTemp('pl_corpus');
  final f = File('${dir.path}/c.jsonl');
  await f.writeAsString(lines.join('\n'));
  return f;
}

void main() {
  test('a recorded session replays into the expected graph', () async {
    final f = await corpusFile([
      metaLine,
      frameLine(1786550000000, 'DEAD'),
      frameLine(1786550002000, 'BEEF'), // different payload → counts again
      frameLine(1786550004000, 'BEEF'), // identical → variant-dedup drop
    ]);
    final r = await replayCorpus(f);
    expect(r.frames, 3);
    expect(r.adapter.framesSeen, 3);

    final snap = r.graph.snapshot();
    expect(snap.nodes.keys, containsAll(['A277', '1312']));
    final edge = snap.edges[('A277', '1312')]!;
    expect(edge.obsCount, 2, reason: 'third frame deduped by payload');
    // Ingress attribution: anonymous frames feed edges only, but the
    // radio identity from the meta line gives self a last-hop entry.
    expect(r.graph.egressCandidates().single.repeaterHash, '1312');
    await r.graph.dispose();
  });

  test('replay is deterministic — same corpus, same graph, any day',
      () async {
    final f = await corpusFile([
      metaLine,
      frameLine(1786550000000, 'DEAD'),
      frameLine(1786550002000, 'BEEF'),
    ]);
    final a = await replayCorpus(f);
    final b = await replayCorpus(f);
    // The module clock is the recorded clock, so even generated_at and
    // every decayed weight reproduce exactly.
    expect(jsonEncode(a.graph.exportGraph()),
        jsonEncode(b.graph.exportGraph()));
    expect(jsonEncode(a.graph.saveSession()),
        jsonEncode(b.graph.saveSession()));
    await a.graph.dispose();
    await b.graph.dispose();
  });

  test('non-corpus files are rejected', () async {
    final f = await corpusFile(['{"meta":{"format":"something-else"}}']);
    expect(replayCorpus(f), throwsFormatException);
  });
}
