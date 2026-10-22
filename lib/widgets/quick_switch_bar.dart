import 'package:flutter/material.dart';
import '../l10n/l10n.dart';

/// Chats | Map at the bottom of the screen: a standard bar, edge to edge.
/// It keeps clear of the system's gesture area itself.
class QuickSwitchBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const QuickSwitchBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelMedium ?? const TextStyle();

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: colorScheme.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return labelStyle.copyWith(
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      child: NavigationBar(
        height: 60,
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            label: context.l10n.nav_chats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            label: context.l10n.nav_map,
          ),
        ],
      ),
    );
  }
}
