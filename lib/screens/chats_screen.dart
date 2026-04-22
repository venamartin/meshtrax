import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../utils/dialog_utils.dart';
import '../utils/disconnect_navigation_mixin.dart';
import '../utils/route_transitions.dart';
import '../widgets/app_bar.dart';
import '../widgets/quick_switch_bar.dart';
import '../widgets/unread_badge.dart';
import 'channel_chat_screen.dart';
import 'channels_screen.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class _ChatListItem {
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final int unreadCount;
  final Contact? contact;
  final Channel? channel;
  
  _ChatListItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.unreadCount,
    this.contact,
    this.channel,
  });
}

class ChatsScreen extends StatefulWidget {
  final bool hideBackButton;

  const ChatsScreen({super.key, this.hideBackButton = false});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> with DisconnectNavigationMixin {
  Future<void> _disconnect(BuildContext context) async {
    final connector = context.read<MeshCoreConnector>();
    await showDisconnectDialog(context, connector);
  }

  void _handleQuickSwitch(int index, BuildContext context) {
    if (index == 0) return;
    switch (index) {
      case 1:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const ContactsScreen(hideBackButton: true)),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const ChannelsScreen(hideBackButton: true)),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const MapScreen(hideBackButton: true)),
        );
        break;
    }
  }

  String _formatTimestamp(BuildContext context, DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0 && now.day == timestamp.day) {
      return TimeOfDay.fromDateTime(timestamp).format(context);
    } else if (difference.inDays < 7) {
      // Poor man's week day string, rely on app locale if needed or package `intl`
      final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekDays[timestamp.weekday - 1];
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  Widget _buildSubtitleText(BuildContext context, _ChatListItem item) {
    final subtitle = item.subtitle;
    final colonIndex = subtitle.indexOf(': ');

    if (colonIndex > 0) {
      final senderPart = subtitle.substring(0, colonIndex + 2); // includes ': '
      final messagePart = subtitle.substring(colonIndex + 2);

      return RichText(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          children: [
            TextSpan(
              text: senderPart,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            TextSpan(
              text: messagePart,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      );
    }

    return Text(
      subtitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  void _showChatActions(BuildContext context, _ChatListItem item, MeshCoreConnector connector) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(context.l10n.contact_clearChat),
              onTap: () async {
                Navigator.pop(sheetContext);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(context.l10n.contact_clearChat),
                    content: const Text('Remove this chat from your inbox? This will delete the local message history, but new messages will still appear here.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(context.l10n.common_cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(context.l10n.common_clear, style: const TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ) ?? false;
                
                if (confirmed) {
                  if (item.contact != null) {
                    connector.clearMessagesForContact(item.contact!);
                  } else if (item.channel != null) {
                    connector.clearMessagesForChannel(item.channel!.index);
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(context.l10n.common_cancel),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, child) {
        final List<_ChatListItem> chatItems = [];

        // Add Active Contacts (exclude repeaters)
        for (final contact in connector.contacts) {
          if (contact.type == advTypeRepeater) continue;
          final messages = connector.getMessages(contact);
          if (messages.isNotEmpty) {
            final lastMessage = messages.last;
            final contactName = contact.name.isEmpty ? 'Unknown' : contact.name;
            final subtitle = lastMessage.isOutgoing ? 'You: ${lastMessage.text}' : lastMessage.text;
            chatItems.add(
              _ChatListItem(
                id: 'contact_${contact.publicKeyHex}',
                title: contactName,
                subtitle: subtitle,
                timestamp: lastMessage.timestamp,
                unreadCount: connector.getUnreadCountForContact(contact),
                contact: contact,
              ),
            );
          }
        }

        // Add Active Channels
        for (final channel in connector.channels) {
          final messages = connector.getChannelMessages(channel);
          if (messages.isNotEmpty) {
            final lastMessage = messages.last;
            final subtitle = lastMessage.isOutgoing ? 'You: ${lastMessage.text}' : '${lastMessage.senderName}: ${lastMessage.text}';
            chatItems.add(
              _ChatListItem(
                id: 'channel_${channel.index}',
                title: channel.name.isEmpty ? 'Channel ${channel.index}' : channel.name,
                subtitle: subtitle,
                timestamp: lastMessage.timestamp,
                unreadCount: connector.getUnreadCountForChannel(channel),
                channel: channel,
              ),
            );
          }
        }

        // Sort by most recent
        chatItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: AppBarTitle(context.l10n.chats_title),
            centerTitle: true,
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.logout, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(context.l10n.common_disconnect),
                      ],
                    ),
                    onTap: () => _disconnect(context),
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.settings),
                        const SizedBox(width: 8),
                        Text(context.l10n.settings_title),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    ),
                  ),
                ],
                icon: const Icon(Icons.more_vert),
              ),
            ],
          ),
          body: chatItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No active chats yet.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: chatItems.length,
                  itemBuilder: (context, index) {
                    final item = chatItems[index];
                    final isChannel = item.channel != null;
                    final iconColor = isChannel ? Colors.blue : Colors.green;
                    final bgColor = isChannel
                        ? Colors.blue.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2);
                    IconData iconData;
                    if (isChannel) {
                      if (item.channel!.isPublicChannel) {
                        iconData = Icons.public;
                      } else if (item.channel!.name.startsWith('#')) {
                        iconData = Icons.tag;
                      } else {
                        iconData = Icons.lock;
                      }
                    } else {
                      iconData = Icons.person;
                    }

                    return GestureDetector(
                      onLongPress: () => _showChatActions(context, item, connector),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: bgColor,
                            child: Icon(iconData, color: iconColor),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _formatTimestamp(context, item.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                  fontWeight: item.unreadCount > 0
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            children: [
                              Expanded(
                                child: _buildSubtitleText(context, item),
                              ),
                              if (item.unreadCount > 0) ...[
                                const SizedBox(width: 8),
                                UnreadBadge(count: item.unreadCount),
                              ],
                            ],
                          ),
                          onTap: () async {
                            if (item.contact != null) {
                              connector.markContactRead(item.contact!.publicKeyHex);
                              await Future.delayed(const Duration(milliseconds: 50));
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(contact: item.contact!),
                                  ),
                                );
                              }
                            } else if (item.channel != null) {
                              connector.markChannelRead(item.channel!.index);
                              await Future.delayed(const Duration(milliseconds: 50));
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChannelChatScreen(channel: item.channel!),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: QuickSwitchBar(
              selectedIndex: 0,
              onDestinationSelected: (index) => _handleQuickSwitch(index, context),
            ),
          ),
        );
      },
    );
  }
}
