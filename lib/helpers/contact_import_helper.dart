import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../screens/chat_screen.dart';

import 'meshcore_qr.dart';
import 'snack_bar_builder.dart';

class ContactImportHelper {
  static void importFromScannedData(BuildContext context, String data) {
    final link = MeshCoreQr.parseContactParams(data) ??
        MeshCoreQr.parseAdvertCard(data) ??
        MeshCoreQr.parseContactText(data);
    if (link != null) {
      unawaited(_importFromPublicKeyHex(context, link.pubKeyHex,
          name: link.name,
          type: link.type,
          latitude: link.latitude,
          longitude: link.longitude));
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

  /// [data] from the Add page, imported as [importFromScannedData] does but
  /// leaving where to go next to the page: the saved contact, or null.
  static Future<Contact?> importContact(
    BuildContext context,
    ContactQrData data,
  ) =>
      _importFromPublicKeyHex(
        context,
        data.pubKeyHex,
        name: data.name,
        type: data.type,
        latitude: data.latitude,
        longitude: data.longitude,
        openRoom: false,
      );

  /// A room, new or already saved, then opens through its password prompt
  /// when [openRoom]. The saved contact, or null.
  static Future<Contact?> _importFromPublicKeyHex(BuildContext context, String pubKeyHex,
      {String name = '',
      int type = advTypeChat,
      double? latitude,
      double? longitude,
      bool openRoom = true}) async {
    final connector = context.read<MeshCoreConnector>();
    try {
      final pubKey = hex2Uint8List(pubKeyHex);
      if (pubKey.length != 32) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_invalidAdvertFormat),
        );
        return null;
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
        if (openRoom && saved.type == advTypeRoom) {
          ChatScreen.open(context, saved);
        }
        return saved;
      }
      // Already heard on air: its own advert's name, type and position
      // beat what the link says. Added now, though: the radio keeps this as
      // the contact's lastmod, and a table that is full evicts the oldest.
      final heard = connector.discoveredContacts
          .where((c) => c.publicKeyHex.toLowerCase() == hexLower)
          .firstOrNull;
      final contact = heard?.copyWith(lastSeen: DateTime.now()) ??
          Contact(
            publicKey: pubKey,
            name: name,
            type: type,
            pathLength: -1,
            path: Uint8List(0),
            pathHashSize: connector.pathHashByteWidth,
            latitude: latitude,
            longitude: longitude,
            lastSeen: DateTime.now(),
          );
      // Advert time 0: the radio drops any advert no newer than the one it
      // holds, so "now" would keep a room's real advert (name, position)
      // out until its clock passed this moment.
      final ok = await connector.importDiscoveredContact(
        contact,
        lastAdvertEpochSeconds: 0,
      );
      if (!context.mounted) return null;
      if (!ok) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.contacts_contactImportFailed),
        );
        return null;
      }
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.contacts_contactImported),
      );
      final added = savedWithKey();
      if (openRoom && added != null && added.type == advTypeRoom) {
        ChatScreen.open(context, added);
      }
      return added ?? contact;
    } catch (e) {
      if (!context.mounted) return null;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.contacts_invalidAdvertFormat),
      );
      return null;
    }
  }
}
