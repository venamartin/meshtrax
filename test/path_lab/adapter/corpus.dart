// Frame corpus: record a live session's raw frames, replay them later
// as a deterministic regression test.
//
// Format is JSONL. First line is a meta record; every other line is one
// frame with its arrival time:
//   {"meta":{"format":"path-lab-corpus-v1","self":"<64hex>","stride":2,
//            "started":"<iso8601>"}}
//   {"t":1786550000123,"f":"88F40312..."}
//
// A corpus is raw RF as heard — adverts and path bytes are public, DM
// payloads ride along encrypted. Treat a recording like the session
// checkpoints: bench data, reviewed before ever committing one.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:path_graph/path_graph.dart';

import 'frame_adapter.dart';

const corpusFormat = 'path-lab-corpus-v1';

String _hex(Uint8List bytes) => bytes
    .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
    .join();

Uint8List _unhex(String hex) => Uint8List.fromList([
      for (var i = 0; i + 1 < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16)
    ]);

/// Appends frames to a JSONL file as they arrive.
class CorpusRecorder {
  CorpusRecorder(File file, {required String selfPubkey, required int stride})
      : _sink = file.openWrite(mode: FileMode.append) {
    _sink.writeln(jsonEncode({
      'meta': {
        'format': corpusFormat,
        'self': selfPubkey,
        'stride': stride,
        'started': DateTime.now().toIso8601String(),
      }
    }));
  }

  final IOSink _sink;
  int frames = 0;

  void record(Uint8List frame) {
    _sink.writeln(jsonEncode({
      't': DateTime.now().millisecondsSinceEpoch,
      'f': _hex(frame),
    }));
    frames++;
  }

  Future<void> close() async {
    await _sink.flush();
    await _sink.close();
  }
}

/// Replays a corpus through a fresh in-memory graph, advancing the
/// module's clock to each frame's recorded arrival — the same session
/// reproduces the same graph, whenever it runs.
Future<({PathGraph graph, PathLabAdapter adapter, int frames})> replayCorpus(
  File file, {
  PathGraphConfig config = const PathGraphConfig(),
}) async {
  final lines = await file.readAsLines();
  if (lines.isEmpty) throw const FormatException('empty corpus');

  final metaLine = jsonDecode(lines.first) as Map<String, dynamic>;
  final meta = metaLine['meta'] as Map<String, dynamic>?;
  if (meta == null || meta['format'] != corpusFormat) {
    throw FormatException('not a $corpusFormat file');
  }

  var clockMs = 0;
  final graph = PathGraph(
    NativeDatabase.memory(),
    config: config,
    now: () => DateTime.fromMillisecondsSinceEpoch(clockMs),
  );
  await graph.init();
  final self = meta['self'] as String?;
  if (self != null && self.isNotEmpty) {
    graph.setRadioIdentity(self, (meta['stride'] as num?)?.toInt() ?? 2);
  }

  final adapter = PathLabAdapter(graph);
  var frames = 0;
  for (final line in lines.skip(1)) {
    if (line.trim().isEmpty) continue;
    final row = jsonDecode(line) as Map<String, dynamic>;
    final t = (row['t'] as num?)?.toInt();
    final f = row['f'] as String?;
    if (t == null || f == null) continue;
    clockMs = t;
    adapter.handleFrame(_unhex(f));
    frames++;
  }
  await graph.flush();
  return (graph: graph, adapter: adapter, frames: frames);
}
