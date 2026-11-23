import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:traxpix/traxpix.dart';
import 'image_codec_bundle.dart';
import 'image_safety.dart';
import 'litert_api.dart';
import 'litert_codec_backend.dart';

/// Owns a long-lived [Isolate] and the LiteRT models inside it.
///
/// A rebuild must never run on the root isolate: it would freeze the UI and
/// stall the BLE notify stream the app reads mesh frames from. LiteRT is
/// reached through FFI, so the worker needs no platform channel.
///
/// Jobs run one at a time, in the order they were sent.
class ImageCodecSession {
  final Isolate _isolate;
  final SendPort _toWorker;
  final ReceivePort _fromWorker;
  final ReceivePort _errors;
  final Map<int, Completer<Object>> _pending = {};
  final Completer<void> _exited = Completer<void>();
  int _nextJobId = 1;
  StateError? _closed;

  ImageCodecSession._(
    this._isolate,
    this._toWorker,
    this._fromWorker,
    this._errors,
  );

  /// Spawns the worker and waits until it has checked [bundle]'s files and
  /// parsed the tables. No model is compiled yet.
  ///
  /// [weightCacheDir] overrides the bundle's; [libraryPath] overrides the
  /// platform's LiteRT library, for host tests.
  static Future<ImageCodecSession> spawn(
    ImageCodecBundle bundle, {
    int? threads,
    String? weightCacheDir,
    String? libraryPath,
  }) async {
    final fromWorker = ReceivePort();
    final errors = ReceivePort();
    final handshake = Completer<Map<String, Object?>>();
    ImageCodecSession? session;

    fromWorker.listen((message) {
      if (message is! Map) return;
      final map = message.cast<String, Object?>();
      final active = session;
      if (active != null) {
        active._handleMessage(map);
      } else if (!handshake.isCompleted) {
        handshake.complete(map);
      }
    });
    errors.listen((message) {
      final description = message == null
          ? 'exited'
          : message is List && message.isNotEmpty
          ? message.first.toString()
          : message.toString();
      final active = session;
      if (active != null) {
        active._markDead(
          active._closed ?? StateError('LiteRT isolate died: $description'),
        );
      } else if (!handshake.isCompleted) {
        handshake.complete({'type': 'fatal', 'error': description});
      }
    });

    final Isolate isolate;
    try {
      isolate = await Isolate.spawn<_Boot>(
        _workerMain,
        (
          reply: fromWorker.sendPort,
          bundle: bundle,
          threads: threads ?? Platform.numberOfProcessors,
          weightCacheDir: weightCacheDir ?? bundle.weightCacheDir,
          libraryPath: libraryPath,
        ),
        errorsAreFatal: true,
        onError: errors.sendPort,
        onExit: errors.sendPort,
        debugName: 'litert-codec',
      );
    } catch (_) {
      fromWorker.close();
      errors.close();
      rethrow;
    }
    final reply = await handshake.future;
    if (reply['type'] != 'ready') {
      isolate.kill(priority: Isolate.immediate);
      fromWorker.close();
      errors.close();
      throw StateError('LiteRT codec failed to start: ${reply['error']}');
    }
    return session = ImageCodecSession._(
      isolate,
      reply['port'] as SendPort,
      fromWorker,
      errors,
    );
  }

  /// Checks the photo, covers its faces as [faces] says, then codes it. A
  /// flagged photo has no bitstream.
  Future<EncodedImage> encode(
    Uint8List rgbBytes, {
    FaceCover faces = FaceCover.none,
  }) => _submit(switch (faces) {
    FaceCover.none => 'encode',
    FaceCover.blur => 'encodeBlurred',
    FaceCover.dark => 'encodeDarkened',
  }, rgbBytes);

  /// Rebuilds the photo and checks it, with [forSender] by the sender's
  /// stricter check. A flagged picture has no pixels.
  Future<RebuiltImage> rebuild(Uint8List bitstream, {bool forSender = false}) =>
      _submit(forSender ? 'senderRebuild' : 'rebuild', bitstream);

  /// The rANS bitstream -> `y_hat [1, 256, 16, 16]`, without the decoder.
  Future<Float32List> decodeToLatent(Uint8List bitstream) =>
      _submit('decodeToLatent', bitstream);

  /// The safety classifier's scores, nothing else.
  Future<ImageSafetyScores> classify(Uint8List rgbBytes) =>
      _submit('classify', rgbBytes);

  /// Enlarges a rebuilt 512 x 512 picture 4x and checks it, with every other
  /// model released first. A flagged picture has no pixels.
  Future<EnhancedImage> enhance(Uint8List rgbBytes) =>
      _submit('enhance', rgbBytes);

  Future<T> _submit<T extends Object>(String op, Uint8List bytes) async {
    final closed = _closed;
    if (closed != null) throw closed;
    final id = _nextJobId++;
    final job = Completer<Object>();
    _pending[id] = job;
    _toWorker.send({'type': 'job', 'id': id, 'op': op, 'bytes': bytes});
    return await job.future as T;
  }

  void _handleMessage(Map<String, Object?> message) {
    final id = message['id'];
    final job = id is int ? _pending.remove(id) : null;
    switch (message['type']) {
      case 'result':
        job?.complete(message['value']!);
      case 'error':
        job?.completeError(
          StateError(message['error']?.toString() ?? 'LiteRT codec failed.'),
        );
    }
  }

  void _markDead(StateError error) {
    _closed = error;
    final jobs = _pending.values.toList();
    _pending.clear();
    for (final job in jobs) {
      job.completeError(error);
    }
    _isolate.kill(priority: Isolate.immediate);
    _fromWorker.close();
    _errors.close();
    if (!_exited.isCompleted) _exited.complete();
  }

  /// Finishes the jobs already sent, frees the models, and ends the worker.
  Future<void> dispose() async {
    if (_closed == null) {
      _closed = StateError('LiteRT codec session disposed.');
      _toWorker.send(const {'type': 'shutdown'});
    }
    await _exited.future;
  }
}

typedef _Boot = ({
  SendPort reply,
  ImageCodecBundle bundle,
  int threads,
  String? weightCacheDir,
  String? libraryPath,
});

Future<void> _workerMain(_Boot boot) async {
  final reply = boot.reply;
  final LiteRtImageCodecBackend backend;
  try {
    for (final path in boot.bundle.allPaths) {
      if (!File(path).existsSync()) {
        throw FileSystemException('LiteRT codec file not found', path);
      }
    }
    if (boot.weightCacheDir case final dir?) {
      Directory(dir).createSync(recursive: true);
    }
    backend = LiteRtImageCodecBackend(
      boot.bundle,
      AeicRansCoders(
        EntropyTables.parse(await File(boot.bundle.tablesPath).readAsBytes()),
      ),
      api: LiteRtApi.open(boot.libraryPath),
      threads: boot.threads,
      weightCacheDir: boot.weightCacheDir,
    );
  } catch (error) {
    reply.send({'type': 'fatal', 'error': error.toString()});
    return;
  }

  final commands = ReceivePort();
  var queue = Future<void>.value();
  reply.send({'type': 'ready', 'port': commands.sendPort});
  commands.listen((message) {
    if (message is! Map) return;
    final map = message.cast<String, Object?>();
    switch (map['type']) {
      case 'shutdown':
        queue = queue.then((_) {
          backend.dispose();
          Isolate.exit();
        });
      case 'job':
        queue = queue.then((_) async {
          final id = map['id'] as int;
          try {
            final bytes = map['bytes'] as Uint8List;
            final Object value = switch (map['op']) {
              'encode' => await backend.checkedEncode(bytes),
              'encodeBlurred' => await backend.checkedEncode(
                bytes,
                cover: FaceCover.blur,
              ),
              'encodeDarkened' => await backend.checkedEncode(
                bytes,
                cover: FaceCover.dark,
              ),
              'rebuild' => await backend.rebuild(bytes),
              'senderRebuild' => await backend.rebuild(bytes, forSender: true),
              'decodeToLatent' => await backend.decodeToLatent(bytes),
              'classify' => backend.classify(bytes),
              'enhance' => backend.enhance(bytes),
              final op => throw StateError('Unknown codec op: $op'),
            };
            reply.send({'type': 'result', 'id': id, 'value': value});
          } catch (error) {
            reply.send({'type': 'error', 'id': id, 'error': error.toString()});
          }
        });
    }
  });
}
