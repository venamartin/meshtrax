import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

/// The MeshTrax footprint, faint in the lower-right corner of a rebuilt
/// photo, opposite "AI reconstructed": white with a light shadow, small at a
/// glance and plain when zoomed. Fills its parent, which is the square photo.
/// Drawn over the rebuilt picture, never sent.
class PhotoFootprintMark extends StatelessWidget {
  const PhotoFootprintMark({super.key});

  static const asset = 'assets/icons/meshtraxnotification.png';

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: LayoutBuilder(
      builder: (context, box) {
        final f = photoFootprintFor(box.maxWidth);
        Widget print(Color color) => Image.asset(
          asset,
          height: f.height,
          color: color,
          colorBlendMode: BlendMode.srcIn,
        );
        return Stack(
          children: [
            Positioned(
              right: f.right,
              bottom: f.bottom,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: f.blur, sigmaY: f.blur),
                child: print(
                  Colors.black.withValues(alpha: photoFootprintShadow),
                ),
              ),
            ),
            Positioned(
              right: f.right,
              bottom: f.bottom,
              child: print(
                Colors.white.withValues(alpha: photoFootprintOpacity),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// The footprint's white and its shadow's black, as opacities.
const double photoFootprintOpacity = 0.7;
const double photoFootprintShadow = 0.25;

/// The footprint's height, margins and shadow blur on a photo [width] wide,
/// the same on screen and in saved copies: 7% of the width tall, in the
/// margins "AI reconstructed" keeps in the opposite corner.
({double height, double right, double bottom, double blur}) photoFootprintFor(
  double width,
) {
  final mark = width * 0.024;
  final height = width * 0.07;
  return (
    height: height,
    right: mark * 0.8,
    bottom: mark * 0.6,
    blur: height / 14,
  );
}
