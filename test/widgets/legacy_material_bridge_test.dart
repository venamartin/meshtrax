import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:meshtrax/widgets/legacy_material_bridge.dart';

void main() {
  // With the package's bridge alone each of these drew in the plain icon
  // colour: black on the filled button in light mode.
  for (final brightness in Brightness.values) {
    testWidgets('icon buttons keep their colours, ${brightness.name}',
        (tester) async {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: brightness,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme),
          builder: (_, child) => LegacyMaterialBridge(child: child!),
          home: Scaffold(
            body: Row(
              children: [
                IconButton(icon: const Icon(Icons.close), onPressed: () {}),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: () {},
                ),
                IconButton.filledTonal(
                  icon: const Icon(Icons.undo),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );
      Color? drawn(IconData icon) =>
          IconTheme.of(tester.element(find.byIcon(icon))).color;
      expect(drawn(Icons.close), scheme.onSurfaceVariant);
      expect(drawn(Icons.send), scheme.onPrimary);
      expect(drawn(Icons.undo), scheme.onSecondaryContainer);
    });
  }
}
