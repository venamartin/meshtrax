import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:meshtrax/screens/path_trace_map.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../helpers/path_helper.dart';
import '../helpers/snack_bar_builder.dart';
import 'path_selection_dialog.dart';

class PathManagementDialog {
  static Future<void> show(BuildContext context, {required Contact contact}) {
    return showDialog<void>(
      context: context,
      builder: (context) => _PathManagementDialog(contact: contact),
    );
  }
}

class _PathManagementDialog extends StatefulWidget {
  final Contact contact;

  const _PathManagementDialog({required this.contact});

  @override
  State<_PathManagementDialog> createState() => _PathManagementDialogState();
}

class _PathManagementDialogState extends State<_PathManagementDialog> {
  int _resolveContactIndex = -1;

  Contact _resolveContact(MeshCoreConnector connector) {
    if (_resolveContactIndex >= 0 &&
        _resolveContactIndex < connector.contacts.length &&
        connector.contacts[_resolveContactIndex].publicKeyHex ==
            widget.contact.publicKeyHex) {
      return connector.contacts[_resolveContactIndex];
    }
    _resolveContactIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.contact.publicKeyHex,
    );
    if (_resolveContactIndex == -1) {
      return widget.contact;
    }
    return connector.contacts[_resolveContactIndex];
  }

  void _showFullPathDialog(BuildContext context, List<int> pathBytes) {
    final l10n = context.l10n;
    if (pathBytes.isEmpty) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.chat_pathDetailsNotAvailable),
        duration: const Duration(seconds: 2),
      );
      return;
    }

    final connector = context.read<MeshCoreConnector>();
    final allContacts = connector.allContacts;

    final formattedPath = PathHelper.formatPathHex(pathBytes);
    final resolvedNames = PathHelper.resolvePathNames(pathBytes, allContacts);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chat_fullPath),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(formattedPath),
            const SizedBox(height: 8),
            SelectableText(
              resolvedNames,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PathTraceMapScreen(
                  title: context.l10n.contacts_repeaterPathTrace,
                  path: Uint8List.fromList(pathBytes),
                  flipPathAround: true,
                  targetContact: widget.contact,
                  pathHashByteWidth: connector.pathHashByteWidth,
                ),
              ),
            ),
            child: Text(context.l10n.contacts_pathTrace),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_close),
          ),
        ],
      ),
    );
  }

  Future<void> _setCustomPath(
    BuildContext context,
    MeshCoreConnector connector,
    Contact currentContact,
  ) async {
    if (currentContact.pathLength > 0 &&
        currentContact.path.isEmpty &&
        connector.isConnected) {
      connector.getContacts();
    }

    final pathForInput = currentContact.pathFormattedIdList(
      connector.pathHashByteWidth,
    );
    final availableContacts = connector.allContacts
        .where((c) => c.publicKeyHex != currentContact.publicKeyHex)
        .toList();

    final result = await PathSelectionDialog.show(
      context,
      availableContacts: availableContacts,
      initialPath: pathForInput.isEmpty ? null : pathForInput,
      currentPathLabel: currentContact.pathLabel,
      onRefresh: connector.isConnected ? connector.getContacts : null,
      pathHashByteWidth: connector.pathHashByteWidth,
    );

    if (result != null && context.mounted) {
      await connector.setPathOverride(
        currentContact,
        pathBytes: result,
      );

      if (!context.mounted) return;
      final updatedContact = _resolveContact(connector);
      showDismissibleSnackBar(
        context,
        content: Text(updatedContact.pathLabel),
        duration: const Duration(seconds: 2),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final currentContact = _resolveContact(connector);
        final currentPath =
            currentContact.pathOverrideBytes ?? currentContact.path;

        return AlertDialog(
          title: Text(l10n.chat_pathManagement),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: currentPath.isEmpty
                      ? null
                      : () => _showFullPathDialog(context, currentPath),
                  child: Text(
                    l10n.path_currentPath(currentContact.pathLabel),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
                const Divider(),
                ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.purple,
                    child: Icon(Icons.edit_road, size: 16),
                  ),
                  title: Text(
                    l10n.chat_setCustomPath,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.chat_setCustomPathSubtitle,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () async {
                    await _setCustomPath(context, connector, currentContact);
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.clear_all, size: 16),
                  ),
                  title: Text(
                    l10n.chat_clearPath,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.chat_clearPathSubtitle,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () async {
                    await connector.clearContactPath(currentContact);
                    if (!context.mounted) return;
                    showDismissibleSnackBar(
                      context,
                      content: Text(l10n.chat_pathCleared),
                      duration: const Duration(seconds: 2),
                    );
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  dense: true,
                  leading: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.waves, size: 16),
                  ),
                  title: Text(
                    l10n.chat_forceFloodMode,
                    style: const TextStyle(fontSize: 14),
                  ),
                  subtitle: Text(
                    l10n.chat_floodModeSubtitle,
                    style: const TextStyle(fontSize: 11),
                  ),
                  onTap: () async {
                    await connector.setPathOverride(
                      currentContact,
                      pathLen: -1,
                    );
                    if (!context.mounted) return;
                    showDismissibleSnackBar(
                      context,
                      content: Text(l10n.chat_floodModeEnabled),
                      duration: const Duration(seconds: 2),
                    );
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_close),
            ),
          ],
        );
      },
    );
  }
}
