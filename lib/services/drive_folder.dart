import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/services.dart';
import 'package:traxmap/traxmap.dart';

/// The native side of "Use a drive": `MeshTraxDrive.kt` on Android, the
/// `DriveFolder` class in `AppDelegate.swift` on iOS.
const _channel = MethodChannel('meshtrax/drive');

/// Asks for a folder of maps (traxmapmaker's stick: its `MeshTrax-maps`, or
/// the drive itself) and opens it; null when none is chosen. On phones the
/// system's folder picker, which reaches USB drives and SD cards; on
/// desktops the usual folder dialog.
Future<MapDrive?> pickMapDrive() async {
  if (Platform.isAndroid) {
    final picked = await _channel.invokeMapMethod<String, Object?>(
      'pickFolder',
    );
    if (picked == null) return null;
    final uri = picked['uri'] as String;
    return SafMapDrive(uri, name: picked['name'] as String? ?? uri);
  }
  if (Platform.isIOS) {
    final picked = await _channel.invokeMapMethod<String, Object?>(
      'pickFolder',
    );
    if (picked == null) return null;
    final path = picked['path'] as String;
    return IoMapDrive(
      Directory(path),
      name: picked['name'] as String?,
      onClose: () => _channel.invokeMethod<void>('stopAccess', path),
    );
  }
  final path = await getDirectoryPath();
  return path == null ? null : IoMapDrive(Directory(path));
}

/// Keeps a phone's screen on while maps copy from a drive: an iPhone stops
/// the app when it locks. Desktops ignore it.
Future<void> keepScreenOn(bool on) async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  await _channel.invokeMethod<void>('keepScreenOn', on);
}

/// A [MapDrive] on Android, read through the Storage Access Framework: the
/// folder the system picker granted ([treeUri]). Apps can't open USB drives
/// and SD cards by path, so `MeshTraxDrive.kt` lists and copies the files.
class SafMapDrive implements MapDrive {
  final String treeUri;

  @override
  final String name;

  /// Each file's document URI by path, from [list].
  final Map<String, String> _uris;

  SafMapDrive(this.treeUri, {required this.name, Map<String, String>? uris})
    : _uris = uris ?? {};

  static var _copies = 0;

  @override
  Future<Map<String, int>> list() async {
    final files =
        await _channel.invokeListMethod<Map<Object?, Object?>>(
          'list',
          treeUri,
        ) ??
        const [];
    _uris.clear();
    final sizes = <String, int>{};
    for (final file in files) {
      final path = file['path'] as String;
      sizes[path] = (file['size'] as num).toInt();
      _uris[path] = file['uri'] as String;
    }
    return sizes;
  }

  @override
  Future<String> readText(String path) async =>
      (await _channel.invokeMethod<String>('readText', _uriOf(path)))!;

  @override
  Future<void> copy(
    String path,
    File to, {
    int from = 0,
    Future<void>? stop,
  }) async {
    final id = '${_copies++}';
    unawaited(stop?.then((_) => _channel.invokeMethod<void>('cancelCopy', id)));
    final done = await _channel.invokeMethod<bool>('copy', {
      'id': id,
      'uri': _uriOf(path),
      'to': to.path,
      'from': from,
    });
    if (done != true) throw const DriveCopyStopped();
  }

  @override
  Future<bool> isReadable() async =>
      await _channel.invokeMethod<bool>('isReadable', treeUri) ?? false;

  @override
  MapDrive inFolder(String name) => SafMapDrive(
    treeUri,
    name: this.name,
    uris: {
      for (final MapEntry(:key, :value) in _uris.entries)
        if (key.startsWith('$name/')) key.substring(name.length + 1): value,
    },
  );

  @override
  Future<void> close() async {}

  String _uriOf(String path) =>
      _uris[path] ?? (throw FileSystemException('Not on the drive', path));
}
