import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../widgets/contact_info_dialog.dart';
import '../widgets/contact_tile.dart';
import '../widgets/list_filter_widget.dart';
import '../utils/contact_search.dart';
import '../helpers/snack_bar_builder.dart';
import '../utils/telemetry_dialog.dart';
import 'add_screen.dart';
import 'chat_screen.dart';
import 'contact_share_screen.dart';
import '../widgets/contact_copy_tiles.dart';
import '../widgets/room_login_dialog.dart';
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
              leading: const Icon(Icons.info_outline),
              title: Text(context.l10n.contact_info),
              onTap: () {
                Navigator.pop(sheetContext);
                ContactInfoDialog.show(context, contact);
              },
            ),
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
              leading: const Icon(Icons.qr_code),
              title: Text(context.l10n.share_qrAndLink),
              onTap: () {
                Navigator.pop(sheetContext);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ContactShareScreen(
                      name: contact.name,
                      pubKeyHex: contact.publicKeyHex,
                      type: contact.type,
                    ),
                  ),
                );
              },
            ),
            ...contactCopyTiles(
              context,
              name: contact.name,
              keyHex: contact.publicKeyHex,
              type: contact.type,
              close: () => Navigator.pop(sheetContext),
            ),
            ListTile(
              leading: const Icon(Icons.connect_without_contact),
              title: Text(context.l10n.contacts_ShareContactZeroHop),
              onTap: () async {
                Navigator.pop(sheetContext);
                final shared = await connector.shareContactZeroHop(
                  contact.publicKey,
                );
                if (context.mounted) {
                  showDismissibleSnackBar(
                    context,
                    content: Text(
                      shared
                          ? context.l10n.settings_advertisementSent
                          : context.l10n.contacts_shareByAdvertFailed,
                    ),
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
                    content: Text([
                      context.l10n.contacts_removeConfirm(contact.name),
                      if (connector.radioAutoAdds(contact.type))
                        context.l10n.contacts_deleteComesBack,
                    ].join('\n\n')),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: Text(context.l10n.common_cancel),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          if (!await connector.removeContact(contact) &&
                              context.mounted) {
                            showDismissibleSnackBar(
                              context,
                              content: Text(context.l10n
                                  .contacts_contactDeleteFailed(contact.name)),
                            );
                          }
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

  /// One page adds a contact or a channel from any format.
  void _openAdd({bool scanFirst = false}) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddScreen(scanFirst: scanFirst)),
      );

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
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.contact_info),
                onTap: () => Navigator.of(sheetContext).pop('info'),
              ),
              ListTile(
                leading: const Icon(Icons.add_reaction_sharp),
                title: Text(l10n.discoveredContacts_addContact),
                onTap: () => Navigator.of(sheetContext).pop('import_contact'),
              ),
              ...contactCopyTiles(
                context,
                name: contact.name,
                keyHex: contact.publicKeyHex,
                type: contact.type,
                close: () => Navigator.of(sheetContext).pop(),
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
      case 'info':
        ContactInfoDialog.show(context, contact);
        break;
      case 'import_contact':
        connector.importDiscoveredContact(contact);
        break;
      case 'delete_contact':
        connector.removeDiscoveredContact(contact);
        break;
    }
  }

  DateTime _resolveLastSeen(Contact contact, MeshCoreConnector connector) =>
      connector.heardAt(contact);

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
          if (searchQuery.isNotEmpty &&
              !matchesContactQuery(
                contact,
                searchQuery,
                note: connector.contactNote(contact.publicKeyHex),
              )) {
            return false;
          }
          if (typeFilter != ContactTypeFilter.all && !_matchesTypeFilter(contact, typeFilter)) return false;
          if (showUnreadOnly && connector.getUnreadCountForContact(contact) == 0) return false;
          if (contact.publicKeyHex == selfPubKeyHex) return false;
          return true;
        }).toList();

        switch (sortOption) {
          case ContactSortOption.lastSeen:
          case ContactSortOption.hops:
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
                  child: Icon(Icons.add, color: Colors.white),
                ),
                title: Text(context.l10n.add_title, style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: IconButton(
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: context.l10n.channels_scanQrCode,
                  onPressed: () => _openAdd(scanFirst: true),
                ),
                onTap: _openAdd,
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
                            // Same value the sort uses: when WE last heard
                            // the node. contact.lastSeen is sender-claimed
                            // advert time — a node with a broken clock sits
                            // at the top labeled "~9 days" otherwise.
                            lastSeen: _resolveLastSeen(contact, connector),
                            unreadCount: connector.getUnreadCountForContact(contact),
                            isFavorite: contact.isFavorite,
                            isDiscovered: isDiscovered,
                            realName:
                                connector.realNameFor(contact.publicKeyHex),
                            sharesPosition:
                                connector.positionVisibleTo(contact),
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
