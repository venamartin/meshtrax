import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../utils/route_transitions.dart';
import '../widgets/app_bar.dart';
import '../widgets/quick_switch_bar.dart';
import '../widgets/unread_badge.dart';
import 'channel_chat_screen.dart';
import 'channels_screen.dart';
import 'chat_screen.dart';
import 'contacts_screen.dart';
import 'map_screen.dart';

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

class _ChatsScreenState extends State<ChatsScreen> {
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
      final config = Localizations.localeOf(context).languageCode;
      // Poor man's week day string, rely on app locale if needed or package `intl`
      final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekDays[timestamp.weekday - 1];
    } else {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, child) {
        final List<_ChatListItem> chatItems = [];

        // Add Active Contacts
        for (final contact in connector.contacts) {
          final messages = connector.getMessages(contact);
          if (messages.isNotEmpty) {
            final lastMessage = messages.last;
            chatItems.add(
              _ChatListItem(
                id: 'contact_${contact.publicKeyHex}',
                title: contact.name.isEmpty ? 'Unknown' : contact.name,
                subtitle: lastMessage.text,
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
            chatItems.add(
              _ChatListItem(
                id: 'channel_${channel.index}',
                title: channel.name.isEmpty ? 'Channel ${channel.index}' : channel.name,
                subtitle: lastMessage.text,
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
            automaticallyImplyLeading: !widget.hideBackButton,
            title: AppBarTitle(context.l10n.chats_title),
            centerTitle: true,
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

                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      confirmDismiss: (direction) async {
                        return await showDialog<bool>(
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
                            ) ??
                            false;
                      },
                      onDismissed: (direction) {
                        if (item.contact != null) {
                          connector.clearMessagesForContact(item.contact!);
                        } else if (item.channel != null) {
                          connector.clearMessagesForChannel(item.channel!.index);
                        }
                      },
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
                              child: Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
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
