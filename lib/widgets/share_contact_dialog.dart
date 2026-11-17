import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/meshcore_qr.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';

/// Picks my own contact or a saved one and gives it as the
/// `<public key:type:name>` line other MeshCore apps read; null if cancelled.
Future<String?> showShareContactDialog(
  BuildContext context,
  MeshCoreConnector connector,
) {
  return showDialog<String>(
    context: context,
    builder: (_) => _ShareContactDialog(connector: connector),
  );
}

class _ShareContactDialog extends StatefulWidget {
  final MeshCoreConnector connector;

  const _ShareContactDialog({required this.connector});

  @override
  State<_ShareContactDialog> createState() => _ShareContactDialogState();
}

class _ShareContactDialogState extends State<_ShareContactDialog> {
  String _query = '';

  static IconData _icon(int type) => switch (type) {
    advTypeRepeater => Icons.cell_tower,
    advTypeRoom => Icons.meeting_room,
    advTypeSensor => Icons.sensors,
    _ => Icons.person,
  };

  void _pick(String name, String keyHex, int type) =>
      Navigator.pop(context, MeshCoreQr.encodeContactText(name, keyHex, type));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = widget.connector;
    final selfKey = connector.selfPublicKeyHex;
    final selfName = connector.selfName ?? connector.deviceDisplayName;
    final query = _query.trim().toLowerCase();
    final contacts =
        connector.contacts
            .where((c) => c.publicKeyHex != selfKey)
            .where((c) => query.isEmpty || c.name.toLowerCase().contains(query))
            .toList()
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final showSelf =
        selfKey.isNotEmpty &&
        (query.isEmpty || selfName.toLowerCase().contains(query));
    // An explicit size: an AlertDialog asks its content for an intrinsic
    // width, which a ListView can't answer.
    final size = MediaQuery.sizeOf(context);
    final width = math.min(size.width - 80, 480.0);

    Widget tile(Contact c) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(_icon(c.type)),
      title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => _pick(c.name, c.publicKeyHex, c.type),
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      titleTextStyle: Theme.of(context).textTheme.titleLarge,
      title: Row(
        children: [
          const Icon(Icons.contact_page),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.shareContact_title)),
        ],
      ),
      content: SizedBox(
        width: width,
        height: math.min(size.height * 0.5, 420),
        child: Column(
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: l10n.listFilter_searchHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: !showSelf && contacts.isEmpty
                  ? Center(child: Text(l10n.chat_searchNoMatches))
                  : ListView(
                      children: [
                        if (showSelf)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(Icons.account_circle),
                            title: Text(l10n.shareContact_myContact),
                            subtitle: Text(
                              selfName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _pick(selfName, selfKey, advTypeChat),
                          ),
                        if (showSelf && contacts.isNotEmpty) const Divider(),
                        for (final c in contacts) tile(c),
                      ],
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
      ],
    );
  }
}
