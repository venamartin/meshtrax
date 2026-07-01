import 'dart:async';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/utils/platform_info.dart';
import 'package:meshtrax/widgets/app_bar.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../services/ui_view_state_service.dart';
import '../models/channel.dart';
import '../utils/dialog_utils.dart';
import '../utils/disconnect_navigation_mixin.dart';
import '../utils/route_transitions.dart';
import '../widgets/list_filter_widget.dart';
import '../widgets/empty_state.dart';
import '../widgets/quick_switch_bar.dart';
import '../widgets/unread_badge.dart';
import '../helpers/snack_bar_builder.dart';
import 'channel_chat_screen.dart';
import 'channel_share_screen.dart';
import 'channel_qr_scanner_screen.dart';
import 'chats_screen.dart';
import 'map_screen.dart';
import 'settings_screen.dart';

class ChannelsScreen extends StatefulWidget {
  final bool hideBackButton;

  const ChannelsScreen({super.key, this.hideBackButton = false});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen>
    with DisconnectNavigationMixin {
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;

  ChannelMessageStore get _channelMessageStore => ChannelMessageStore();

  @override
  void initState() {
    super.initState();
    _searchController.text = context
        .read<UiViewStateService>()
        .channelsSearchText;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeshCoreConnector>().getChannels();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connector = context.watch<MeshCoreConnector>();
    final viewState = context.watch<UiViewStateService>();

    final channelMessageStore = ChannelMessageStore();
    channelMessageStore.setPublicKeyHex = connector.selfPublicKeyHex;

    // Auto-navigate back to scanner if disconnected
    if (!checkConnectionAndNavigate(connector)) {
      return const SizedBox.shrink();
    }

    final allowBack = !connector.isConnected;

    return PopScope(
      canPop: allowBack,
      child: Scaffold(
        appBar: AppBar(
          title: AppBarTitle(context.l10n.channels_title),
          centerTitle: true,
          automaticallyImplyLeading: false,
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
        body: RefreshIndicator(
          onRefresh: () async {
            await context.read<MeshCoreConnector>().getChannels(force: true);
          },
          child: () {
            if (connector.isLoadingChannels) {
              return const Center(child: CircularProgressIndicator());
            }

            final channels = connector.channels;

            if (channels.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height - 200,
                    child: EmptyState(
                      icon: Icons.tag,
                      title: context.l10n.channels_noChannelsConfigured,
                      action: FilledButton.icon(
                        onPressed: () => _addPublicChannel(context, connector),
                        icon: const Icon(Icons.public),
                        label: Text(context.l10n.channels_addPublicChannel),
                      ),
                    ),
                  ),
                ],
              );
            }

            final filteredChannels = _filterAndSortChannels(
              channels,
              connector,
              viewState,
            );

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: context.l10n.channels_searchChannels,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (viewState.channelsSearchText.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchDebounce?.cancel();
                                _searchDebounce = null;
                                _searchController.clear();
                                context
                                    .read<UiViewStateService>()
                                    .setChannelsSearchText('');
                              },
                            ),
                          _buildFilterButton(viewState),
                        ],
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      _searchDebounce?.cancel();
                      _searchDebounce = Timer(
                        const Duration(milliseconds: 300),
                        () {
                          if (!mounted) return;
                          context
                              .read<UiViewStateService>()
                              .setChannelsSearchText(value);
                        },
                      );
                    },
                  ),
                ),
                Expanded(
                  child: filteredChannels.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height - 300,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      context.l10n.channels_noChannelsFound,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : (viewState.channelsSortOption ==
                                ChannelSortOption.manual &&
                            viewState.channelsSearchText.isEmpty)
                      ? ReorderableListView.builder(
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 88,
                          ),
                          buildDefaultDragHandles: false,
                          itemCount: filteredChannels.length,
                          onReorder: (oldIndex, newIndex) {
                            if (newIndex > oldIndex) newIndex -= 1;
                            final reordered = List<Channel>.from(
                              filteredChannels,
                            );
                            final item = reordered.removeAt(oldIndex);
                            reordered.insert(newIndex, item);
                            unawaited(
                              connector.setChannelOrder(
                                reordered.map((c) => c.index).toList(),
                              ),
                            );
                          },
                          itemBuilder: (context, index) {
                            final channel = filteredChannels[index];
                            return _buildChannelTile(
                              context,
                              connector,
                              channelMessageStore,
                              channel,
                              showDragHandle: true,
                              dragIndex: index,
                            );
                          },
                        )
                      : ListView.builder(
                          itemExtent: 80.0,
                          padding: const EdgeInsets.only(
                            top: 8,
                            bottom: 88,
                          ),
                          itemCount: filteredChannels.length,
                          itemBuilder: (context, index) {
                            final channel = filteredChannels[index];
                            return _buildChannelTile(
                              context,
                              connector,
                              channelMessageStore,
                              channel,
                            );
                          },
                        ),
                ),
              ],
            );
          }(),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddChannelDialog(context),
          tooltip: context.l10n.channels_addChannel,
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: QuickSwitchBar(
            selectedIndex: 0,
            onDestinationSelected: (index) =>
                _handleQuickSwitch(index, context),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelTile(
    BuildContext context,
    MeshCoreConnector connector,
    ChannelMessageStore channelMessageStore,
    Channel channel, {
    bool showDragHandle = false,
    int? dragIndex,
  }) {
    final unreadCount = connector.getUnreadCountForChannel(channel);

    // Determine icon and colors based on channel type
    IconData icon;
    Color iconColor;
    Color bgColor;
    String subtitle;

    if (channel.isPublicChannel) {
      icon = Icons.public;
      iconColor = Colors.green;
      bgColor = Colors.green.withValues(alpha: 0.2);
      subtitle = context.l10n.channels_publicChannel;
    } else if (channel.name.startsWith('#')) {
      icon = Icons.tag;
      iconColor = Colors.orange;
      bgColor = Colors.orange.withValues(alpha: 0.2);
      subtitle = context.l10n.channels_hashtagChannel;
    } else {
      icon = Icons.lock;
      iconColor = Colors.blue;
      bgColor = Colors.blue.withValues(alpha: 0.2);
      subtitle = context.l10n.channels_privateChannel;
    }

    return Card(
      key: ValueKey('channel_${channel.index}'),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        onSecondaryTapUp: PlatformInfo.isDesktop
            ? (_) => _showChannelActions(
                context,
                connector,
                channelMessageStore,
                channel,
              )
            : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: bgColor,
            child: Icon(icon, color: iconColor),
          ),
          title: Text(
            channel.name.isEmpty
                ? context.l10n.channels_channelIndex(channel.index)
                : channel.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (unreadCount > 0) ...[
                UnreadBadge(count: unreadCount),
                const SizedBox(width: 4),
              ],
              if (showDragHandle && dragIndex != null)
                ReorderableDelayedDragStartListener(
                  index: dragIndex,
                  child: Icon(
                    Icons.drag_handle,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          onTap: () async {
            connector.markChannelRead(channel.index);
            await Future.delayed(const Duration(milliseconds: 50));
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChannelChatScreen(channel: channel, unreadCount: unreadCount),
                ),
              );
            }
          },
          onLongPress: () => _showChannelActions(
            context,
            connector,
            channelMessageStore,
            channel,
          ),
        ),
      ),
    );
  }

  void _showChannelActions(
    BuildContext context,
    MeshCoreConnector connector,
    ChannelMessageStore channelMessageStore,
    Channel channel,
  ) {
    final parentContext = context;
    final settingsService = context.read<AppSettingsService>();
    final isMuted = settingsService.isChannelMuted(channel.name);

    showModalBottomSheet(
      context: parentContext,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(context.l10n.channels_editChannel),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Future.delayed(const Duration(milliseconds: 100));
                if (parentContext.mounted) {
                  _showEditChannelDialog(parentContext, connector, channel);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.qr_code_2),
              title: Text(context.l10n.channels_shareChannel),
              onTap: () {
                Navigator.pop(sheetContext);
                if (parentContext.mounted) {
                  Navigator.push(
                    parentContext,
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
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: Text(
                context.l10n.channels_deleteChannel,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Future.delayed(const Duration(milliseconds: 100));
                if (parentContext.mounted) {
                  _confirmDeleteChannel(
                    context,
                    connector,
                    channelMessageStore,
                    channel,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickSwitch(int index, BuildContext context) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const ChatsScreen(hideBackButton: true)),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          buildQuickSwitchRoute(const MapScreen(hideBackButton: true)),
        );
        break;
    }
  }

  Future<void> _disconnect(BuildContext context) async {
    final connector = context.read<MeshCoreConnector>();
    await showDisconnectDialog(context, connector);
  }

  Widget _buildFilterButton(UiViewStateService viewState) {
    return SortFilterMenu<ChannelSortOption>(
      tooltip: context.l10n.listFilter_tooltip,
      sections: [
        SortFilterMenuSection<ChannelSortOption>(
          title: context.l10n.channels_sortBy,
          options: [
            SortFilterMenuOption<ChannelSortOption>(
              value: ChannelSortOption.manual,
              label: context.l10n.channels_sortManual,
              checked: viewState.channelsSortOption == ChannelSortOption.manual,
            ),
            SortFilterMenuOption<ChannelSortOption>(
              value: ChannelSortOption.name,
              label: context.l10n.channels_sortAZ,
              checked: viewState.channelsSortOption == ChannelSortOption.name,
            ),
            SortFilterMenuOption<ChannelSortOption>(
              value: ChannelSortOption.latestMessages,
              label: context.l10n.channels_sortLatestMessages,
              checked:
                  viewState.channelsSortOption ==
                  ChannelSortOption.latestMessages,
            ),
            SortFilterMenuOption<ChannelSortOption>(
              value: ChannelSortOption.unread,
              label: context.l10n.channels_sortUnread,
              checked: viewState.channelsSortOption == ChannelSortOption.unread,
            ),
          ],
        ),
      ],
      onSelected: (sortOption) {
        viewState.setChannelsSortOption(sortOption);
      },
    );
  }

  List<Channel> _filterAndSortChannels(
    List<Channel> channels,
    MeshCoreConnector connector,
    UiViewStateService viewState,
  ) {
    var filtered = channels.where((channel) {
      if (viewState.channelsSearchText.isEmpty) return true;
      final label = _normalizeChannelName(channel);
      return label.toLowerCase().contains(
        viewState.channelsSearchText.toLowerCase(),
      );
    }).toList();

    int compareByName(Channel a, Channel b) {
      final nameA = _normalizeChannelName(a);
      final nameB = _normalizeChannelName(b);
      return nameA.toLowerCase().compareTo(nameB.toLowerCase());
    }

    switch (viewState.channelsSortOption) {
      case ChannelSortOption.manual:
        break;
      case ChannelSortOption.latestMessages:
        filtered.sort((a, b) {
          final aMessages = connector.getChannelMessages(a);
          final bMessages = connector.getChannelMessages(b);
          final aLast = aMessages.isEmpty
              ? DateTime(1970)
              : aMessages.last.timestamp;
          final bLast = bMessages.isEmpty
              ? DateTime(1970)
              : bMessages.last.timestamp;
          final timeCompare = bLast.compareTo(aLast);
          if (timeCompare != 0) return timeCompare;
          return compareByName(a, b);
        });
        break;
      case ChannelSortOption.unread:
        filtered.sort((a, b) {
          final aUnread = connector.getUnreadCountForChannel(a);
          final bUnread = connector.getUnreadCountForChannel(b);
          final unreadCompare = bUnread.compareTo(aUnread);
          if (unreadCompare != 0) return unreadCompare;
          return compareByName(a, b);
        });
        break;
      case ChannelSortOption.name:
        filtered.sort(compareByName);
        break;
    }

    return filtered;
  }

  String _normalizeChannelName(Channel channel) {
    if (channel.name.isEmpty) {
      return 'Channel ${channel.index}'; // Fallback for sorting
    }
    final trimmed = channel.name.trim();
    if (trimmed.startsWith('#') && trimmed.length > 1) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  void _showAddChannelDialog(BuildContext context) {
    final connector = context.read<MeshCoreConnector>();
    final nextIndex = _findNextAvailableIndex(
      connector.channels,
      connector.maxChannels,
    );
    final hasPublicChannel = connector.channels.any((c) => c.isPublicChannel);
    int? selectedOption;
    final nameController = TextEditingController();
    final pskController = TextEditingController();
    final hashtagController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          Widget buildOptionTile({
            required int optionIndex,
            required IconData icon,
            required String title,
            required String subtitle,
            bool enabled = true,
            VoidCallback? onTapOverride,
          }) {
            final isSelected = selectedOption == optionIndex;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: enabled
                    ? (isSelected
                          ? Theme.of(dialogContext).colorScheme.primaryContainer
                          : null)
                    : Colors.grey.withValues(alpha: 0.2),
                child: Icon(
                  icon,
                  color: enabled
                      ? (isSelected
                            ? Theme.of(dialogContext).colorScheme.primary
                            : null)
                      : Colors.grey,
                ),
              ),
              title: Text(
                title,
                style: TextStyle(color: enabled ? null : Colors.grey),
              ),
              subtitle: Text(
                subtitle,
                style: TextStyle(color: enabled ? null : Colors.grey),
              ),
              trailing: enabled ? const Icon(Icons.chevron_right) : null,
              selected: isSelected,
              onTap: enabled
                  ? (onTapOverride ??
                      () {
                        setDialogState(() {
                          selectedOption = optionIndex;
                          nameController.clear();
                          pskController.clear();
                          hashtagController.clear();
                        });
                      })
                  : null,
            );
          }

          Widget? buildExpandedContent(
            ChannelMessageStore channelMessageStore,
          ) {
            switch (selectedOption) {
              case 0: // Create Private Channel
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.channels_channelName,
                          border: const OutlineInputBorder(),
                        ),
                        maxLength: 31,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                final name = nameController.text.trim();
                                if (name.isEmpty) {
                                  showDismissibleSnackBar(
                                    context,
                                    content: Text(
                                      dialogContext
                                          .l10n
                                          .channels_enterChannelName,
                                    ),
                                  );
                                  return;
                                }
                                final random = Random.secure();
                                final psk = Uint8List(16);
                                for (int i = 0; i < 16; i++) {
                                  psk[i] = random.nextInt(256);
                                }
                                Navigator.pop(dialogContext);
                                await connector.setChannel(
                                  nextIndex,
                                  name,
                                  psk,
                                );
                                await channelMessageStore.clearChannelMessages(
                                  nextIndex,
                                );
                                if (context.mounted) {
                                  showDismissibleSnackBar(
                                    context,
                                    content: Text(
                                      context.l10n.channels_channelAdded(name),
                                    ),
                                  );
                                }
                              },
                              child: Text(dialogContext.l10n.common_create),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

              case 1: // Create Hashtag Channel
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: hashtagController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.channels_enterHashtag,
                          hintText: dialogContext.l10n.channels_hashtagHint,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.tag),
                        ),
                        maxLength: 31,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () async {
                                var hashtag = hashtagController.text.trim();
                                if (hashtag.isEmpty) {
                                  showDismissibleSnackBar(
                                    context,
                                    content: Text(
                                      dialogContext
                                          .l10n
                                          .channels_enterChannelName,
                                    ),
                                  );
                                  return;
                                }

                                if (hashtag.startsWith('#')) {
                                  hashtag = hashtag.substring(1);
                                }
                                final channelName = '#$hashtag';
                                final psk = Channel.derivePskFromHashtag(hashtag);

                                if (dialogContext.mounted) {
                                  Navigator.pop(dialogContext);
                                }
                                connector.setChannel(
                                  nextIndex,
                                  channelName,
                                  psk,
                                );
                                if (context.mounted) {
                                  showDismissibleSnackBar(
                                    context,
                                    content: Text(
                                      context.l10n.channels_channelAdded(
                                        channelName,
                                      ),
                                    ),
                                  );
                                }
                              },
                              child: Text(dialogContext.l10n.common_add),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

              case 2: // Scan Channel QR
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            Navigator.pop(dialogContext);
                            if (context.mounted) {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ChannelQrScannerScreen(),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.qr_code_scanner),
                          label: Text(dialogContext.l10n.channels_shareChannelQr),
                        ),
                      ),
                    ],
                  ),
                );

              case 3: // Manually Add Channel (Private Key and Name)
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.channels_channelName,
                          border: const OutlineInputBorder(),
                        ),
                        maxLength: 31,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: pskController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.channels_pskHex,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton(
                              onPressed: () {
                                final name = nameController.text.trim();
                                final pskHex = pskController.text.trim();
                                if (name.isEmpty) {
                                  showDismissibleSnackBar(
                                    context,
                                    content: Text(
                                      dialogContext
                                          .l10n
                                          .channels_enterChannelName,
                                    ),
                                  );
                                  return;
                                }
                                Uint8List psk;
                                try {
                                  psk = Channel.parsePskHex(pskHex);
                                } on FormatException {
                                  showDismissibleSnackBar(
                                    context,
                                    content: Text(
                                      dialogContext
                                          .l10n
                                          .channels_pskMustBe32Hex,
                                    ),
                                  );
                                  return;
                                }
                                Navigator.pop(dialogContext);
                                connector.setChannel(nextIndex, name, psk);
                                if (context.mounted) {
                                  showDismissibleSnackBar(
                                    context,
                                    content: Text(
                                      context.l10n.channels_channelAdded(name),
                                    ),
                                  );
                                }
                              },
                              child: Text(dialogContext.l10n.common_add),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );

              case 4: // Add Public Channel
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            final psk = Channel.parsePskHex(Channel.publicChannelPsk);
                            connector.setChannel(nextIndex, 'Public', psk);
                            if (context.mounted) {
                              showDismissibleSnackBar(
                                context,
                                content: Text(context.l10n.channels_publicChannelAdded),
                              );
                            }
                          },
                          child: Text(dialogContext.l10n.common_add),
                        ),
                      ),
                    ],
                  ),
                );

              default:
                return null;
            }
          }

          return AlertDialog(
            title: Text(dialogContext.l10n.channels_addChannel),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!hasPublicChannel) ...[
                      buildOptionTile(
                        optionIndex: 4,
                        icon: Icons.public,
                        title: dialogContext.l10n.channels_joinPublicChannel,
                        subtitle: dialogContext.l10n.channels_joinPublicChannelDesc,
                      ),
                      if (selectedOption == 4)
                        buildExpandedContent(_channelMessageStore)!,
                      const Divider(height: 1),
                    ],
                    buildOptionTile(
                      optionIndex: 0,
                      icon: Icons.lock,
                      title: dialogContext.l10n.channels_createPrivateChannel,
                      subtitle: dialogContext.l10n.channels_createPrivateChannelDesc,
                    ),
                    if (selectedOption == 0)
                      buildExpandedContent(_channelMessageStore)!,
                    const Divider(height: 1),
                    buildOptionTile(
                      optionIndex: 1,
                      icon: Icons.tag,
                      title: dialogContext.l10n.channels_joinHashtagChannel, // Actually we'll use this since user says Create
                      subtitle: dialogContext.l10n.channels_joinHashtagChannelDesc,
                    ),
                    if (selectedOption == 1)
                      buildExpandedContent(_channelMessageStore)!,
                    const Divider(height: 1),
                    buildOptionTile(
                      optionIndex: 2,
                      icon: Icons.qr_code_scanner,
                      title: dialogContext.l10n.channels_shareChannelQr,
                      subtitle: dialogContext.l10n.channels_scanQrCode,
                      onTapOverride: () async {
                        Navigator.pop(dialogContext);
                        if (context.mounted) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChannelQrScannerScreen(),
                            ),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),
                    buildOptionTile(
                      optionIndex: 3,
                      icon: Icons.add,
                      title: dialogContext.l10n.channels_joinPrivateChannel,
                      subtitle: dialogContext.l10n.channels_joinPrivateChannelDesc,
                    ),
                    if (selectedOption == 3)
                      buildExpandedContent(_channelMessageStore)!,
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(dialogContext.l10n.common_close),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditChannelDialog(
    BuildContext context,
    MeshCoreConnector connector,
    Channel channel,
  ) {
    final nameController = TextEditingController(text: channel.name);
    final pskController = TextEditingController(text: channel.pskHex);
    bool smazEnabled = connector.isChannelSmazEnabled(channel.index);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) => AlertDialog(
          title: Text(
            dialogContext.l10n.channels_editChannelTitle(channel.index),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: dialogContext.l10n.channels_channelName,
                    border: const OutlineInputBorder(),
                  ),
                  maxLength: 31,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: pskController,
                  decoration: InputDecoration(
                    labelText: dialogContext.l10n.channels_pskHex,
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.casino),
                      tooltip: dialogContext.l10n.channels_generateRandomPsk,
                      onPressed: () {
                        final random = Random.secure();
                        final bytes = Uint8List(16);
                        for (int i = 0; i < 16; i++) {
                          bytes[i] = random.nextInt(256);
                        }
                        pskController.text = Channel.formatPskHex(bytes);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(dialogContext.l10n.channels_smazCompression),
                  value: smazEnabled,
                  onChanged: (value) => setState(() => smazEnabled = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(dialogContext.l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final pskHex = pskController.text.trim();

                Uint8List psk;
                try {
                  psk = Channel.parsePskHex(pskHex);
                } on FormatException {
                  showDismissibleSnackBar(
                    dialogContext,
                    content: Text(dialogContext.l10n.channels_pskMustBe32Hex),
                  );
                  return;
                }

                Navigator.pop(dialogContext);
                try {
                  await connector.setChannel(channel.index, name, psk);
                  await connector.setChannelSmazEnabled(
                    channel.index,
                    smazEnabled,
                  );
                  if (!context.mounted) return;
                  showDismissibleSnackBar(
                    context,
                    content: Text(context.l10n.channels_channelUpdated(name)),
                  );
                } catch (e, st) {
                  debugPrint(st.toString());
                  if (!context.mounted) return;
                  showDismissibleSnackBar(
                    context,
                    content: Text('Failed to update channel: $e'),
                  );
                }
              },
              child: Text(dialogContext.l10n.common_save),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteChannel(
    BuildContext context,
    MeshCoreConnector connector,
    ChannelMessageStore channelMessageStore,
    Channel channel,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.l10n.channels_deleteChannel),
        content: Text(
          dialogContext.l10n.channels_deleteChannelConfirm(channel.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(dialogContext.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await connector.deleteChannel(channel.index);

                await channelMessageStore.clearChannelMessages(channel.index);

                if (!context.mounted) return;

                showDismissibleSnackBar(
                  context,
                  content: Text(
                    context.l10n.channels_channelDeleted(channel.name),
                  ),
                );
              } catch (e, st) {
                if (!context.mounted) return;

                showDismissibleSnackBar(
                  context,
                  content: Text(
                    context.l10n.channels_channelDeleteFailed(channel.name),
                  ),
                );

                // Preserve existing logging (if it was there)
                debugPrint('Failed to delete channel: $e\n$st');
              }
            },
            child: Text(
              dialogContext.l10n.common_delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _addPublicChannel(BuildContext context, MeshCoreConnector connector) {
    final psk = Channel.parsePskHex(Channel.publicChannelPsk);
    connector.setChannel(0, 'Public', psk);
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.channels_publicChannelAdded),
    );
  }

  int _findNextAvailableIndex(List<Channel> channels, int maxChannels) {
    final usedIndices = channels.map((c) => c.index).toSet();
    for (int i = 0; i < maxChannels; i++) {
      if (!usedIndices.contains(i)) return i;
    }
    return 0;
  }

}
