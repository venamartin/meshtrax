import 'package:material_ui/material_ui.dart';

class SignalUi {
  final IconData icon;
  final Color color;

  const SignalUi({required this.icon, required this.color});
}

SignalUi signalUiForStrengthTier(int tier) {
  switch (tier) {
    case 0:
      return const SignalUi(
        icon: Icons.signal_cellular_4_bar,
        color: Colors.green,
      );
    case 1:
      return const SignalUi(
        icon: Icons.signal_cellular_alt,
        color: Colors.lightGreen,
      );
    case 2:
      return const SignalUi(
        icon: Icons.signal_cellular_alt_2_bar,
        color: Colors.amber,
      );
    case 3:
      return const SignalUi(
        icon: Icons.signal_cellular_alt_1_bar,
        color: Colors.orange,
      );
    default:
      return const SignalUi(
        icon: Icons.signal_cellular_alt_1_bar,
        color: Colors.red,
      );
  }
}
