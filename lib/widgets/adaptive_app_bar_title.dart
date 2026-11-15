import 'package:material_ui/material_ui.dart';

/// An app bar title as wide as its text, so the bar can centre it on the
/// screen; a title too long for the bar shrinks to fit.
class AdaptiveAppBarTitle extends StatelessWidget {
  final String text;

  const AdaptiveAppBarTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1));
}
