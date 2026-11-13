import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

class LosIcon extends StatelessWidget {
  final double size;
  final Color? color;

  const LosIcon({super.key, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconTheme = IconTheme.of(context);
    final iconColor =
        color ??
        iconTheme.color ??
        theme.iconTheme.color ??
        theme.colorScheme.onSurface;

    return Icon(Symbols.elevation, size: size, color: iconColor);
  }
}
