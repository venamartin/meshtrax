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

enum RoutingMode { auto, flood, custom }

RoutingMode routingModeOf(Contact contact) {
  final override = contact.pathOverride;
  if (override == null) return RoutingMode.auto;
  if (override < 0) return RoutingMode.flood;
  return RoutingMode.custom;
}

IconData routingIconOf(Contact contact) {
  switch (routingModeOf(contact)) {
    case RoutingMode.auto:
      return Icons.auto_mode;
    case RoutingMode.flood:
      return Icons.waves;
    case RoutingMode.custom:
      return Icons.route;
  }
}

/// The one place a contact's routing is chosen: automatic (the radio's own
/// route), always flood, or a custom path. Used by every screen that sends
/// to a contact.
class RoutingDialog {
  static Future<void> show(BuildContext context, {required Contact contact}) {
    return showDialog<void>(
      context: context,
      builder: (context) => _RoutingDialog(contact: contact),
    );
  }
}

class _RoutingDialog extends StatelessWidget {
  final Contact contact;

  const _RoutingDialog({required this.contact});

  Contact _live(MeshCoreConnector connector) {
    for (final c in connector.contacts) {
      if (c.publicKeyHex == contact.publicKeyHex) return c;
    }
    return contact;
  }

  String _routeLabel(BuildContext context, Contact c) {
    final l10n = context.l10n;
    if (c.pathLength < 0) return l10n.routing_noRoute;
    if (c.pathLength == 0) return l10n.chat_direct;
    final hops = PathHelper.formatPathHex(c.path, stride: c.pathHashSize);
    return '${l10n.chat_hopsCount(c.pathLength)} · $hops';
  }

  String? _customLabel(BuildContext context, Contact c) {
    if (routingModeOf(c) != RoutingMode.custom) return null;
    final bytes = c.pathOverrideBytes;
    if (c.pathOverride == 0 || bytes == null || bytes.isEmpty) {
      return context.l10n.chat_direct;
    }
    return PathHelper.formatPathHex(
      bytes,
      stride: context.read<MeshCoreConnector>().pathHashByteWidth,
    );
  }

  void _showFullPath(BuildContext context, Contact c) {
    final connector = context.read<MeshCoreConnector>();
    final l10n = context.l10n;
    final pathBytes = c.path;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.chat_fullPath),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              PathHelper.formatPathHex(pathBytes, stride: c.pathHashSize),
            ),
            const SizedBox(height: 8),
            SelectableText(
              PathHelper.resolvePathNames(
                pathBytes,
                connector.allContacts,
                stride: c.pathHashSize,
              ),
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
                  targetContact: c,
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

  Future<void> _pickCustomPath(
    BuildContext context,
    MeshCoreConnector connector,
    Contact c,
  ) async {
    if (c.pathLength > 0 && c.path.isEmpty && connector.isConnected) {
      connector.getContacts();
    }
    final current = c.pathOverrideBytes != null
        ? PathHelper.formatPathHex(
            c.pathOverrideBytes!,
            stride: connector.pathHashByteWidth,
          )
        : c.pathFormattedIdList(connector.pathHashByteWidth);
    final result = await PathSelectionDialog.show(
      context,
      availableContacts: connector.allContacts
          .where((x) => x.publicKeyHex != c.publicKeyHex)
          .toList(),
      initialPath: current.isEmpty ? null : current,
      currentPathLabel: c.pathLabel,
      onRefresh: connector.isConnected ? connector.getContacts : null,
      pathHashByteWidth: connector.pathHashByteWidth,
    );
    if (result == null) return;
    if (result.isEmpty) {
      await connector.setPathOverride(c, pathLen: 0, pathBytes: Uint8List(0));
    } else {
      await connector.setPathOverride(c, pathBytes: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Consumer<MeshCoreConnector>(
      builder: (context, connector, _) {
        final c = _live(connector);
        final mode = routingModeOf(c);
        final customLabel = _customLabel(context, c);

        Future<void> select(RoutingMode? next) async {
          switch (next) {
            case RoutingMode.auto:
              await connector.setPathOverride(c, pathLen: null);
            case RoutingMode.flood:
              await connector.setPathOverride(c, pathLen: -1);
            case RoutingMode.custom:
              await _pickCustomPath(context, connector, c);
            case null:
              break;
          }
        }

        return AlertDialog(
          title: Text(l10n.routing_title),
          contentPadding: const EdgeInsets.fromLTRB(0, 16, 0, 0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: InkWell(
                    onTap: c.pathLength > 0 && c.path.isNotEmpty
                        ? () => _showFullPath(context, c)
                        : null,
                    child: Text(
                      l10n.routing_route(_routeLabel(context, c)),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                RadioGroup<RoutingMode>(
                  groupValue: mode,
                  onChanged: select,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RadioListTile<RoutingMode>(
                        value: RoutingMode.auto,
                        title: Text(l10n.routing_auto),
                        subtitle: Text(l10n.routing_autoSubtitle),
                      ),
                      RadioListTile<RoutingMode>(
                        value: RoutingMode.flood,
                        title: Text(l10n.routing_flood),
                        subtitle: Text(l10n.routing_floodSubtitle),
                      ),
                      RadioListTile<RoutingMode>(
                        value: RoutingMode.custom,
                        title: Text(l10n.routing_custom),
                        subtitle:
                            Text(customLabel ?? l10n.routing_customSubtitle),
                        secondary: mode == RoutingMode.custom
                            ? IconButton(
                                icon: const Icon(Icons.edit),
                                tooltip: l10n.routing_custom,
                                onPressed: () =>
                                    _pickCustomPath(context, connector, c),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: c.pathLength < 0
                  ? null
                  : () async {
                      await connector.clearContactPath(c);
                      if (!context.mounted) return;
                      showDismissibleSnackBar(
                        context,
                        content: Text(l10n.routing_forgetDone),
                        duration: const Duration(seconds: 2),
                      );
                    },
              child: Text(l10n.routing_forget),
            ),
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
