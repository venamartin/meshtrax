import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meshtrax/screens/path_trace_map.dart';
import 'package:meshtrax/services/notification_service.dart';
import 'package:meshtrax/utils/app_logger.dart';
import 'package:meshtrax/widgets/app_bar.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import '../models/contact_group.dart';
import '../services/ui_view_state_service.dart';
import '../utils/contact_search.dart';
import '../storage/contact_group_store.dart';
import '../utils/dialog_utils.dart';
import '../utils/disconnect_navigation_mixin.dart';
import '../utils/route_transitions.dart';
import '../utils/telemetry_dialog.dart';
import '../widgets/contact_tile.dart';
import '../widgets/empty_state.dart';
import '../widgets/list_filter_widget.dart';
import '../widgets/quick_switch_bar.dart';
import '../widgets/repeater_login_dialog.dart';
import '../widgets/room_login_dialog.dart';
import '../helpers/contact_import_helper.dart';
import '../helpers/snack_bar_builder.dart';
import 'chat_screen.dart';
import 'contact_qr_scanner_screen.dart';
import 'contact_share_screen.dart';
import '../helpers/meshcore_qr.dart';
import 'chats_screen.dart';
import 'discovery_screen.dart';
import 'map_screen.dart';
import 'repeater_hub_screen.dart';
import 'settings_screen.dart';

enum RoomLoginDestination { chat, management }

enum ContactOperationType { import, zeroHopShare }

class ContactsScreen extends StatefulWidget {
  final bool hideBackButton;

  const ContactsScreen({super.key, this.hideBackButton = false});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with DisconnectNavigationMixin {
  final TextEditingController _searchController = TextEditingController();
  final ContactGroupStore _groupStore = ContactGroupStore();
  MeshCoreConnector? _scopeSyncConnector;
  List<ContactGroup> _groups = [];
  String _loadedGroupScopeKeyHex = '';
  Timer? _searchDebounce;

  final Set<ContactOperationType> _pendingOperations = {};

  StreamSubscription<Uint8List>? _frameSubscription;

  @override
  void initState() {
    super.initState();
    _searchController.text = context
        .read<UiViewStateService>()
        .contactsSearchText;
    _loadGroups();
    _setupFrameListener();
    _clearAdvertNotifications();
  }

  void _clearAdvertNotifications() {
    final connector = context.read<MeshCoreConnector>();
    final contactIds = connector.contacts.map((c) => c.publicKeyHex).toList();
    NotificationService().clearAdvertNotifications(contactIds);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final connector = context.read<MeshCoreConnector>();
    if (!identical(_scopeSyncConnector, connector)) {
      _scopeSyncConnector?.removeListener(_handleConnectorScopeChange);
      _scopeSyncConnector = connector;
      _scopeSyncConnector?.addListener(_handleConnectorScopeChange);
    }
    _handleConnectorScopeChange();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _frameSubscription?.cancel();
    _scopeSyncConnector?.removeListener(_handleConnectorScopeChange);
    super.dispose();
  }

  void _handleConnectorScopeChange() {
    final connector = _scopeSyncConnector;
    if (connector == null) return;
    _syncGroupScopeIfNeeded(connector);
  }

  Future<void> _loadGroups() async {
    final selfPublicKeyHex = context.read<MeshCoreConnector>().selfPublicKeyHex;
    if (selfPublicKeyHex.isEmpty) {
      return;
    }
    _groupStore.setPublicKeyHex = selfPublicKeyHex;
    final groups = await _groupStore.loadGroups();
    if (!mounted) return;
    setState(() {
      _loadedGroupScopeKeyHex = selfPublicKeyHex;
      _groups = groups;
      _ensureValidSelectedGroup();
    });
  }

  Future<void> _saveGroups() async {
    final selfPublicKeyHex = context.read<MeshCoreConnector>().selfPublicKeyHex;
    if (selfPublicKeyHex.isEmpty) {
      return;
    }
    _groupStore.setPublicKeyHex = selfPublicKeyHex;
    await _groupStore.saveGroups(_groups);
  }

  bool _hasGroupStoreScope(MeshCoreConnector connector) {
    return connector.selfPublicKeyHex.isNotEmpty;
  }

  void _syncGroupScopeIfNeeded(MeshCoreConnector connector) {
    final selfPublicKeyHex = connector.selfPublicKeyHex;
    if (selfPublicKeyHex.isEmpty ||
        selfPublicKeyHex == _loadedGroupScopeKeyHex) {
      return;
    }
    _loadGroups();
  }

  void _collapseContactsSearch(UiViewStateService viewState) {
    _searchDebounce?.cancel();
    _searchDebounce = null;
    _searchController.clear();
    viewState.setContactsSearchText('');
    viewState.setContactsSearchExpanded(false);
  }

  void _showGroupsUnavailableMessage(BuildContext context) {
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.common_loading),
    );
  }

  void _setupFrameListener() {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    // Listen for incoming text messages from the repeater
    _frameSubscription = connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      final frameBuffer = BufferReader(frame);
      try {
        final code = frameBuffer.readUInt8();


        if (code == respCodeOk) {
          // Show a snackbar indicating success
          if (!mounted) return;

          if (_pendingOperations.contains(ContactOperationType.import)) {
            showDismissibleSnackBar(
              context,
              content: Text(context.l10n.contacts_contactImported),
            );
          }

          if (_pendingOperations.contains(ContactOperationType.zeroHopShare)) {
            showDismissibleSnackBar(
              context,
              content: Text(context.l10n.contacts_zeroHopContactAdvertSent),
            );
          }


          _pendingOperations.clear();
        }

        if (code == respCodeErr) {
          // Show a snackbar indicating failure
          if (!mounted) return;

          if (_pendingOperations.contains(ContactOperationType.import)) {
            showDismissibleSnackBar(
              context,
              content: Text(context.l10n.contacts_contactImportFailed),
            );
          }

          if (_pendingOperations.contains(ContactOperationType.zeroHopShare)) {
            showDismissibleSnackBar(
              context,
              content: Text(context.l10n.contacts_zeroHopContactAdvertFailed),
            );
          }

          _pendingOperations.clear();
        }
      } catch (e) {
        appLogger.error(
          'Error processing received frame: $e',
          tag: 'ContactsScreen',
        );
      }
    });
  }

  Future<void> _contactZeroHop(Uint8List pubKey) async {
    final connector = Provider.of<MeshCoreConnector>(context, listen: false);
    final exportContactZeroHopFrame = buildZeroHopContact(pubKey);
    _pendingOperations.add(ContactOperationType.zeroHopShare);
    await connector.sendFrame(
      exportContactZeroHopFrame,
      expectsGenericAck: true,
    );
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

  @override
  Widget build(BuildContext context) {
    final connector = context.watch<MeshCoreConnector>();

    // Auto-navigate back to scanner if disconnected
    if (!checkConnectionAndNavigate(connector)) {
      return const SizedBox.shrink();
    }

    final allowBack = !connector.isConnected;
    return PopScope(
      canPop: allowBack,
      child: Scaffold(
        appBar: AppBar(
          title: AppBarTitle(context.l10n.contacts_title),
          automaticallyImplyLeading: false,
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
                  onTap: () => _disconnect(context, connector),
                ),
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_rounded),
                      const SizedBox(width: 8),
                      Text(context.l10n.discoveredContacts_Title),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DiscoveryScreen(),
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
        body: _buildContactsBody(context, connector),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showAddContactDialog(context),
          tooltip: context.l10n.contacts_addContact,
          child: const Icon(Icons.add),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: QuickSwitchBar(
            selectedIndex: 1,
            onDestinationSelected: (index) =>
                _handleQuickSwitch(index, context),
          ),
        ),
      ),
    );
  }

  Future<void> _disconnect(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    await showDisconnectDialog(context, connector);
  }

  ContactGroup? _selectedGroupForName(String selectedGroupName) {
    if (selectedGroupName == contactsAllGroupsValue) return null;
    for (final group in _groups) {
      if (group.name == selectedGroupName) return group;
    }
    return null;
  }

  void _ensureValidSelectedGroup() {
    final viewState = context.read<UiViewStateService>();
    if (viewState.contactsSelectedGroupName == contactsAllGroupsValue) return;
    final exists = _groups.any(
      (group) => group.name == viewState.contactsSelectedGroupName,
    );
    if (!exists) {
      viewState.setContactsSelectedGroupName(contactsAllGroupsValue);
    }
  }

  void _closeDropdownAndRun(BuildContext popupContext, VoidCallback action) {
    final route = ModalRoute.of(popupContext);
    if (route != null && route.isCurrent) {
      Navigator.of(popupContext).pop();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      action();
    });
  }

  Widget _buildFilterButton(
    BuildContext context,
    UiViewStateService viewState,
  ) {
    return ContactsFilterMenu(
      sortOption: viewState.contactsSortOption,
      typeFilter: viewState.contactsTypeFilter,
      showUnreadOnly: viewState.contactsShowUnreadOnly,
      onSortChanged: (value) {
        viewState.setContactsSortOption(value);
      },
      onTypeFilterChanged: (value) {
        viewState.setContactsTypeFilter(value);
      },
      onUnreadOnlyChanged: (value) {
        viewState.setContactsShowUnreadOnly(value);
      },
    );
  }

  Widget _buildGroupButton(
    BuildContext context,
    MeshCoreConnector connector,
    UiViewStateService viewState,
    List<Contact> contacts,
    List<ContactGroup> sortedGroups,
  ) {
    final canManageGroups = _hasGroupStoreScope(connector);
    final selectedGroupName =
        _selectedGroupForName(viewState.contactsSelectedGroupName)?.name ??
        context.l10n.listFilter_all;
    final double menuWidth = (MediaQuery.sizeOf(context).width - 16).clamp(
      0.0,
      double.infinity,
    );

    return PopupMenuButton<String>(
      position: PopupMenuPosition.under,
      constraints: BoxConstraints.tightFor(width: menuWidth),
      onSelected: (String value) {
        viewState.setContactsSelectedGroupName(value);
      },
      itemBuilder: (menuContext) => [
        PopupMenuItem<String>(
          value: contactsAllGroupsValue,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(menuContext.l10n.listFilter_all),
              IconButton(
                tooltip: menuContext.l10n.contacts_newGroup,
                icon: const Icon(Icons.group_add, size: 20),
                onPressed: canManageGroups
                    ? () => _closeDropdownAndRun(
                        menuContext,
                        () => _showGroupEditor(this.context, contacts),
                      )
                    : () => _closeDropdownAndRun(
                        menuContext,
                        () => _showGroupsUnavailableMessage(this.context),
                      ),
              ),
            ],
          ),
        ),
        ...sortedGroups.map((group) {
          return PopupMenuItem<String>(
            value: group.name,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(group.name, overflow: TextOverflow.ellipsis),
                ),
                IconButton(
                  tooltip: menuContext.l10n.contacts_editGroup,
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: canManageGroups
                      ? () => _closeDropdownAndRun(
                          menuContext,
                          () => _showGroupEditor(
                            this.context,
                            contacts,
                            group: group,
                          ),
                        )
                      : () => _closeDropdownAndRun(
                          menuContext,
                          () => _showGroupsUnavailableMessage(this.context),
                        ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: menuContext.l10n.contacts_deleteGroup,
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: canManageGroups
                      ? () => _closeDropdownAndRun(
                          menuContext,
                          () => _confirmDeleteGroup(this.context, group),
                        )
                      : () => _closeDropdownAndRun(
                          menuContext,
                          () => _showGroupsUnavailableMessage(this.context),
                        ),
                ),
              ],
            ),
          );
        }),
      ],
      child: SizedBox(
        height: 48,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Text(selectedGroupName, overflow: TextOverflow.ellipsis),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactsBody(BuildContext context, MeshCoreConnector connector) {
    final viewState = context.watch<UiViewStateService>();
    final contacts = connector.contacts;
    final shouldShowStartupSpinner =
        contacts.isEmpty &&
        _groups.isEmpty &&
        connector.isConnected &&
        (connector.isLoadingContacts ||
            connector.isLoadingChannels ||
            connector.selfPublicKey == null);

    if (shouldShowStartupSpinner) {
      return const Center(child: CircularProgressIndicator());
    }

    if (contacts.isEmpty && _groups.isEmpty) {
      return EmptyState(
        icon: Icons.people_outline,
        title: context.l10n.contacts_noContacts,
        subtitle: context.l10n.contacts_contactsWillAppear,
      );
    }

    final filteredAndSorted = _filterAndSortContacts(
      contacts,
      connector,
      viewState,
    );

    String hintText = "";

    switch (viewState.contactsTypeFilter) {
      case ContactTypeFilter.all:
        hintText = context.l10n.contacts_searchContacts(
          filteredAndSorted.length,
          viewState.contactsShowUnreadOnly
              ? " ${context.l10n.contacts_unread}"
              : "",
        );
        break;
      case ContactTypeFilter.users:
        hintText = context.l10n.contacts_searchUsers(
          filteredAndSorted.length,
          viewState.contactsShowUnreadOnly
              ? " ${context.l10n.contacts_unread}"
              : "",
        );
        break;
      case ContactTypeFilter.repeaters:
        hintText = context.l10n.contacts_searchRepeaters(
          filteredAndSorted.length,
          viewState.contactsShowUnreadOnly
              ? " ${context.l10n.contacts_unread}"
              : "",
        );
        break;
      case ContactTypeFilter.rooms:
        hintText = context.l10n.contacts_searchRoomServers(
          filteredAndSorted.length,
          viewState.contactsShowUnreadOnly
              ? " ${context.l10n.contacts_unread}"
              : "",
        );
        break;
      case ContactTypeFilter.favorites:
        hintText = context.l10n.contacts_searchFavorites(
          filteredAndSorted.length,
          viewState.contactsShowUnreadOnly
              ? " ${context.l10n.contacts_unread}"
              : "",
        );
        break;
    }

    final groupsByName = <String, ContactGroup>{};
    for (final group in _groups) {
      groupsByName.putIfAbsent(group.name, () => group);
    }
    final sortedGroups = groupsByName.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    final screenWidth = MediaQuery.sizeOf(context).width;
    final searchExpandedWidth = (screenWidth * 0.52).clamp(
      97.0,
      double.infinity,
    ); // allow expansion up to 52% of screen width, but not less than the collapsed width
    final searchCollapsedWidth = (screenWidth * 0.22).clamp(
      97.0,
      120.0,
    ); //two 48px icon buttons + 1px divider

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: _buildGroupButton(
                  context,
                  connector,
                  viewState,
                  contacts,
                  sortedGroups,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: viewState.contactsSearchExpanded
                    ? searchExpandedWidth
                    : searchCollapsedWidth,
                height: 48,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: viewState.contactsSearchExpanded
                            ? TextField(
                                controller: _searchController,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: hintText,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
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
                                          .setContactsSearchText(value);
                                    },
                                  );
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: IconButton(
                          onPressed: () {
                            if (viewState.contactsSearchExpanded) {
                              _collapseContactsSearch(viewState);
                              return;
                            }
                            viewState.setContactsSearchExpanded(true);
                          },
                          icon: Icon(
                            viewState.contactsSearchExpanded
                                ? Icons.close
                                : Icons.search,
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: _buildFilterButton(context, viewState),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredAndSorted.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        viewState.contactsShowUnreadOnly
                            ? context.l10n.contacts_noUnreadContacts
                            : context.l10n.contacts_noContactsFound,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => connector.getContacts(),
                  child: ListView.builder(
                    itemExtent: 88.0,
                    itemCount: filteredAndSorted.length,
                    itemBuilder: (context, index) {
                      final contact = filteredAndSorted[index];
                      final unreadCount = connector.getUnreadCountForContact(
                        contact,
                      );
                      return ContactTile(
                        contact: contact,
                        lastSeen: _resolveLastSeen(contact),
                        unreadCount: unreadCount,
                        isFavorite: contact.isFavorite,
                        onTap: () => _openChat(context, contact),
                        onLongPress: () =>
                            _showContactOptions(context, connector, contact),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  List<Contact> _filterAndSortContacts(
    List<Contact> contacts,
    MeshCoreConnector connector,
    UiViewStateService viewState,
  ) {
    var filtered = contacts.where((contact) {
      if (viewState.contactsSearchText.isEmpty) return true;
      return matchesContactQuery(contact, viewState.contactsSearchText);
    }).toList();

    final selectedGroup = _selectedGroupForName(
      viewState.contactsSelectedGroupName,
    );
    if (selectedGroup != null) {
      final memberKeys = selectedGroup.memberKeys.toSet();
      filtered = filtered
          .where((contact) => memberKeys.contains(contact.publicKeyHex))
          .toList();
    }

    // Filter out own node from the list
    if (connector.selfPublicKey != null) {
      final selfPubKeyHex = pubKeyToHex(connector.selfPublicKey!);
      filtered = filtered.where((contact) {
        return contact.publicKeyHex != selfPubKeyHex;
      }).toList();
    }

    if (viewState.contactsTypeFilter != ContactTypeFilter.all) {
      filtered = filtered
          .where(
            (contact) =>
                _matchesTypeFilter(contact, viewState.contactsTypeFilter),
          )
          .toList();
    }

    if (viewState.contactsShowUnreadOnly) {
      filtered = filtered.where((contact) {
        return connector.getUnreadCountForContact(contact) > 0;
      }).toList();
    }

    switch (viewState.contactsSortOption) {
      case ContactSortOption.lastSeen:
        filtered.sort(
          (a, b) => _resolveLastSeen(b).compareTo(_resolveLastSeen(a)),
        );
        break;
      case ContactSortOption.recentMessages:
        filtered.sort((a, b) {
          final aMessages = connector.getMessages(a);
          final bMessages = connector.getMessages(b);
          final aLastMsg = aMessages.isEmpty
              ? DateTime(1970)
              : aMessages.last.timestamp;
          final bLastMsg = bMessages.isEmpty
              ? DateTime(1970)
              : bMessages.last.timestamp;
          return bLastMsg.compareTo(aLastMsg);
        });
        break;
      case ContactSortOption.name:
        filtered.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }

    return filtered;
  }

  bool _matchesTypeFilter(Contact contact, ContactTypeFilter typeFilter) {
    switch (typeFilter) {
      case ContactTypeFilter.all:
        return true;
      case ContactTypeFilter.favorites:
        return contact.isFavorite;
      case ContactTypeFilter.users:
        return contact.type == advTypeChat;
      case ContactTypeFilter.repeaters:
        return contact.type == advTypeRepeater;
      case ContactTypeFilter.rooms:
        return contact.type == advTypeRoom;
    }
  }

  DateTime _resolveLastSeen(Contact contact) {
    if (contact.type != advTypeChat) return contact.lastSeen;
    return contact.lastMessageAt.isAfter(contact.lastSeen)
        ? contact.lastMessageAt
        : contact.lastSeen;
  }

  void _openChat(BuildContext context, Contact contact) {
    // Check if this is a repeater
    if (contact.type == advTypeRepeater) {
      _showRepeaterLogin(context, contact);
    } else if (contact.type == advTypeRoom) {
      _showRoomLogin(context, contact, RoomLoginDestination.chat);
    } else {
      final unread = context.read<MeshCoreConnector>().getUnreadCountForContactKey(contact.publicKeyHex);
      context.read<MeshCoreConnector>().markContactRead(contact.publicKeyHex);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChatScreen(contact: contact, unreadCount: unread)),
      );
    }
  }

  void _handleQuickSwitch(int index, BuildContext context) {
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        buildQuickSwitchRoute(const ChatsScreen(hideBackButton: true)),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        buildQuickSwitchRoute(const MapScreen(hideBackButton: true)),
      );
    }
  }

  void _showRepeaterLogin(BuildContext context, Contact repeater) {
    showDialog(
      context: context,
      builder: (context) => RepeaterLoginDialog(
        repeater: repeater,
        onLogin: (password, isAdmin) {
          // Navigate to repeater hub screen after successful login
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RepeaterHubScreen(
                repeater: repeater,
                password: password,
                isAdmin: isAdmin,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showRoomLogin(
    BuildContext context,
    Contact room,
    RoomLoginDestination destination,
  ) {
    showDialog(
      context: context,
      builder: (context) => RoomLoginDialog(
        room: room,
        onLogin: (password, isAdmin) {
          final unread = context.read<MeshCoreConnector>().getUnreadCountForContactKey(room.publicKeyHex);
          context.read<MeshCoreConnector>().markContactRead(room.publicKeyHex);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  destination == RoomLoginDestination.management
                  ? RepeaterHubScreen(
                      repeater: room,
                      password: password,
                      isAdmin: isAdmin,
                    )
                  : ChatScreen(contact: room, unreadCount: unread),
            ),
          );
        },
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, ContactGroup group) {
    if (!_hasGroupStoreScope(context.read<MeshCoreConnector>())) {
      _showGroupsUnavailableMessage(context);
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(context.l10n.contacts_deleteGroup),
        content: Text(context.l10n.contacts_deleteGroupConfirm(group.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.l10n.common_cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              setState(() {
                _groups.removeWhere((g) => g.name == group.name);
                _ensureValidSelectedGroup();
              });
              await _saveGroups();
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

  void _showGroupEditor(
    BuildContext context,
    List<Contact> contacts, {
    ContactGroup? group,
  }) {
    if (!_hasGroupStoreScope(context.read<MeshCoreConnector>())) {
      _showGroupsUnavailableMessage(context);
      return;
    }
    final isEditing = group != null;
    final nameController = TextEditingController(text: group?.name ?? '');
    final selectedKeys = <String>{...group?.memberKeys ?? []};
    String filterQuery = '';
    final sortedContacts = List<Contact>.from(contacts)
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) {
          final filteredContacts = filterQuery.isEmpty
              ? sortedContacts
              : sortedContacts
                    .where(
                      (contact) => matchesContactQuery(contact, filterQuery),
                    )
                    .toList();
          return AlertDialog(
            title: Text(
              isEditing
                  ? context.l10n.contacts_editGroup
                  : context.l10n.contacts_newGroup,
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: context.l10n.contacts_groupName,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      decoration: InputDecoration(
                        hintText: context.l10n.contacts_filterContacts,
                        prefixIcon: const Icon(Icons.search),
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          filterQuery = value.toLowerCase();
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: filteredContacts.isEmpty
                          ? Center(
                              child: Text(
                                context.l10n.contacts_noContactsMatchFilter,
                              ),
                            )
                          : ListView.builder(
                              itemCount: filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = filteredContacts[index];
                                final isSelected = selectedKeys.contains(
                                  contact.publicKeyHex,
                                );
                                return CheckboxListTile(
                                  value: isSelected,
                                  title: Text(contact.name),
                                  subtitle: Text(contact.typeLabel),
                                  onChanged: (value) {
                                    setDialogState(() {
                                      if (value == true) {
                                        selectedKeys.add(contact.publicKeyHex);
                                      } else {
                                        selectedKeys.remove(
                                          contact.publicKeyHex,
                                        );
                                      }
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(context.l10n.common_cancel),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) {
                    showDismissibleSnackBar(
                      context,
                      content: Text(context.l10n.contacts_groupNameRequired),
                    );
                    return;
                  }
                  if (name.toLowerCase() ==
                      contactsAllGroupsValue.toLowerCase()) {
                    showDismissibleSnackBar(
                      context,
                      content: Text(context.l10n.contacts_groupNameReserved),
                    );
                    return;
                  }
                  final exists = _groups.any((g) {
                    if (isEditing && g.name == group.name) return false;
                    return g.name.toLowerCase() == name.toLowerCase();
                  });
                  if (exists) {
                    showDismissibleSnackBar(
                      context,
                      content: Text(
                        context.l10n.contacts_groupAlreadyExists(name),
                      ),
                    );
                    return;
                  }
                  setState(() {
                    final viewState = context.read<UiViewStateService>();
                    if (isEditing) {
                      final index = _groups.indexWhere(
                        (g) => g.name == group.name,
                      );
                      if (index != -1) {
                        final wasSelected =
                            viewState.contactsSelectedGroupName == group.name;
                        _groups[index] = ContactGroup(
                          name: name,
                          memberKeys: selectedKeys.toList(),
                        );
                        if (wasSelected) {
                          viewState.setContactsSelectedGroupName(name);
                        }
                      }
                    } else {
                      _groups.add(
                        ContactGroup(
                          name: name,
                          memberKeys: selectedKeys.toList(),
                        ),
                      );
                      viewState.setContactsSelectedGroupName(name);
                    }
                    _ensureValidSelectedGroup();
                  });
                  await _saveGroups();
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                },
                child: Text(
                  isEditing
                      ? context.l10n.common_save
                      : context.l10n.common_create,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showContactOptions(
    BuildContext context,
    MeshCoreConnector connector,
    Contact contact,
  ) {
    final isRepeater = contact.type == advTypeRepeater;
    final isRoom = contact.type == advTypeRoom;
    final isFavorite = contact.isFavorite;

    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isRepeater) ...[
              ListTile(
                leading: const Icon(Icons.radar, color: Colors.green),
                title: Text(context.l10n.contacts_ping),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final hw = context
                      .read<MeshCoreConnector>()
                      .pathHashByteWidth;
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
                  _showRepeaterLogin(context, contact);
                },
              ),
            ] else if (isRoom) ...[
              ListTile(
                leading: const Icon(Icons.radar, color: Colors.green),
                title: Text(context.l10n.contacts_pathTrace),
                onTap: () {
                  Navigator.pop(sheetContext);
                  final hw = context
                      .read<MeshCoreConnector>()
                      .pathHashByteWidth;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PathTraceMapScreen(
                        title: contact.pathBytesForDisplay.isNotEmpty
                            ? context.l10n.contacts_roomPathTrace
                            : context.l10n.contacts_roomPing,
                        path: contact.pathBytesForDisplay.isNotEmpty
                            ? contact.pathBytesForDisplay
                            : contact.publicKey.sublist(0, hw),
                        flipPathAround: contact.pathBytesForDisplay.isNotEmpty,
                        targetContact: contact,
                        pathHashByteWidth: hw,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.room, color: Colors.blue),
                title: Text(context.l10n.contacts_roomLogin),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRoomLogin(context, contact, RoomLoginDestination.chat);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.room_preferences,
                  color: Colors.orange,
                ),
                title: Text(context.l10n.room_management),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _showRoomLogin(
                    context,
                    contact,
                    RoomLoginDestination.management,
                  );
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.chat),
                title: Text(context.l10n.contacts_openChat),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _openChat(context, contact);
                },
              ),
            ],
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
              onTap: () {
                Navigator.pop(sheetContext);
                _contactZeroHop(contact.publicKey);
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
                _confirmDelete(context, connector, contact);
              },
            ),
          ],
        ),
      ),
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

}
