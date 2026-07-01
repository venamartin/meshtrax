import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../widgets/app_bar.dart';
import '../widgets/contact_tile.dart';
import '../widgets/list_filter_widget.dart';
import '../widgets/repeater_login_dialog.dart';
import '../helpers/meshcore_qr.dart';
import '../helpers/snack_bar_builder.dart';
import '../utils/contact_search.dart';
import 'path_trace_map.dart';
import 'repeater_hub_screen.dart';

class RepeatersScreen extends StatefulWidget {
  const RepeatersScreen({super.key});

  @override
  State<RepeatersScreen> createState() => _RepeatersScreenState();
}

class _RepeatersScreenState extends State<RepeatersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  ContactSortOption sortOption = ContactSortOption.lastSeen;
  ContactTypeFilter typeFilter = ContactTypeFilter.all;
  bool showUnreadOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showRepeaterOptions(BuildContext context, MeshCoreConnector connector, Contact contact) {
    if (!contact.isActive) {
      connector.importDiscoveredContact(contact);
    }

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.radar, color: Colors.green),
              title: Text(context.l10n.contacts_ping),
              onTap: () {
                Navigator.pop(sheetContext);
                final hw = context.read<MeshCoreConnector>().pathHashByteWidth;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PathTraceMapScreen(
                      title: context.l10n.contacts_repeaterPing,
                      path: contact.publicKey.sublist(0, hw),
                      targetContact: contact,
                      pathHashByteWidth: hw,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cell_tower, color: Colors.orange),
              title: Text(context.l10n.contacts_manageRepeater),
              onTap: () {
                Navigator.pop(sheetContext);
                showDialog(
                  context: context,
                  builder: (context) => RepeaterLoginDialog(
                    repeater: contact,
                    onLogin: (password, isAdmin) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RepeaterHubScreen(
                            repeater: contact,
                            password: password,
                            isAdmin: isAdmin,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
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
            if (!contact.isFavorite)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  context.l10n.contacts_deleteContact,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete(context, connector, contact);
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, child) {
        final repeaters = connector.allContacts
            .where((c) => c.type == advTypeRepeater)
            .toList();

        final searchQueryLower = searchQuery.toLowerCase();
        
        final filtered = repeaters.where((c) {
          if (typeFilter == ContactTypeFilter.favorites && !c.isFavorite) {
            return false;
          }
          if (searchQueryLower.isEmpty) return true;
          return c.name.toLowerCase().contains(searchQueryLower) ||
                 c.publicKeyHex.toLowerCase().contains(searchQueryLower);
        }).toList();
        
        if (sortOption == ContactSortOption.lastSeen) {
          filtered.sort((a, b) => b.lastSeen.compareTo(a.lastSeen));
        } else {
          filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        }

        return Scaffold(
          appBar: AppBar(
            title: AppBarTitle(
              context.l10n.repeaters_title,
              subtitle: false,
              indicators: false,
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
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
                    RepeaterContactsFilterMenu(
                      sortOption: sortOption,
                      typeFilter: typeFilter,
                      onSortChanged: (val) => setState(() => sortOption = val),
                      onTypeFilterChanged: (val) => setState(() => typeFilter = val),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              Text(context.l10n.common_delete), // Or something like Delete Repeaters
                            ],
                          ),
                          onTap: () {
                            _deleteRepeaters(context, connector);
                          },
                        ),
                      ],
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
              ),
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
                          return ContactTile(
                            contact: contact,
                            lastSeen: contact.lastSeen,
                            unreadCount: connector.getUnreadCountForContact(contact),
                            isFavorite: contact.isFavorite,
                            isDiscovered: !contact.isActive,
                            onTap: () => _showRepeaterOptions(context, connector, contact),
                            onLongPress: () => _showRepeaterOptions(context, connector, contact),
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

  void _confirmDelete(
    BuildContext context,
    MeshCoreConnector connector,
    Contact contact,
  ) {
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
              connector.removeDiscoveredContact(contact);
            },
            child: Text(
              context.l10n.common_delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteRepeaters(BuildContext context, MeshCoreConnector connector) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.common_delete),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Older than 1 day'),
                onTap: () {
                  Navigator.pop(context);
                  connector.removeRepeaters(maxAge: const Duration(days: 1));
                  showDismissibleSnackBar(context, content: const Text('Deleted repeaters older than 1 day.'));
                },
              ),
              ListTile(
                title: const Text('Older than 7 days'),
                onTap: () {
                  Navigator.pop(context);
                  connector.removeRepeaters(maxAge: const Duration(days: 7));
                  showDismissibleSnackBar(context, content: const Text('Deleted repeaters older than 7 days.'));
                },
              ),
              ListTile(
                title: const Text('Older than 30 days'),
                onTap: () {
                  Navigator.pop(context);
                  connector.removeRepeaters(maxAge: const Duration(days: 30));
                  showDismissibleSnackBar(context, content: const Text('Deleted repeaters older than 30 days.'));
                },
              ),
              ListTile(
                title: const Text('All Repeaters', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  connector.removeRepeaters();
                  showDismissibleSnackBar(context, content: const Text('Deleted all repeaters.'));
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
  }
}
