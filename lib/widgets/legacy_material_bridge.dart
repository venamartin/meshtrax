import 'package:material_ui/material_ui.dart';

/// Gives packages still on Flutter's own Material library (today:
/// emoji_picker_flutter) the app's theme and translations. Goes in
/// [MaterialApp.builder]; take it out when they have moved to material_ui.
class LegacyMaterialBridge extends StatelessWidget {
  const LegacyMaterialBridge({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // The bridge's theme sets the icon colour as well. It is the same colour,
    // but an IconButton only knows its own library's default and would take
    // this one as the app's choice, losing its Material 3 colour. So the app's
    // own icon theme goes back under the bridge.
    // ignore: deprecated_member_use
    return MaterialUiCompatibilityBridge(
      child: IconTheme(data: Theme.of(context).iconTheme, child: child),
    );
  }
}
