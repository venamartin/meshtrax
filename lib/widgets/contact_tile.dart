import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../utils/platform_info.dart';
import 'unread_badge.dart';

String? _firstEmoji(String text) {
  for (final char in text.runes) {
    if (char >= 0x1F600 && char <= 0x1F64F || // Emoticons
        char >= 0x1F300 && char <= 0x1F5FF || // Misc Symbols and Pictographs
        char >= 0x1F680 && char <= 0x1F6FF || // Transport and Map
        char >= 0x2600 && char <= 0x26FF || // Misc symbols
        char >= 0x2700 && char <= 0x27BF || // Dingbats
        char >= 0xFE00 && char <= 0xFE0F || // Variation Selectors
        char >= 0x1F900 && char <= 0x1F9FF || // Supplemental Symbols and Pictographs
        char >= 0x1FA70 && char <= 0x1FAFF) { // Symbols and Pictographs Extended-A
      return String.fromCharCode(char);
    }
  }
  return null;
}

class ContactTile extends StatelessWidget {
  final Contact contact;
  final DateTime lastSeen;
  final int unreadCount;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isDiscovered;

  const ContactTile({
    super.key,
    required this.contact,
    required this.lastSeen,
    required this.unreadCount,
    required this.isFavorite,
    required this.onTap,
    required this.onLongPress,
    this.isDiscovered = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = _getTypeColor(contact.type);
    final bgColor = isDiscovered ? Colors.transparent : baseColor.withValues(alpha: 0.2);

    return GestureDetector(
      onSecondaryTapUp: PlatformInfo.isDesktop ? (_) => onLongPress() : null,
      onLongPress: onLongPress,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: isDiscovered ? 0 : 1,
        shape: isDiscovered 
            ? RoundedRectangleBorder(
                side: BorderSide(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: bgColor,
            child: _buildContactAvatar(contact, baseColor),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  contact.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              if (contact.clockCorrected) ...[
                Tooltip(
                  message: "Sender's clock is wrong — showing time received",
                  triggerMode: TooltipTriggerMode.tap,
                  child: Icon(
                    Icons.history_toggle_off,
                    size: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(width: 3),
              ],
              Text(
                _formatLastSeen(context, lastSeen),
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
          subtitle: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      contact.pathLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      contact.shortPubKeyHex,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (isFavorite || contact.hasLocation || unreadCount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFavorite)
                      Icon(Icons.star, size: 16, color: Colors.amber[700]),
                    if (isFavorite && contact.hasLocation)
                      const SizedBox(width: 2),
                    if (contact.hasLocation)
                      Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
                    if (unreadCount > 0) ...[
                      const SizedBox(width: 8),
                      UnreadBadge(count: unreadCount),
                    ],
                  ],
                ),
            ],
          ),
          onTap: onTap,
        ),
      ),
    );
  }

  Widget _buildContactAvatar(Contact contact, Color iconColor) {
    final emoji = _firstEmoji(contact.name);
    if (emoji != null) {
      return Text(emoji, style: const TextStyle(fontSize: 18));
    }
    return Icon(_getTypeIcon(contact.type), color: iconColor, size: 20);
  }

  IconData _getTypeIcon(int type) {
    switch (type) {
      case advTypeChat:
        return Icons.person;
      case advTypeRepeater:
        return Icons.cell_tower;
      case advTypeRoom:
        return Icons.group;
      case advTypeSensor:
        return Icons.sensors;
      default:
        return Icons.device_unknown;
    }
  }

  Color _getTypeColor(int type) {
    switch (type) {
      case advTypeChat:
        return Colors.blue;
      case advTypeRepeater:
        return Colors.orange;
      case advTypeRoom:
        return Colors.purple;
      case advTypeSensor:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatLastSeen(BuildContext context, DateTime lastSeen) {
    final now = DateTime.now();
    final diff = now.difference(lastSeen);

    if (diff.isNegative || diff.inMinutes < 5) {
      return context.l10n.contacts_lastSeenNow;
    }
    if (diff.inMinutes < 60) {
      return context.l10n.contacts_lastSeenMinsAgo(diff.inMinutes);
    }
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return hours == 1
          ? context.l10n.contacts_lastSeenHourAgo
          : context.l10n.contacts_lastSeenHoursAgo(hours);
    }
    final days = diff.inDays;
    return days == 1
        ? context.l10n.contacts_lastSeenDayAgo
        : context.l10n.contacts_lastSeenDaysAgo(days);
  }
}
