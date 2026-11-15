import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:meshtrax/widgets/adaptive_app_bar_title.dart';

void main() {
  Future<void> show(WidgetTester tester, AppBar bar) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(appBar: bar)));
  }

  // It took the whole slot after the back button and centred its text in
  // that, which put the text right of the screen's middle.
  testWidgets('sits in the middle of the screen beside a back button', (
    tester,
  ) async {
    await show(
      tester,
      AppBar(
        leading: const BackButton(),
        centerTitle: true,
        title: const AdaptiveAppBarTitle('Path Map'),
      ),
    );
    expect(tester.getCenter(find.text('Path Map')).dx, 200);
  });

  testWidgets('a long title shrinks to fit between the buttons', (
    tester,
  ) async {
    await show(
      tester,
      AppBar(
        leading: const BackButton(),
        centerTitle: true,
        title: AdaptiveAppBarTitle('A title much too long for the bar ' * 3),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.share))],
      ),
    );
    expect(tester.takeException(), isNull);
    final title = tester.getRect(find.byType(AdaptiveAppBarTitle));
    expect(title.left, greaterThanOrEqualTo(56));
    expect(title.right, lessThanOrEqualTo(400 - 48));
  });
}
