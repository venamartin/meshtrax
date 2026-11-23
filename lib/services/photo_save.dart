import 'dart:io' show Platform;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_saver/file_saver.dart';
import 'package:flutter/services.dart' show MethodChannel, rootBundle;
import 'package:material_ui/material_ui.dart';

import '../widgets/photo_footprint_mark.dart';

/// [picture] as a PNG with [mark] ("AI reconstructed") small and faint in
/// its bottom-left corner and the MeshTrax footprint in its bottom-right, as
/// the viewer shows them, so a saved copy stays labelled outside MeshTrax.
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
  final foot = await _footprint();
  final f = photoFootprintFor(width);
  final w = f.height * foot.width / foot.height;
  final src = Rect.fromLTWH(
    0,
    0,
    foot.width.toDouble(),
    foot.height.toDouble(),
  );
  final dst = Rect.fromLTWH(
    width - f.right - w,
    height - f.bottom - f.height,
    w,
    f.height,
  );
  canvas
    ..drawImageRect(
      foot,
      src,
      dst,
      Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.black.withValues(alpha: photoFootprintShadow),
          BlendMode.srcIn,
        )
        ..imageFilter = ui.ImageFilter.blur(sigmaX: f.blur, sigmaY: f.blur),
    )
    ..drawImageRect(
      foot,
      src,
      dst,
      Paint()
        ..colorFilter = ColorFilter.mode(
          Colors.white.withValues(alpha: photoFootprintOpacity),
          BlendMode.srcIn,
        ),
    );
  final drawn = await recorder.endRecording().toImage(
    picture.width,
    picture.height,
  );
  final png = await drawn.toByteData(format: ui.ImageByteFormat.png);
  drawn.dispose();
  return png!.buffer.asUint8List();
}

ui.Image? _footprintImage;

/// The footprint asset as a picture, loaded once.
Future<ui.Image> _footprint() async {
  final loaded = _footprintImage;
  if (loaded != null) return loaded;
  final data = await rootBundle.load(PhotoFootprintMark.asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final image = (await codec.getNextFrame()).image;
  codec.dispose();
  return _footprintImage = image;
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
