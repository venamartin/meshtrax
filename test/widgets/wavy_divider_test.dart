import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/widgets/wavy_divider.dart';

void main() {
  testWidgets('a label between two waves of equal width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: WavyDivider(label: 'NEW MESSAGES', color: Colors.red),
        ),
      ),
    );
    expect(find.text('NEW MESSAGES'), findsOneWidget);
    final waves = find.descendant(
      of: find.byType(WavyDivider),
      matching: find.byType(CustomPaint),
    );
    expect(waves, findsNWidgets(2));
    final left = tester.getSize(waves.first);
    final right = tester.getSize(waves.last);
    expect(left.width, greaterThan(50));
    expect(left.width, right.width);
    // The label sits in the middle of the row.
    final label = tester.getCenter(find.text('NEW MESSAGES'));
    expect(label.dx, closeTo(tester.getCenter(find.byType(WavyDivider)).dx, 1));
  });
}
