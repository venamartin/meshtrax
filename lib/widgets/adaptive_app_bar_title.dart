import 'package:material_ui/material_ui.dart';

class AdaptiveAppBarTitle extends StatelessWidget {
  final String text;

  const AdaptiveAppBarTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SizedBox(
        width: constraints.maxWidth,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1)),
      ),
    );
  }
}
