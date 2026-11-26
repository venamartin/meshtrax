import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../screens/channel_chat_screen.dart';
import '../services/region_service.dart';
import 'meshcore_qr.dart';
import 'snack_bar_builder.dart';

/// Joins a channel from a `meshcore://channel/add` link: confirm, take the
/// first free slot, write it to the radio and open the chat. Already in the
/// channel: just open it.
class ChannelJoinHelper {
  /// The first unused slot, or null when the radio is full.
  static int? nextFreeSlot(MeshCoreConnector connector) {
    final used = connector.channels.map((c) => c.index).toSet();
    for (var i = 0; i < connector.maxChannels; i++) {
      if (!used.contains(i)) return i;
    }
    return null;
  }

  static Future<void> joinFromLink(BuildContext context, String url) async {
    final data = MeshCoreQr.parseChannelQr(url.trim());
    if (data == null) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.community_invalidQrCode),
        backgroundColor: Colors.red,
      );
      return;
    }
    await joinChannel(
      context,
      name: data.name,
      pskHex: data.pskHex,
      region: data.region,
    );
  }

  /// [region] comes from the link; it is used only while the regions
  /// setting lets channel QR codes carry one. [confirm]: ask first; the Add
  /// page already showed the channel. [replace]: the chat takes the place
  /// of the screen it was added from.
  static Future<void> joinChannel(
    BuildContext context, {
    required String name,
    required String pskHex,
    String? region,
    bool confirm = true,
    bool replace = false,
  }) async {
    final connector = context.read<MeshCoreConnector>();
    final regions = context.read<RegionService?>();
    final takeRegion = regions?.regionsInQr == true ? region : null;
    final l10n = context.l10n;
    final wanted = pskHex.toLowerCase();
    final existing = connector.channels
        .where((c) => c.idKey.toLowerCase() == wanted)
        .toList();
    if (existing.isNotEmpty) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.link_alreadyJoined(existing.first.displayName)),
      );
      // Tapped inside that very chat: stay put, don't stack a second copy.
      final here = context.findAncestorWidgetOfExactType<ChannelChatScreen>();
      if (here != null && here.channel.idKey.toLowerCase() == wanted) return;
      _open(context, existing.first, replace: replace);
      return;
    }

    final confirmed = !confirm || await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.channels_addChannel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.link_joinChannelBody(name)),
            const SizedBox(height: 8),
            Text(
              'Secret: ${pskHex.substring(0, 8)}...',
              style: TextStyle(fontFamily: 'monospace', color: Colors.grey[600]),
            ),
            if (takeRegion != null) ...[
              const SizedBox(height: 8),
              Text(l10n.channelRegion_qrLine(takeRegion)),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.common_add),
          ),
        ],
      ),
    ) == true;
    if (!confirmed || !context.mounted) return;

    final slot = nextFreeSlot(connector);
    if (slot == null) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.channels_noAvailableChannelSlots),
        backgroundColor: Colors.red,
      );
      return;
    }
    final psk = hex2Uint8List(pskHex);
    if (takeRegion != null) await regions!.setChannelRegion(pskHex, takeRegion);
    await connector.setChannel(slot, name, psk);
    final channel = await connector.awaitChannelByPsk(psk);

    if (!context.mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(l10n.link_channelJoined(name)),
      backgroundColor: Colors.green,
    );
    if (channel != null) _open(context, channel, replace: replace);
  }

  static void _open(BuildContext context, Channel channel, {bool replace = false}) {
    final route = MaterialPageRoute<void>(
      builder: (_) => ChannelChatScreen(channel: channel),
    );
    if (replace) {
      Navigator.pushReplacement(context, route);
    } else {
      Navigator.push(context, route);
    }
  }
}
