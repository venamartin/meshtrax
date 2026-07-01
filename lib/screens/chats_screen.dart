import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import '../utils/dialog_utils.dart';
import '../utils/disconnect_navigation_mixin.dart';
import '../utils/emoji_utils.dart';
import '../utils/route_transitions.dart';
import '../utils/telemetry_dialog.dart';
import '../helpers/contact_import_helper.dart';
import '../helpers/meshcore_qr.dart';
import '../helpers/snack_bar_builder.dart';
import '../widgets/app_bar.dart';
import '../widgets/quick_switch_bar.dart';
import '../widgets/unread_badge.dart';
import 'package:flutter/services.dart';
import 'channel_chat_screen.dart';
import 'channel_share_screen.dart';
import 'chat_screen.dart';
import 'contact_share_screen.dart';
import 'map_screen.dart';
import 'new_chat_screen.dart';
import 'repeaters_screen.dart';
import 'scanner_screen.dart';
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
    final disconnected = await showDisconnectDialog(context, connector);
    if (disconnected && mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const ScannerScreen()),
        (route) => false,
      );
    }
  }

  void _handleQuickSwitch(int index, BuildContext context) {
    if (index == 0) return;
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        buildQuickSwitchRoute(const MapScreen(hideBackButton: true)),
      );
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
    final settingsService = context.read<AppSettingsService>();

    if (item.channel != null) {
      final channel = item.channel!;
      final isMuted = settingsService.isChannelMuted(channel.name);
      
      showModalBottomSheet(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.qr_code_2),
                title: Text(context.l10n.channels_shareChannel),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChannelShareScreen(channel: channel),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  isMuted
                      ? Icons.notifications_outlined
                      : Icons.notifications_off_outlined,
                ),
                title: Text(
                  isMuted
                      ? context.l10n.channels_unmuteChannel
                      : context.l10n.channels_muteChannel,
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (isMuted) {
                    await settingsService.unmuteChannel(channel.name);
                  } else {
                    await settingsService.muteChannel(channel.name);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services, color: Colors.orange),
                title: Text(
                  context.l10n.contact_clearChat,
                  style: const TextStyle(color: Colors.orange),
                ),
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
                    connector.clearMessagesForChannel(channel.index);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(
                  context.l10n.channels_deleteChannel,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(context.l10n.channels_deleteChannel),
                      content: Text(
                        context.l10n.channels_deleteChannelConfirm(channel.name),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(context.l10n.common_cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(
                            context.l10n.common_delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ) ?? false;
                  
                  if (confirmed) {
                    try {
                      await connector.deleteChannel(channel.index);
                      connector.clearMessagesForChannel(channel.index);
                      if (context.mounted) {
                        showDismissibleSnackBar(
                          context,
                          content: Text(
                            context.l10n.channels_channelDeleted(channel.name),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showDismissibleSnackBar(
                          context,
                          content: Text(
                            context.l10n.channels_channelDeleteFailed(channel.name),
                          ),
                        );
                      }
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
    } else if (item.contact != null) {
      final contact = item.contact!;
      
      showModalBottomSheet(
        context: context,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              ListTile(
                leading: Icon(
                  contact.isFavorite ? Icons.star : Icons.star_border,
                  color: Colors.amber[700],
                ),
                title: Text(
                  contact.isFavorite
                      ? context.l10n.listFilter_removeFromFavorites
                      : context.l10n.listFilter_addToFavorites,
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await connector.setContactFlags(
                    contact,
                    isFavorite: !contact.isFavorite,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.security),
                title: Text(context.l10n.contact_telemetry),
                onTap: () {
                  Navigator.pop(sheetContext);
                  showTelemetryPermissionsDialog(context, contact);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(context.l10n.contacts_ShareContact),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final data = MeshCoreQr.encodeContact(
                    contact.name,
                    pubKeyToHex(contact.publicKey),
                    contact.type,
                  );
                  Clipboard.setData(ClipboardData(text: data));
                  showDismissibleSnackBar(
                    context,
                    content: Text(context.l10n.common_copiedToClipboard),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.connect_without_contact),
                title: Text(context.l10n.contacts_ShareContactZeroHop),
                onTap: () {
                  Navigator.pop(sheetContext);
                  connector.shareContactZeroHop(contact.publicKey);
                  showDismissibleSnackBar(
                    context,
                    content: Text(context.l10n.settings_advertisementSent),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cleaning_services, color: Colors.orange),
                title: Text(
                  context.l10n.contact_clearChat,
                  style: const TextStyle(color: Colors.orange),
                ),
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
                          child: Text(context.l10n.common_clear, style: const TextStyle(color: Colors.orange)),
                        ),
                      ],
                    ),
                  ) ?? false;
                  
                  if (confirmed) {
                    connector.clearMessagesForContact(contact);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  context.l10n.contacts_deleteContact,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogContext) => AlertDialog(
                      title: Text(context.l10n.contacts_deleteContact),
                      content: Text(dialogContext.l10n.contacts_deleteContactConfirm(contact.name)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, false),
                          child: Text(context.l10n.common_cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext, true),
                          child: Text(
                            dialogContext.l10n.common_delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ) ?? false;
                  
                  if (confirmed) {
                    try {
                      await connector.removeContact(contact);
                      if (context.mounted) {
                        showDismissibleSnackBar(
                          context,
                          content: Text(context.l10n.contacts_contactDeleted(contact.name)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showDismissibleSnackBar(
                          context,
                          content: Text(context.l10n.contacts_contactDeleteFailed(contact.name)),
                        );
                      }
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
          } else {
            chatItems.add(
              _ChatListItem(
                id: 'channel_${channel.index}',
                title: channel.name.isEmpty ? 'Channel ${channel.index}' : channel.name,
                subtitle: 'Tap to chat',
                timestamp: DateTime.fromMillisecondsSinceEpoch(0),
                unreadCount: 0,
                channel: channel,
              ),
            );
          }
        }

        // Sort by most recent
        chatItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        Widget? syncBanner;
        final syncStatus = connector.currentSyncStatus;
        if (syncStatus != null) {
          String statusText = '';
          switch (syncStatus) {
            case SyncStatus.deviceInfo:
              statusText = context.l10n.common_syncing_device_info;
              break;
            case SyncStatus.contacts:
              statusText = context.l10n.common_syncing_contacts;
              break;
            case SyncStatus.channels:
              statusText = context.l10n.common_syncing_channels;
              break;
            case SyncStatus.messages:
              statusText = context.l10n.common_syncing_messages;
              break;
          }

          syncBanner = Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.primaryContainer,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return PopScope(
          canPop: false,
          child: Scaffold(
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
                        const Icon(Icons.connect_without_contact),
                        const SizedBox(width: 8),
                        Text(context.l10n.contacts_zeroHopAdvert),
                      ],
                    ),
                    onTap: () => {
                      connector.sendSelfAdvert(flood: false),
                      showDismissibleSnackBar(
                        context,
                        content: Text(context.l10n.settings_advertisementSent),
                      ),
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.cell_tower),
                        const SizedBox(width: 8),
                        Text(context.l10n.contacts_floodAdvert),
                      ],
                    ),
                    onTap: () => {
                      connector.sendSelfAdvert(flood: true),
                      showDismissibleSnackBar(
                        context,
                        content: Text(context.l10n.settings_advertisementSent),
                      ),
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_2),
                        const SizedBox(width: 8),
                        Text(context.l10n.contacts_shareMyQrCode),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ContactShareScreen(
                            name: (connector.selfName?.isEmpty ?? true) ? 'Unknown' : connector.selfName!,
                            pubKeyHex: connector.selfPublicKeyHex,
                            type: advTypeChat,
                          ),
                        ),
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.copy),
                        const SizedBox(width: 8),
                        Text(context.l10n.contacts_copyContactToClipboard),
                      ],
                    ),
                    onTap: () {
                      final data = MeshCoreQr.encodeContact(
                        (connector.selfName?.isEmpty ?? true) ? 'Unknown' : connector.selfName!,
                        connector.selfPublicKeyHex,
                        advTypeChat,
                      );
                      Clipboard.setData(ClipboardData(text: data));
                      showDismissibleSnackBar(
                        context,
                        content: Text(context.l10n.common_copiedToClipboard),
                      );
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        const Icon(Icons.paste),
                        const SizedBox(width: 8),
                        Text(context.l10n.contacts_addContactFromClipboard),
                      ],
                    ),
                    onTap: () async => await ContactImportHelper.importFromClipboard(context),
                  ),
                ],
                icon: const Icon(Icons.connect_without_contact),
              ),
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
                        const Icon(Icons.cell_tower),
                        const SizedBox(width: 8),
                        Text(context.l10n.repeaters_title),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RepeatersScreen(),
                      ),
                    ),
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
          body: Column(
            children: [
              if (syncBanner != null) syncBanner,
              Expanded(
                child: chatItems.isEmpty
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
                        itemExtent: 80.0,
                        itemCount: chatItems.length,
                        itemBuilder: (context, index) {
                          final item = chatItems[index];
                    final isChannel = item.channel != null;
                    final iconColor = isChannel ? Colors.blue : Colors.green;
                    final bgColor = isChannel
                        ? Colors.blue.withValues(alpha: 0.2)
                        : Colors.green.withValues(alpha: 0.2);
                    IconData iconData = Icons.person;
                    String? emojiIcon;
                    
                    if (isChannel) {
                      if (item.channel!.isPublicChannel) {
                        iconData = Icons.public;
                      } else if (item.channel!.name.startsWith('#')) {
                        iconData = Icons.tag;
                      } else {
                        iconData = Icons.lock;
                      }
                    } else {
                      if (item.contact != null && item.contact!.type == advTypeRoom) {
                        iconData = Icons.meeting_room;
                      } else if (item.contact != null) {
                        emojiIcon = firstEmoji(item.contact!.name);
                        iconData = Icons.person;
                      }
                    }

                    return GestureDetector(
                      onLongPress: () => _showChatActions(context, item, connector),
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: bgColor,
                            child: emojiIcon != null 
                                ? Text(emojiIcon, style: const TextStyle(fontSize: 20))
                                : Icon(iconData, color: iconColor),
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
                              final unread = item.unreadCount;
                              connector.markContactRead(item.contact!.publicKeyHex);
                              
                              final settingsService = context.read<AppSettingsService>();
                              if (settingsService.settings.autoFavoriteOnChat && !item.contact!.isFavorite) {
                                await connector.setContactFlags(item.contact!, isFavorite: true);
                              }
                              
                              await Future.delayed(const Duration(milliseconds: 50));
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(contact: item.contact!, unreadCount: unread),
                                  ),
                                );
                              }
                            } else if (item.channel != null) {
                              final unread = item.unreadCount;
                              connector.markChannelRead(item.channel!.index);
                              await Future.delayed(const Duration(milliseconds: 50));
                              if (context.mounted) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChannelChatScreen(channel: item.channel!, unreadCount: unread),
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
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NewChatScreen(),
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          bottomNavigationBar: SafeArea(
            top: false,
            child: QuickSwitchBar(
              selectedIndex: 0,
              onDestinationSelected: (index) => _handleQuickSwitch(index, context),
            ),
          ),
          ),
        );
      },
    );
  }

}
