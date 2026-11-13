import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/screens/companion_radio_stats_screen.dart';

void pushCompanionRadioStatsScreen(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (context) => const CompanionRadioStatsScreen(),
    ),
  );
}
