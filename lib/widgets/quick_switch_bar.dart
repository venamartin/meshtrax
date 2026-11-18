import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import 'active_sos_strip.dart';

/// Chats | Map at the bottom of the screen: a standard bar, edge to edge.
/// It keeps clear of the system's gesture area itself. Chats carries the
/// count of unread messages, so new ones show from the map too. Above it,
/// the user's own SOS while it lasts.
class QuickSwitchBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  const QuickSwitchBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  /// Unread messages in the chats that are not muted. A muted chat, such as
  /// Public by default, would keep the count up all the time.
  static int _unmutedUnread(
    MeshCoreConnector connector,
    AppSettingsService settings,
  ) {
    var total = 0;
    for (final contact in connector.chatContacts) {
      if (settings.isContactMuted(contact.publicKeyHex)) continue;
      total += connector.getUnreadCountForContact(contact);
    }
    for (final channel in connector.channels) {
      // Older versions stored a mute under the channel's name.
      if (settings.isChannelMuted(channel.idKey) ||
          settings.isChannelMuted(channel.name) ||
          settings.isChannelMuted(channel.displayName)) {
        continue;
      }
      total += connector.getUnreadCountForChannel(channel);
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelMedium ?? const TextStyle();
    final settings = context.watch<AppSettingsService>();
    final unread = context.select<MeshCoreConnector, int>(
      (connector) => _unmutedUnread(connector, settings),
    );

    final bar = NavigationBarTheme(
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
            // The colors of the counts on the Chats list's rows.
            icon: Badge.count(
              count: unread,
              maxCount: 99,
              isLabelVisible: unread > 0,
              backgroundColor: Colors.redAccent,
              textColor: Colors.white,
              child: const Icon(Icons.chat_bubble_outline),
            ),
            label: context.l10n.nav_chats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.map_outlined),
            label: context.l10n.nav_map,
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [const ActiveSosStrip(), bar],
    );
  }
}
