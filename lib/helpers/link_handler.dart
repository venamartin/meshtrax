import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/l10n.dart';
import 'package:provider/provider.dart';
import '../helpers/snack_bar_builder.dart';
import '../connector/meshcore_connector.dart';
import '../models/channel.dart';
import '../screens/channel_chat_screen.dart';
import '../screens/map_screen.dart';
import '../utils/platform_info.dart';
import 'channel_join_helper.dart';
import 'contact_import_helper.dart';
import 'maps_link.dart';

/// What happens when a link, hashtag, coordinate or meshcore:// link in a
/// message is tapped.
class LinkHandler {
  static Future<void> handleHashtagTap(BuildContext context, String hashtag) async {
    final connector = context.read<MeshCoreConnector>();

    // Check if channel already exists
    final int existingIndex = connector.channels.indexWhere((c) => c.name == hashtag);
    if (existingIndex != -1) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChannelChatScreen(
              channel: connector.channels[existingIndex],
            ),
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.channels_addChannel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.channels_addChannelConfirmation,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                hashtag,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.channels_addChannel),
          ),
        ],
      ),
    );

    if (shouldAdd != true) return;
    if (!context.mounted) return;

    int nextIndex = 1;
    for (int i = 1; i < connector.maxChannels; i++) {
      if (!connector.channels.any((c) => c.index == i)) {
        nextIndex = i;
        break;
      }
    }

    final psk = Channel.derivePskFromHashtag(hashtag.substring(1));
    connector.setChannel(nextIndex, hashtag, psk);

    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.channels_channelAdded(hashtag)),
    );
  }

  static void openMapAt(BuildContext context, LatLng position, {String? label}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MapScreen(highlightPosition: position, highlightLabel: label),
      ),
    );
  }

  /// Hands [position] to the system maps app for directions. Android gets a
  /// `geo:` URI, so the user picks the app (Google Maps, OsmAnd, …).
  static Future<void> openInMapsApp(
    BuildContext context,
    LatLng position, {
    String? label,
  }) async {
    final coords = '${position.latitude},${position.longitude}';
    final String url;
    if (PlatformInfo.isAndroid) {
      final name = label == null || label.isEmpty
          ? ''
          : '(${Uri.encodeComponent(label)})';
      url = 'geo:$coords?q=$coords$name';
    } else if (PlatformInfo.isIOS || PlatformInfo.isMacOS) {
      url = 'https://maps.apple.com/?daddr=$coords';
    } else {
      url = 'https://www.google.com/maps/dir/?api=1&destination=$coords';
    }
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    ).catchError((_) => false);
    if (!opened && context.mounted) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_couldNotOpenLink(url)),
        backgroundColor: Colors.red,
      );
    }
  }

  /// `meshcore://channel/add` joins the channel, `meshcore://contact/add`
  /// imports the contact, room or repeater.
  static Future<void> handleMeshCoreLink(BuildContext context, String url) async {
    if (url.startsWith('meshcore://channel/add')) {
      await ChannelJoinHelper.joinFromLink(context, url);
    } else {
      ContactImportHelper.importFromScannedData(context, url);
    }
  }

  static Future<void> handleLinkTap(BuildContext context, String url) async {
    // A maps link with coordinates opens our map, not the browser; a contact
    // share link imports the contact.
    final maps = MapsLink.isMapsUrl(url) ? MapsLink.parse(url) : null;
    if (maps != null) {
      openMapAt(context, maps.position, label: maps.name);
      return;
    }
    if (url.contains('?public_key=') || url.contains('&public_key=')) {
      ContactImportHelper.importFromScannedData(context, url);
      return;
    }

    // Show confirmation dialog
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.chat_openLink),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.chat_openLinkConfirmation,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.chat_open),
          ),
        ],
      ),
    );

    if (shouldOpen != true) return;

    // Launch URL
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          showDismissibleSnackBar(
            context,
            content: Text(context.l10n.chat_couldNotOpenLink(url)),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.chat_invalidLink),
          backgroundColor: Colors.red,
        );
      }
    }
  }
}
