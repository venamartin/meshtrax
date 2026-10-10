import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/repeater_command_service.dart';
import '../helpers/snack_bar_builder.dart';

class _AclEntry {
  final Uint8List prefix;
  final int permissions;
  final Contact? contact;

  _AclEntry({required this.prefix, required this.permissions, this.contact});

  int get role => permissions & 0x3;
}

/// Admin view of a room server's access list, with role changes through the
/// `setperm` command. The server only shares its ADMIN entries — members who
/// joined with the room password are not listed.
class RoomUsersScreen extends StatefulWidget {
  final Contact room;
  final String password;

  const RoomUsersScreen({
    super.key,
    required this.room,
    required this.password,
  });

  @override
  State<RoomUsersScreen> createState() => _RoomUsersScreenState();
}

class _RoomUsersScreenState extends State<RoomUsersScreen> {
  late final MeshCoreConnector _connector;
  late final RepeaterCommandService _service;
  StreamSubscription<Uint8List>? _frameSubscription;
  List<_AclEntry> _entries = const [];
  bool _isLoading = true;
  String? _error;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _connector = context.read<MeshCoreConnector>();
    _service = RepeaterCommandService(_connector);
    _frameSubscription = _connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      if (frame[0] != respCodeContactMsgRecv &&
          frame[0] != respCodeContactMsgRecvV3) {
        return;
      }
      final parsed = parseContactMessageText(frame);
      if (parsed == null) return;
      if (!_matchesRoomPrefix(parsed.senderPrefix)) return;
      _service.handleResponse(widget.room, parsed.text);
    });
    _loadAccessList();
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _service.dispose();
    super.dispose();
  }

  bool _matchesRoomPrefix(Uint8List prefix) {
    final target = widget.room.publicKey;
    if (target.length < 6 || prefix.length < 6) return false;
    for (int i = 0; i < 6; i++) {
      if (prefix[i] != target[i]) return false;
    }
    return true;
  }

  bool _prefixMatches(Uint8List key, Uint8List prefix) {
    if (key.length < prefix.length) return false;
    for (int i = 0; i < prefix.length; i++) {
      if (key[i] != prefix[i]) return false;
    }
    return true;
  }

  Contact? _resolveByPrefix(Uint8List prefix) {
    for (final c in _connector.allContactsUnfiltered) {
      if (_prefixMatches(c.publicKey, prefix)) return c;
    }
    return null;
  }

  /// The ACL contains whoever logged in — including this radio, which is
  /// never in its own contacts list.
  bool _isSelf(Uint8List prefix) {
    final selfKey = _connector.selfPublicKey;
    return selfKey != null && _prefixMatches(selfKey, prefix);
  }

  Future<void> _loadAccessList() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final payload = await _service.sendBinaryRequest(
        widget.room,
        Uint8List.fromList([reqTypeGetAccessList, 0, 0]),
      );
      final entries = <_AclEntry>[];
      for (int i = 0; i + 7 <= payload.length; i += 7) {
        final prefix = payload.sublist(i, i + 6);
        entries.add(_AclEntry(
          prefix: prefix,
          permissions: payload[i + 6],
          contact: _resolveByPrefix(prefix),
        ));
      }
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String _roleLabel(int role) {
    switch (role) {
      case 3:
        return context.l10n.room_roleAdmin;
      case 2:
        return context.l10n.room_roleMember;
      default:
        return context.l10n.room_roleReadOnly;
    }
  }

  Future<void> _setPermission(String keyHex, int role) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      final response =
          await _service.sendCommand(widget.room, 'setperm $keyHex $role');
      if (!mounted) return;
      final failed = response.trim().toLowerCase().startsWith('err');
      showDismissibleSnackBar(
        context,
        content: Text(failed ? response : context.l10n.room_roleUpdated),
        backgroundColor: failed ? Colors.red : null,
      );
      if (!failed) await _loadAccessList();
    } catch (e) {
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.room_roleUpdateFailed),
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _pickRoleAndSet(String keyHex, {bool allowRemove = true}) async {
    final l10n = context.l10n;
    final role = await showModalBottomSheet<int>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(l10n.room_roleAdmin),
              onTap: () => Navigator.pop(sheetContext, 3),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(l10n.room_roleMember),
              onTap: () => Navigator.pop(sheetContext, 2),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: Text(l10n.room_roleReadOnly),
              onTap: () => Navigator.pop(sheetContext, 1),
            ),
            if (allowRemove)
              ListTile(
                leading: const Icon(Icons.person_remove, color: Colors.red),
                title: Text(
                  l10n.room_removeAccess,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => Navigator.pop(sheetContext, 0),
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(l10n.common_cancel),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
    if (role == null) return;
    // Demoting or removing yourself is one tap away from losing admin
    // access that only the room's own console can restore.
    if (role < 3 &&
        keyHex.toLowerCase() == _connector.selfPublicKeyHex.toLowerCase()) {
      if (!mounted) return;
      final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.room_setUserRole),
              content: Text(l10n.room_selfDemoteWarning),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.common_cancel),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(
                    l10n.common_continue,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ) ??
          false;
      if (!confirmed) return;
    }
    await _setPermission(keyHex, role);
  }

  Future<void> _addUser() async {
    final l10n = context.l10n;
    // Full 32-byte keys are required by setperm (except removal), so only
    // saved or discovered contacts qualify.
    final candidates = _connector.allContactsUnfiltered
        .where((c) =>
            c.type == advTypeChat && c.publicKey.length == pubKeySize)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (candidates.isEmpty) return;
    final picked = await showModalBottomSheet<Contact>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: candidates.length,
          itemBuilder: (context, index) {
            final contact = candidates[index];
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(contact.name),
              subtitle: Text(
                contact.shortPubKeyHex,
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () => Navigator.pop(sheetContext, contact),
            );
          },
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await _pickRoleAndSet(picked.publicKeyHex, allowRemove: false);
    // ignore: use_build_context_synchronously
    if (mounted) showDismissibleSnackBar(context, content: Text(l10n.room_usersAdminsNote));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.room_users),
            Text(
              widget.room.name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadAccessList,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isBusy ? null : _addUser,
        icon: const Icon(Icons.person_add),
        label: Text(l10n.room_setUserRole),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.room_usersAdminsNote,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.room_usersLoadFailed,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _entries.length,
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      final isSelf = _isSelf(entry.prefix);
                      final name = isSelf
                          ? (_connector.selfName ?? context.l10n.chat_me)
                          : entry.contact?.name;
                      final prefixHex =
                          pubKeyToHex(entry.prefix).toUpperCase();
                      // Only resolved contacts (or ourselves) carry the full
                      // key setperm needs; unresolved entries can still be
                      // removed by their prefix.
                      final keyHex = isSelf
                          ? _connector.selfPublicKeyHex
                          : entry.contact?.publicKeyHex ?? prefixHex;
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(
                            entry.role == 3
                                ? Icons.admin_panel_settings
                                : Icons.person,
                          ),
                        ),
                        title: Text(name ?? prefixHex),
                        subtitle:
                            Text(name == null ? '' : prefixHex),
                        trailing: Text(_roleLabel(entry.role)),
                        onTap: () => isSelf || entry.contact != null
                            ? _pickRoleAndSet(keyHex)
                            : _confirmRemoveByPrefix(prefixHex),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Future<void> _confirmRemoveByPrefix(String prefixHex) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(l10n.room_removeAccess),
            content: Text(l10n.room_removeOnlyUnknown),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.common_cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  l10n.room_removeAccess,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (confirmed) await _setPermission(prefixHex, 0);
  }
}
