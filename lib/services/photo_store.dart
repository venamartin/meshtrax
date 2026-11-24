import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show rootBundle;
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:traxmap/traxmap.dart';
import 'package:traxpix/traxpix.dart' show PhotoPosition;
import 'package:traxpix_litert/traxpix_litert.dart';

import '../storage/prefs_manager.dart';
import '../utils/app_logger.dart';

/// The ft8 model's LiteRT files in [dir], and the face models in
/// [facesDir] when given.
ImageCodecBundle ft8Bundle(String dir, {String? facesDir}) =>
    ImageCodecBundle.inDirectory(dir, facesDir: facesDir);

/// One photo in a chat.
class PhotoRecord {
  final String messageId;

  /// Coded size, the bytes that crossed the radio.
  final int bytes;

  /// Packets on air, the repair packet included.
  final int packets;
  final bool outgoing;
  final bool recoveredWithParity;

  /// Null until the rebuilt picture has been checked.
  bool? flagged;

  /// Reported by the user: hidden for good, picture and code deleted.
  bool reported;

  /// The few words the sender typed with it, if any; shown as text.
  final String? tag;

  /// Where the sender sent it from, when they included their position.
  final PhotoPosition? position;

  /// Of a photo this radio sent through repeaters: how many of its
  /// [packets] a repeater was heard passing on. Null for one sent zero hop,
  /// a received photo, or one sent before MeshTrax listened for them.
  int? packetsPassedOn;

  PhotoRecord({
    required this.messageId,
    required this.bytes,
    required this.packets,
    required this.outgoing,
    this.recoveredWithParity = false,
    this.flagged,
    this.reported = false,
    this.tag,
    this.position,
    this.packetsPassedOn,
  });

  Map<String, Object?> toJson() => {
    'messageId': messageId,
    'bytes': bytes,
    'packets': packets,
    'outgoing': outgoing,
    'recoveredWithParity': recoveredWithParity,
    'flagged': flagged,
    'reported': reported,
    'tag': tag,
    'position': position?.encode(),
    'packetsPassedOn': packetsPassedOn,
  };

  factory PhotoRecord.fromJson(Map<String, Object?> j) => PhotoRecord(
    messageId: j['messageId'] as String,
    bytes: j['bytes'] as int,
    packets: j['packets'] as int,
    outgoing: j['outgoing'] as bool,
    recoveredWithParity: j['recoveredWithParity'] as bool? ?? false,
    flagged: j['flagged'] as bool?,
    reported: j['reported'] as bool? ?? false,
    tag: j['tag'] as String?,
    position: switch (j['position']) {
      final List<Object?> b => PhotoPosition.decode(b.cast<int>()),
      _ => null,
    },
    packetsPassedOn: j['packetsPassedOn'] as int?,
  );
}

enum RebuildOutcome { shown, flagged, noMemory, noModel, failed }

/// How much room rebuilt pictures may take: about 250 photos at ~400 KB.
const int kPhotoCacheBytes = 100 * 1000 * 1000;

/// Drops the oldest files in [dir] until they take at most [cap] bytes; their
/// photos show "Rebuild" again.
void trimPictureCache(Directory dir, {int cap = kPhotoCacheBytes}) {
  final files = [
    for (final f in dir.listSync().whereType<File>()) (f, f.statSync()),
  ]..sort((a, b) => a.$2.modified.compareTo(b.$2.modified));
  var total = files.fold(0, (sum, f) => sum + f.$2.size);
  for (final (file, stat) in files) {
    if (total <= cap) break;
    file.deleteSync();
    total -= stat.size;
  }
}

/// The photos in chats. Each keeps the coded bytes that crossed the radio
/// and, once rebuilt and passed by the safety check, the rebuilt picture as a
/// PNG. A flagged photo never has its pixels stored.
class PhotoStore extends ChangeNotifier {
  static final PhotoStore instance = PhotoStore._();
  PhotoStore._();

  final Map<String, PhotoRecord> _records = {};
  final Set<String> _rebuilding = {};
  Future<void>? _loading;
  Future<void> _queue = Future<void>.value();
  late String _dir;
  late String _models;

  /// The rebuilt pictures: a cache in the system's cache folder, which no
  /// device backup includes, kept under [kPhotoCacheBytes]. Null until
  /// loaded. The coded bytes and records stay in [_dir], in backups.
  String? _cache;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final docs = (await getApplicationDocumentsDirectory()).path;
    final cache = '${(await getApplicationCacheDirectory()).path}/photos';
    _dir = '$docs/photos';
    _models = '$docs/ft8';
    Directory(_dir).createSync(recursive: true);
    Directory(cache).createSync(recursive: true);
    for (final f in Directory(_dir).listSync().whereType<File>()) {
      if (!f.path.endsWith('.json')) continue;
      try {
        final r = PhotoRecord.fromJson(
          jsonDecode(f.readAsStringSync()) as Map<String, Object?>,
        );
        _records[r.messageId] = r;
      } catch (_) {}
    }
    _cache = cache;
    _trimCache();
    notifyListeners();
  }

  File _pngOf(String messageId) => File('$_cache/$messageId.png');

  void _trimCache() => trimPictureCache(Directory(_cache!));

  PhotoRecord? recordFor(String messageId) => _records[messageId];
  bool isRebuilding(String messageId) => _rebuilding.contains(messageId);

  /// The rebuilt picture, if this photo has one.
  File? imageFor(String messageId) {
    if (_cache == null) return null;
    final f = _pngOf(messageId);
    return f.existsSync() ? f : null;
  }

  ImageCodecBundle get bundle => ft8Bundle(_models);

  /// The bundle for coding a photo to send: [bundle] and the two face models,
  /// which come with the app. LiteRT reads models from files, so they're
  /// copied to the cache folder, which no backup includes, whenever they
  /// aren't there.
  Future<ImageCodecBundle> sendingBundle() async {
    await load();
    final faces = '${(await getApplicationCacheDirectory()).path}/faces';
    Directory(faces).createSync(recursive: true);
    for (final name in [kFaceShortRangeFile, kFaceFullRangeFile]) {
      final file = File('$faces/$name');
      final data = await rootBundle.load('assets/models/$name');
      if (file.existsSync() && file.lengthSync() == data.lengthInBytes) {
        continue;
      }
      File('${file.path}.part')
        ..writeAsBytesSync(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          flush: true,
        )
        ..renameSync(file.path);
    }
    return ft8Bundle(_models, facesDir: faces);
  }

  /// Whether the photo model files are on this device.
  Future<bool> modelsReady() async {
    await load();
    return bundle.allPaths.every((p) => File(p).existsSync());
  }

  /// Files a photo under [record.messageId]: its coded [bitstream] and, for a
  /// photo already rebuilt and passed (the sender's preview), its [png].
  Future<void> save(
    PhotoRecord record,
    Uint8List bitstream, {
    Uint8List? png,
  }) async {
    await load();
    File('$_dir/${record.messageId}.aeic').writeAsBytesSync(bitstream);
    if (png != null) {
      _pngOf(record.messageId).writeAsBytesSync(png);
      _trimCache();
      record.flagged = false;
    }
    _writeRecord(record);
    _records[record.messageId] = record;
    notifyListeners();
  }

  /// The coded bytes as they crossed the radio, if still kept.
  Uint8List? codeFor(String messageId) {
    if (_loading == null) return null;
    final f = File('$_dir/$messageId.aeic');
    return f.existsSync() ? f.readAsBytesSync() : null;
  }

  /// Hides a photo for good: the rebuilt picture and the code are deleted,
  /// only the record that it was reported stays.
  Future<void> markReported(String messageId) async {
    await load();
    final record = _records[messageId];
    if (record == null) return;
    record.reported = true;
    for (final f in [_pngOf(messageId), File('$_dir/$messageId.aeic')]) {
      if (f.existsSync()) f.deleteSync();
    }
    _writeRecord(record);
    notifyListeners();
  }

  /// Records that repeaters were heard passing on [count] of the packets of
  /// my photo [messageId].
  Future<void> notePassedOn(String messageId, int count) async {
    await load();
    final record = _records[messageId];
    if (record == null || record.packetsPassedOn == count) return;
    record.packetsPassedOn = count;
    _writeRecord(record);
    notifyListeners();
  }

  /// Deletes everything kept for a photo whose message was deleted: the
  /// rebuilt picture, the coded bytes and the record.
  Future<void> forget(String messageId) async {
    await load();
    if (_records.remove(messageId) == null) return;
    for (final f in [
      _pngOf(messageId),
      File('$_dir/$messageId.aeic'),
      File('$_dir/$messageId.json'),
    ]) {
      if (f.existsSync()) f.deleteSync();
    }
    notifyListeners();
  }

  void _writeRecord(PhotoRecord r) =>
      File('$_dir/${r.messageId}.json')
          .writeAsStringSync(jsonEncode(r.toJson()));

  static const _enabledKey = 'photos_enabled';

  /// Photos, the switch in App settings' Messaging card: off by default.
  /// On, chats offer to send a photo and settings offer the photo model.
  bool get photosEnabled => PrefsManager.instance.getBool(_enabledKey) ?? false;

  set photosEnabled(bool on) {
    unawaited(PrefsManager.instance.setBool(_enabledKey, on));
    notifyListeners();
  }

  static const _automaticKey = 'photo_rebuild_automatically';

  /// "Rebuild received photos automatically": off by default, so a photo
  /// waits for a tap unless this is on.
  bool get rebuildAutomatically =>
      PrefsManager.instance.getBool(_automaticKey) ?? false;

  set rebuildAutomatically(bool on) {
    unawaited(PrefsManager.instance.setBool(_automaticKey, on));
    notifyListeners();
  }

  static const _enlargeKey = 'photo_enlarge_automatically';

  /// "Enlarge photos automatically": off by default. Only phones with 8 GB
  /// of memory or more offer it (`photoAutoEnlargeAllowed`).
  bool get enlargeAutomatically =>
      PrefsManager.instance.getBool(_enlargeKey) ?? false;

  set enlargeAutomatically(bool on) {
    unawaited(PrefsManager.instance.setBool(_enlargeKey, on));
    notifyListeners();
  }

  static const _noLimitsKey = 'photo_ignore_time_limits';

  /// "Ignore the photo time limits": off by default. For testing: on, this
  /// phone sends photos without the waits between them.
  bool get ignoreTimeLimits =>
      PrefsManager.instance.getBool(_noLimitsKey) ?? false;

  set ignoreTimeLimits(bool on) {
    unawaited(PrefsManager.instance.setBool(_noLimitsKey, on));
    notifyListeners();
  }

  final _waitingForFront = <String>{};
  AppLifecycleListener? _frontListener;

  /// Rebuilds a photo that just arrived, by itself: only while the app is in
  /// front, and only when the phone has the memory now. Short of memory, it
  /// leaves the photo for a tap rather than free the map's memory.
  void rebuildAutomaticallyWhenInFront(String messageId) {
    final state = WidgetsBinding.instance.lifecycleState;
    if (state == null || state == AppLifecycleState.resumed) {
      unawaited(rebuild(messageId, makeRoom: false));
      return;
    }
    _waitingForFront.add(messageId);
    _frontListener ??= AppLifecycleListener(
      onResume: () {
        final waiting = [..._waitingForFront];
        _waitingForFront.clear();
        for (final id in waiting) {
          unawaited(rebuild(id, makeRoom: false));
        }
      },
    );
  }

  /// Rebuilds and checks one photo, one at a time. With [makeRoom] it frees
  /// the map's memory if short; either way it gives up with
  /// [RebuildOutcome.noMemory] rather than let iOS stop the app.
  Future<RebuildOutcome> rebuild(String messageId, {bool makeRoom = true}) {
    final done = Completer<RebuildOutcome>();
    _queue = _queue.then((_) async {
      done.complete(await _rebuild(messageId, makeRoom: makeRoom));
    });
    return done.future;
  }

  Future<RebuildOutcome> _rebuild(
    String messageId, {
    required bool makeRoom,
  }) async {
    await load();
    final record = _records[messageId];
    final coded = File('$_dir/$messageId.aeic');
    if (record == null || !coded.existsSync()) return RebuildOutcome.failed;
    // Already done, e.g. tapped while the automatic one waited its turn.
    if (!makeRoom && record.flagged != null) {
      return record.flagged! ? RebuildOutcome.flagged : RebuildOutcome.shown;
    }
    if (!await modelsReady()) return RebuildOutcome.noModel;
    if (!imageCodecHasRoomToRebuild()) {
      if (!makeRoom) return RebuildOutcome.noMemory;
      releaseMapMemory();
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!imageCodecHasRoomToRebuild()) return RebuildOutcome.noMemory;
    }
    _rebuilding.add(messageId);
    notifyListeners();
    ImageCodecSession? codec;
    try {
      codec = await ImageCodecSession.spawn(bundle);
      final rebuilt = await codec.rebuild(coded.readAsBytesSync());
      final flagged = rebuilt.flagged;
      record.flagged = flagged;
      final rgb = flagged ? null : rebuilt.rgb;
      if (rgb != null) {
        _pngOf(messageId).writeAsBytesSync(await rgbToPng(rgb));
        _trimCache();
      }
      _writeRecord(record);
      return flagged ? RebuildOutcome.flagged : RebuildOutcome.shown;
    } catch (e) {
      appLogger.warn('Rebuilding a photo: $e', tag: 'Photos');
      return RebuildOutcome.failed;
    } finally {
      await codec?.dispose();
      _rebuilding.remove(messageId);
      notifyListeners();
    }
  }

  /// Enlarges a rebuilt photo 4x and checks it, in the same queue as the
  /// rebuilds, so the two never share the memory; frees the map's memory if
  /// short. The enlarged picture isn't kept: it's for the screen showing it.
  Future<({RebuildOutcome outcome, Uint8List? rgb})> enlarge(String messageId) =>
      _enlargeQueued(() async {
        await load();
        try {
          return imageFor(messageId)?.readAsBytesSync();
        } on FileSystemException catch (e) {
          appLogger.warn('Enlarging a photo: $e', tag: 'Photos');
          return null;
        }
      });

  /// The same for the sender's preview, before the photo is sent.
  Future<({RebuildOutcome outcome, Uint8List? rgb})> enlargePng(
    Uint8List png,
  ) => _enlargeQueued(() async => png);

  Future<({RebuildOutcome outcome, Uint8List? rgb})> _enlargeQueued(
    Future<Uint8List?> Function() png,
  ) {
    final done = Completer<({RebuildOutcome outcome, Uint8List? rgb})>();
    _queue = _queue.then((_) async {
      done.complete(await _enlarge(await png()));
    });
    return done.future;
  }

  Future<({RebuildOutcome outcome, Uint8List? rgb})> _enlarge(
    Uint8List? png,
  ) async {
    if (png == null) return (outcome: RebuildOutcome.failed, rgb: null);
    if (!await modelsReady()) {
      return (outcome: RebuildOutcome.noModel, rgb: null);
    }
    if (!imageCodecHasRoomToEnhance()) {
      releaseMapMemory();
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!imageCodecHasRoomToEnhance()) {
        return (outcome: RebuildOutcome.noMemory, rgb: null);
      }
    }
    ImageCodecSession? codec;
    try {
      final rgb = await pngToRgb(png);
      codec = await ImageCodecSession.spawn(bundle);
      final enlarged = await codec.enhance(rgb);
      return enlarged.flagged
          ? (outcome: RebuildOutcome.flagged, rgb: null)
          : (outcome: RebuildOutcome.shown, rgb: enlarged.rgb);
    } catch (e) {
      appLogger.warn('Enlarging a photo: $e', tag: 'Photos');
      return (outcome: RebuildOutcome.failed, rgb: null);
    } finally {
      await codec?.dispose();
    }
  }
}

/// Packed 8-bit RGB, 512x512 -> a dart:ui image.
Future<ui.Image> rgbToImage(Uint8List rgb, {int side = 512}) async {
  final rgba = Uint8List(side * side * 4);
  for (var i = 0, j = 0; i < rgb.length; i += 3, j += 4) {
    rgba[j] = rgb[i];
    rgba[j + 1] = rgb[i + 1];
    rgba[j + 2] = rgb[i + 2];
    rgba[j + 3] = 255;
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(rgba);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: side,
    height: side,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  return (await codec.getNextFrame()).image;
}

/// Packed 8-bit RGB, 512x512 -> PNG bytes.
Future<Uint8List> rgbToPng(Uint8List rgb) async {
  final image = await rgbToImage(rgb);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}

/// A rebuilt picture's PNG -> packed 8-bit RGB.
Future<Uint8List> pngToRgb(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  final image = (await codec.getNextFrame()).image;
  final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
      .buffer
      .asUint8List();
  image.dispose();
  final rgb = Uint8List(rgba.length ~/ 4 * 3);
  for (var i = 0, j = 0; j < rgba.length; i += 3, j += 4) {
    rgb[i] = rgba[j];
    rgb[i + 1] = rgba[j + 1];
    rgb[i + 2] = rgba[j + 2];
  }
  return rgb;
}
