import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart' show MethodChannel;
import 'package:material_ui/material_ui.dart';

/// [picture] as a PNG with [mark] ("AI reconstructed") small and faint in
/// its bottom-left corner, as the viewer shows it, so a saved copy stays
/// labelled outside MeshTrax.
Future<Uint8List> markedPng(ui.Image picture, String mark) async {
  final width = picture.width.toDouble(), height = picture.height.toDouble();
  final size = width * 0.024;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder)..drawImage(picture, Offset.zero, Paint());
  final text = TextPainter(
    text: TextSpan(
      text: mark,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.7),
        fontSize: size,
        shadows: [Shadow(blurRadius: size / 4, color: Colors.black54)],
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  text.paint(canvas, Offset(size * 0.8, height - size * 0.6 - text.height));
  text.dispose();
  final drawn = await recorder.endRecording().toImage(
    picture.width,
    picture.height,
  );
  final png = await drawn.toByteData(format: ui.ImageByteFormat.png);
  drawn.dispose();
  return png!.buffer.asUint8List();
}

/// A PNG's picture, for [markedPng].
Future<ui.Image> decodePng(Uint8List png) async {
  final codec = await ui.instantiateImageCodec(png);
  return (await codec.getNextFrame()).image;
}

/// Saves [png] to the phone's photos, or on a Mac where the user chooses.
/// False when it wasn't saved: no permission, cancelled, or a failure.
Future<bool> savePhotoPicture(Uint8List png) async {
  if (Platform.isMacOS) {
    final path = await FileSaver.instance.saveAs(
      name: 'MeshTrax photo',
      bytes: png,
      fileExtension: 'png',
      mimeType: MimeType.png,
    );
    return path != null && path.isNotEmpty;
  }
  try {
    return await const MethodChannel('meshtrax/storage')
            .invokeMethod<bool>('saveToPhotos', png) ??
        false;
  } on Object catch (_) {
    return false;
  }
}
