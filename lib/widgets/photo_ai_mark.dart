import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';

/// "AI reconstructed", small and faint in a corner of a rebuilt photo: there,
/// but not in the way. White with a soft shadow, as theme colours don't hold
/// over a picture.
class PhotoAiMark extends StatelessWidget {
  const PhotoAiMark({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Text(
      context.l10n.photo_label,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white.withValues(alpha: 0.7),
        shadows: const [Shadow(blurRadius: 3, color: Colors.black54)],
      ),
    ),
  );
}
