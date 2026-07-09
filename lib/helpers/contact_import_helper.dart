import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';

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
    // Extract public_key via regex to avoid Uri.queryParameters emoji decode issues
    final pubKeyMatch =
        RegExp(r'[?&]public_key=([0-9a-fA-F]{64})').firstMatch(data);
    if (pubKeyMatch != null) {
      final pubKeyHex = pubKeyMatch.group(1)!;
      String name = '';
      int type = advTypeChat;
      try {
        final nameMatch = RegExp(r'[?&]name=([^&]+)').firstMatch(data);
        if (nameMatch != null) {
          name = Uri.decodeComponent(nameMatch.group(1)!);
        }
        final typeMatch = RegExp(r'[?&]type=(\d+)').firstMatch(data);
        if (typeMatch != null) {
          type = int.tryParse(typeMatch.group(1)!) ?? advTypeChat;
        }
      } catch (_) {
        // Name/type decoding failed — add with empty name
      }
      _importFromPublicKeyHex(context, pubKeyHex, name: name, type: type);
      return;
    }
    // Bare 64-char hex public key
    if (data.length == 64) {
      _importFromPublicKeyHex(context, data);
      return;
    }
    
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.contacts_invalidAdvertFormat),
    );
  }

  static void _importFromPublicKeyHex(BuildContext context, String pubKeyHex, {String name = '', int type = advTypeChat}) {
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
      final contact = Contact(
        publicKey: pubKey,
        name: name,
        type: type,
        pathLength: -1,
        path: Uint8List(0),
        lastSeen: DateTime.now(),
      );
      connector.importDiscoveredContact(contact);
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.contacts_import), // 'Import' or 'Contact imported'
      );
    } catch (e) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.contacts_invalidAdvertFormat),
      );
    }
  }
}
