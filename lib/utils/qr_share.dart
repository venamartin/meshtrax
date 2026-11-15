import 'dart:io';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import 'platform_info.dart';

/// A QR code of [data] as a PNG: black on white with a quiet margin, so it
/// scans from a chat app's dark background too.
Future<Uint8List> qrPng(String data, {double size = 720}) async {
  const margin = 48.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final side = size + margin * 2;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, side, side),
    Paint()..color = Colors.white,
  );
  canvas.translate(margin, margin);
  QrPainter(
    data: data,
    version: QrVersions.auto,
    gapless: true,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Colors.black,
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Colors.black,
    ),
  ).paint(canvas, Size(size, size));
  final image = await recorder.endRecording().toImage(
    side.round(),
    side.round(),
  );
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return bytes!.buffer.asUint8List();
}

String _fileName(String name) {
  final safe = name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '_');
  return 'meshtrax-${safe.isEmpty ? 'qr' : safe}';
}

/// Sends the QR code's picture and its link to another app. Windows and
/// Linux have no share sheet that takes a file, so there the picture is
/// saved instead. Returns false when nothing was sent or saved.
Future<bool> shareQrCode({
  required String data,
  required String name,
  Rect? sharePositionOrigin,
}) async {
  final png = await qrPng(data);
  if (PlatformInfo.isWindows || PlatformInfo.isLinux) {
    final saved = await FileSaver.instance.saveAs(
      name: _fileName(name),
      bytes: png,
      fileExtension: 'png',
      mimeType: MimeType.png,
    );
    return saved != null && saved.isNotEmpty;
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/${_fileName(name)}.png');
  await file.writeAsBytes(png);
  try {
    final result = await SharePlus.instance.share(
      ShareParams(
        text: data,
        subject: name,
        files: [XFile(file.path, mimeType: 'image/png')],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
    return result.status == ShareResultStatus.success;
  } finally {
    if (file.existsSync()) file.deleteSync();
  }
}
