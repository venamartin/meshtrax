import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../helpers/meshcore_qr.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';

/// A contact menu's two copies (owner, 2026-11-26): the meshcore:// link a
/// QR code carries, and the `<key:type:name>` line other apps post. [close]
/// shuts the menu; the note shows on [context], the screen under it.
List<Widget> contactCopyTiles(
  BuildContext context, {
  required String name,
  required String keyHex,
  required int type,
  required VoidCallback close,
}) {
  final l10n = context.l10n;
  void copy(String text) {
    close();
    Clipboard.setData(ClipboardData(text: text));
    showDismissibleSnackBar(
      context,
      content: Text(l10n.common_copiedToClipboard),
    );
  }

  return [
    ListTile(
      leading: const Icon(Icons.link),
      title: Text(l10n.copy_link),
      onTap: () => copy(MeshCoreQr.encodeContact(name, keyHex, type)),
    ),
    ListTile(
      leading: const Icon(Icons.short_text),
      title: Text(l10n.copy_asText),
      onTap: () => copy(MeshCoreQr.encodeContactText(name, keyHex, type)),
    ),
  ];
}
