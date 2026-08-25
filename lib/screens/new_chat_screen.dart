import 'dart:math';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../models/contact.dart';
import '../widgets/contact_tile.dart';
import '../widgets/list_filter_widget.dart';
import '../utils/contact_search.dart';
import '../helpers/contact_import_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../utils/telemetry_dialog.dart';
import 'channel_chat_screen.dart';
import 'channel_qr_scanner_screen.dart';
import 'chat_screen.dart';
import 'contact_qr_scanner_screen.dart';
import '../widgets/room_login_dialog.dart';
import '../helpers/meshcore_qr.dart';
import 'package:flutter/services.dart';
import '../services/app_settings_service.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({super.key});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController _searchController = TextEditingController();

  String searchQuery = '';
  ContactSortOption sortOption = ContactSortOption.lastSeen;
  ContactTypeFilter typeFilter = ContactTypeFilter.all;
  ContactSourceFilter sourceFilter = ContactSourceFilter.all;
  bool showUnreadOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddContactDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.contacts_addContact),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.qr_code_scanner),
              ),
              title: Text(context.l10n.contacts_scanQrCode),
              subtitle: Text(context.l10n.contacts_scanQrCodeDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(dialogContext);
                _navigateToQrScanner(context);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.tag),
              ),
              title: Text(context.l10n.contacts_enterIdHash),
              subtitle: Text(context.l10n.contacts_enterIdHashDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.pop(dialogContext);
                _showEnterAdvertDialog(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToQrScanner(BuildContext context) async {
    final scannedData = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const ContactQrScannerScreen(),
      ),
    );
    if (scannedData != null && context.mounted) {
      ContactImportHelper.importFromScannedData(context, scannedData);
    }
  }

  void _showEnterAdvertDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.contacts_enterIdHash),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: context.l10n.contacts_advertHint,
            border: const OutlineInputBorder(),
          ),
          maxLines: 4,
          minLines: 2,
          keyboardType: TextInputType.multiline,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.pop(dialogContext);
              ContactImportHelper.importFromScannedData(context, text);
            },
            child: Text(context.l10n.contacts_import),
          ),
        ],
      ),
    );
  }

  void _showContactOptions(BuildContext context, Contact contact) {
    final isFavorite = contact.isFavorite;
    final connector = context.read<MeshCoreConnector>();
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: Colors.amber[700],
              ),
              title: Text(
                isFavorite
                    ? context.l10n.listFilter_removeFromFavorites
                    : context.l10n.listFilter_addToFavorites,
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                await connector.setContactFlags(
                  contact,
                  isFavorite: !isFavorite,
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
              onTap: () async {
                Navigator.pop(sheetContext);
                final exportContactZeroHopFrame = buildZeroHopContact(contact.publicKey);
                await connector.sendFrame(
                  exportContactZeroHopFrame,
                  expectsGenericAck: true,
                );
                if (context.mounted) {
                    showDismissibleSnackBar(
                      context,
                      content: Text(context.l10n.settings_advertisementSent),
                    );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(
                context.l10n.contacts_deleteContact,
                style: const TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(context.l10n.contacts_deleteContact),
                    content: Text(context.l10n.contacts_removeConfirm(contact.name)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(context.l10n.common_cancel),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          connector.removeContact(contact);
                        },
                        child: Text(
                          context.l10n.common_delete,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Lands the user in the channel they just added, ready to type. Replaces
  /// this screen so the back arrow returns to the chats list rather than the
  /// add screen they are done with.
  ///
  /// The channel is resolved by PSK against the radio's own slot map — never
  /// by the slot index we asked for, which the radio owns. The resolve waits
  /// out the slot resync; a miss means the radio never took the channel, so
  /// we stay put.
  Future<void> _openChannel(Uint8List psk) async {
    final connector = context.read<MeshCoreConnector>();
    final channel = await connector.awaitChannelByPsk(psk);
    if (channel == null || !mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelChatScreen(channel: channel),
      ),
    );
  }

  int _findNextAvailableIndex(List<Channel> channels, int maxChannels) {
    final usedIndices = channels.map((c) => c.index).toSet();
    for (int i = 0; i < maxChannels; i++) {
      if (!usedIndices.contains(i)) return i;
    }
    return 0;
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

          Future<void> createPrivateChannel() async {
            final name = nameController.text.trim();
            if (name.isEmpty) {
              showDismissibleSnackBar(
                context,
                content: Text(dialogContext.l10n.channels_enterChannelName),
              );
              return;
            }
            final random = Random.secure();
            final psk = Uint8List(16);
            for (int i = 0; i < 16; i++) {
              psk[i] = random.nextInt(256);
            }
            Navigator.pop(dialogContext);
            await connector.setChannel(nextIndex, name, psk);
            if (!context.mounted) return;
            showDismissibleSnackBar(
              context,
              content: Text(context.l10n.channels_channelAdded(name)),
            );
            await _openChannel(psk);
          }

          Future<void> addHashtagChannel() async {
            var hashtag = hashtagController.text.trim();
            if (hashtag.isEmpty) {
              showDismissibleSnackBar(
                context,
                content: Text(dialogContext.l10n.channels_enterChannelName),
              );
              return;
            }
            if (hashtag.startsWith('#')) {
              hashtag = hashtag.substring(1);
            }
            final channelName = '#$hashtag';
            final psk = Channel.derivePskFromHashtag(hashtag);

            Navigator.pop(dialogContext);
            await connector.setChannel(nextIndex, channelName, psk);
            if (!context.mounted) return;
            showDismissibleSnackBar(
              context,
              content: Text(context.l10n.channels_channelAdded(channelName)),
            );
            await _openChannel(psk);
          }

          Future<void> joinPrivateChannel() async {
            final name = nameController.text.trim();
            final pskHex = pskController.text.trim();
            if (name.isEmpty) {
              showDismissibleSnackBar(
                context,
                content: Text(dialogContext.l10n.channels_enterChannelName),
              );
              return;
            }
            Uint8List psk;
            try {
              psk = Channel.parsePskHex(pskHex);
            } on FormatException {
              showDismissibleSnackBar(
                context,
                content: Text(dialogContext.l10n.channels_pskMustBe32Hex),
              );
              return;
            }
            Navigator.pop(dialogContext);
            await connector.setChannel(nextIndex, name, psk);
            if (!context.mounted) return;
            showDismissibleSnackBar(
              context,
              content: Text(context.l10n.channels_channelAdded(name)),
            );
            await _openChannel(psk);
          }

          Future<void> joinPublicChannel() async {
            Navigator.pop(dialogContext);
            final psk = Channel.parsePskHex(Channel.publicChannelPsk);
            await connector.setChannel(nextIndex, 'Public', psk);
            if (!context.mounted) return;
            showDismissibleSnackBar(
              context,
              content: Text(context.l10n.channels_publicChannelAdded),
            );
            await _openChannel(psk);
          }

          // The confirm button lives in the dialog's pinned actions row —
          // inside the scrollable body the keyboard covered it. Options with
          // no form (join public) confirm through the same pinned button.
          String? confirmLabel;
          VoidCallback? onConfirm;
          switch (selectedOption) {
            case 0:
              confirmLabel = dialogContext.l10n.common_create;
              onConfirm = createPrivateChannel;
            case 1:
              confirmLabel = dialogContext.l10n.common_add;
              onConfirm = addHashtagChannel;
            case 3:
              confirmLabel = dialogContext.l10n.common_add;
              onConfirm = joinPrivateChannel;
            case 4:
              confirmLabel = dialogContext.l10n.common_add;
              onConfirm = joinPublicChannel;
          }

          Widget? buildExpandedContent() {
            switch (selectedOption) {
              case 0:
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: dialogContext.l10n.channels_channelName,
                      border: const OutlineInputBorder(),
                    ),
                    maxLength: 31,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => createPrivateChannel(),
                  ),
                );
              case 1:
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: hashtagController,
                    decoration: InputDecoration(
                      labelText: dialogContext.l10n.channels_enterHashtag,
                      hintText: dialogContext.l10n.channels_hashtagHint,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.tag),
                    ),
                    maxLength: 31,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => addHashtagChannel(),
                  ),
                );
              case 3:
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.channels_channelName,
                          border: const OutlineInputBorder(),
                        ),
                        maxLength: 31,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: pskController,
                        decoration: InputDecoration(
                          labelText: dialogContext.l10n.channels_pskHex,
                          border: const OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => joinPrivateChannel(),
                      ),
                    ),
                  ],
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
                      const Divider(height: 1),
                    ],
                    buildOptionTile(
                      optionIndex: 0,
                      icon: Icons.lock,
                      title: dialogContext.l10n.channels_createPrivateChannel,
                      subtitle: dialogContext.l10n.channels_createPrivateChannelDesc,
                    ),
                    if (selectedOption == 0) buildExpandedContent()!,
                    const Divider(height: 1),
                    buildOptionTile(
                      optionIndex: 1,
                      icon: Icons.tag,
                      title: dialogContext.l10n.channels_joinHashtagChannel,
                      subtitle: dialogContext.l10n.channels_joinHashtagChannelDesc,
                    ),
                    if (selectedOption == 1) buildExpandedContent()!,
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
                    if (selectedOption == 3) buildExpandedContent()!,
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(dialogContext.l10n.common_close),
              ),
              if (onConfirm != null)
                FilledButton(
                  onPressed: onConfirm,
                  child: Text(confirmLabel!),
                ),
            ],
          );
        },
      ),
    );
  }

  void _openChat(Contact contact) {
    final connector = context.read<MeshCoreConnector>();
    final settingsService = context.read<AppSettingsService>();

    if (settingsService.settings.autoFavoriteOnChat && !contact.isFavorite) {
      unawaited(connector.setContactFlags(contact, isFavorite: true));
    }

    if (contact.type == advTypeRoom) {
      showDialog(
        context: context,
        builder: (context) => RoomLoginDialog(
          room: contact,
          onLogin: (password, isAdmin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => ChatScreen(
                    contact: contact,
                    unreadCount: 0,
                  ),
              ),
            );
          },
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            contact: contact,
            unreadCount: 0,
          ),
        ),
      );
    }
  }

  void _deleteContacts(BuildContext context, MeshCoreConnector connector) {
    showDialog(
      context: context,
      builder: (context) {
        bool includeRepeaters = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Discovered Contacts'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CheckboxListTile(
                    title: const Text('Include Repeaters'),
                    value: includeRepeaters,
                    onChanged: (value) {
                      setState(() {
                        includeRepeaters = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Older than 1 day'),
                    onTap: () {
                      Navigator.pop(context);
                      connector.removeDiscoveredContactsOlderThan(const Duration(days: 1), includeRepeaters: includeRepeaters);
                      if (includeRepeaters) connector.removeRepeaters(maxAge: const Duration(days: 1));
                      showDismissibleSnackBar(context, content: const Text('Deleted discovered contacts older than 1 day.'));
                    },
                  ),
                  ListTile(
                    title: const Text('Older than 7 days'),
                    onTap: () {
                      Navigator.pop(context);
                      connector.removeDiscoveredContactsOlderThan(const Duration(days: 7), includeRepeaters: includeRepeaters);
                      if (includeRepeaters) connector.removeRepeaters(maxAge: const Duration(days: 7));
                      showDismissibleSnackBar(context, content: const Text('Deleted discovered contacts older than 7 days.'));
                    },
                  ),
                  ListTile(
                    title: const Text('Older than 30 days'),
                    onTap: () {
                      Navigator.pop(context);
                      connector.removeDiscoveredContactsOlderThan(const Duration(days: 30), includeRepeaters: includeRepeaters);
                      if (includeRepeaters) connector.removeRepeaters(maxAge: const Duration(days: 30));
                      showDismissibleSnackBar(context, content: const Text('Deleted discovered contacts older than 30 days.'));
                    },
                  ),
                  ListTile(
                    title: const Text('All Discovered Contacts', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      Navigator.pop(context);
                      connector.removeAllDiscoveredContacts(includeRepeaters: includeRepeaters);
                      if (includeRepeaters) connector.removeRepeaters();
                      showDismissibleSnackBar(context, content: const Text('Deleted all discovered contacts.'));
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.common_cancel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDiscoveredContactOptions(
    Contact contact,
    MeshCoreConnector connector,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final l10n = context.l10n;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.add_reaction_sharp),
                title: Text(l10n.discoveredContacts_addContact),
                onTap: () => Navigator.of(sheetContext).pop('import_contact'),
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: Text(l10n.discoveredContacts_copyContact),
                onTap: () => Navigator.of(sheetContext).pop('copy_contact'),
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: Text(l10n.discoveredContacts_deleteContact),
                onTap: () => Navigator.of(sheetContext).pop('delete_contact'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'import_contact':
        connector.importDiscoveredContact(contact);
        break;
      case 'copy_contact':
        final qrData = MeshCoreQr.encodeContact(
          contact.name,
          contact.publicKeyHex,
          contact.type,
        );
        Clipboard.setData(ClipboardData(text: qrData));
        if (!mounted) return;
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_contactAdvertCopied),
        );
        break;
      case 'delete_contact':
        connector.removeDiscoveredContact(contact);
        break;
    }
  }

  DateTime _resolveLastSeen(Contact contact, MeshCoreConnector connector) {
    final localTime = connector.getLocalDiscoveredTime(contact.publicKeyHex);
    if (localTime != null) {
      return localTime;
    }
    return (contact.lastSeen.year > 2000)
        ? contact.lastSeen
        : DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _matchesTypeFilter(Contact contact, ContactTypeFilter filter) {
    if (filter == ContactTypeFilter.all) return true;
    if (filter == ContactTypeFilter.favorites && contact.isFavorite) {
      return true;
    }
    if (filter == ContactTypeFilter.users && contact.type == advTypeChat) {
      return true;
    }
    if (filter == ContactTypeFilter.rooms && contact.type == advTypeRoom) {
      return true;
    }
    if (filter == ContactTypeFilter.repeaters && contact.type == advTypeRepeater) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, child) {
        // One merged list, exactly like Manage Repeaters: saved contacts
        // plus discovered-but-unsaved ones, deduped by allContacts.
        final contacts = connector.allContacts
            .where((c) => c.type != advTypeRepeater)
            .toList();

        final selfPubKeyHex = connector.selfPublicKey != null
            ? pubKeyToHex(connector.selfPublicKey!)
            : null;

        final filtered = contacts.where((contact) {
          final isDiscovered = !contact.isActive;
          if (sourceFilter == ContactSourceFilter.saved && isDiscovered) return false;
          if (sourceFilter == ContactSourceFilter.discovered && !isDiscovered) return false;
          if (searchQuery.isNotEmpty && !matchesContactQuery(contact, searchQuery)) return false;
          if (typeFilter != ContactTypeFilter.all && !_matchesTypeFilter(contact, typeFilter)) return false;
          if (showUnreadOnly && connector.getUnreadCountForContact(contact) == 0) return false;
          if (contact.publicKeyHex == selfPubKeyHex) return false;
          return true;
        }).toList();

        switch (sortOption) {
          case ContactSortOption.lastSeen:
            filtered.sort((a, b) {
              int cmp = _resolveLastSeen(b, connector).compareTo(_resolveLastSeen(a, connector));
              if (cmp != 0) return cmp;
              return a.name.toLowerCase().compareTo(b.name.toLowerCase());
            });
            break;
          case ContactSortOption.recentMessages:
            // Arrival order, matching the chats screen — the claimed send
            // time is display-only (v6).
            filtered.sort((a, b) => connector
                .latestContactArrivalUs(b)
                .compareTo(connector.latestContactArrivalUs(a)));
            break;
          case ContactSortOption.name:
            filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            break;
        }

        final totalCount =
            contacts.where((c) => c.publicKeyHex != selfPubKeyHex).length;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.l10n.newChat_title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  context.l10n.newChat_contactCount(totalCount),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person_add, color: Colors.white),
                ),
                title: Text(context.l10n.newChat_newContact, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () => _navigateToQrScanner(context),
                ),
                onTap: () => _showAddContactDialog(context),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.tag, color: Colors.white),
                ),
                title: Text(context.l10n.newChat_newChannel, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ChannelQrScannerScreen(),
                      ),
                    );
                  },
                ),
                onTap: () => _showAddChannelDialog(context),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: context.l10n.listFilter_searchHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => searchQuery = '');
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onChanged: (val) => setState(() => searchQuery = val),
                      ),
                    ),
                    ContactsFilterMenu(
                      sortOption: sortOption,
                      typeFilter: typeFilter,
                      sourceFilter: sourceFilter,
                      showUnreadOnly: showUnreadOnly,
                      onSortChanged: (val) => setState(() => sortOption = val),
                      onTypeFilterChanged: (val) => setState(() => typeFilter = val),
                      onSourceFilterChanged: (val) => setState(() => sourceFilter = val),
                      onUnreadOnlyChanged: (val) => setState(() => showUnreadOnly = val),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(context.l10n.discoveredContacts_deleteContactAll),
                            ],
                          ),
                          onTap: () {
                            _deleteContacts(context, connector);
                          },
                        ),
                      ],
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Text(
                          searchQuery.isEmpty
                              ? context.l10n.contacts_noContacts
                              : context.l10n.contacts_noMatchingContacts,
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final contact = filtered[index];
                          final isDiscovered = !contact.isActive;
                          return ContactTile(
                            contact: contact,
                            lastSeen: contact.lastSeen,
                            unreadCount: connector.getUnreadCountForContact(contact),
                            isFavorite: contact.isFavorite,
                            isDiscovered: isDiscovered,
                            onTap: () async {
                              if (!isDiscovered) {
                                _openChat(contact);
                                return;
                              }
                              final success = await connector.importDiscoveredContact(contact);
                              if (success && context.mounted) {
                                _openChat(contact);
                              } else if (!success && context.mounted) {
                                showDismissibleSnackBar(
                                  context,
                                  content: Text(context.l10n.contacts_contactImportFailed),
                                );
                              }
                            },
                            onLongPress: () => isDiscovered
                                ? _showDiscoveredContactOptions(contact, connector)
                                : _showContactOptions(context, contact),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
