import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../screens/chat_screen.dart';

import 'meshcore_qr.dart';
import 'snack_bar_builder.dart';

class ContactImportHelper {
  static Future<void> importFromClipboard(BuildContext context) async {
    final clipboardData = await Clipboard.getData('text/plain');
    if (clipboardData == null || clipboardData.text == null) {
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_invalidAdvertFormat),
        );
      }
      return;
    }
    final text = clipboardData.text!.trim();
    if (text.isEmpty) {
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_invalidAdvertFormat),
        );
      }
      return;
    }
    if (context.mounted) importFromScannedData(context, text);
  }

  static void importFromScannedData(BuildContext context, String data) {
    final link = MeshCoreQr.parseContactParams(data);
    if (link != null) {
      unawaited(_importFromPublicKeyHex(context, link.pubKeyHex,
          name: link.name, type: link.type));
      return;
    }
    // Bare 64-char hex public key
    if (data.length == 64) {
      unawaited(_importFromPublicKeyHex(context, data));
      return;
    }
    
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.contacts_invalidAdvertFormat),
    );
  }

  /// A room, new or already saved, then opens through its password prompt.
  static Future<void> _importFromPublicKeyHex(BuildContext context, String pubKeyHex, {String name = '', int type = advTypeChat}) async {
    final connector = context.read<MeshCoreConnector>();
    try {
      final pubKey = hex2Uint8List(pubKeyHex);
      if (pubKey.length != 32) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_invalidAdvertFormat),
        );
        return;
      }
      // The radio applies an import in place: a blank record built from a
      // scanned key would wipe a saved contact's route, flags, location,
      // name and type.
      final hexLower = pubKeyHex.toLowerCase();
      Contact? savedWithKey() => connector.contacts
          .where((c) => c.publicKeyHex.toLowerCase() == hexLower)
          .firstOrNull;
      final saved = savedWithKey();
      if (saved != null) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_alreadyInContacts(saved.name)),
        );
        if (saved.type == advTypeRoom) ChatScreen.open(context, saved);
        return;
      }
      // Already heard on air: its own advert's name, type and position
      // beat what the link says.
      final heard = connector.discoveredContacts
          .where((c) => c.publicKeyHex.toLowerCase() == hexLower)
          .firstOrNull;
      final contact = heard ??
          Contact(
            publicKey: pubKey,
            name: name,
            type: type,
            pathLength: -1,
            path: Uint8List(0),
            pathHashSize: connector.pathHashByteWidth,
            lastSeen: DateTime.now(),
          );
      // Advert time 0: the radio drops any advert no newer than the one it
      // holds, so "now" would keep a room's real advert (name, position)
      // out until its clock passed this moment.
      final ok = await connector.importDiscoveredContact(
        contact,
        lastAdvertEpochSeconds: 0,
      );
      if (!ok || !context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.contacts_contactImported),
      );
      final added = savedWithKey();
      if (added != null && added.type == advTypeRoom) {
        ChatScreen.open(context, added);
      }
    } catch (e) {
      if (!context.mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.contacts_invalidAdvertFormat),
      );
    }
  }
}
