import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../services/region_service.dart';
import '../helpers/meshcore_qr.dart';
import '../helpers/region_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/qr_code_display.dart';
import '../widgets/qr_share_button.dart';

class ChannelShareScreen extends StatefulWidget {
  final Channel channel;

  const ChannelShareScreen({super.key, required this.channel});

  @override
  State<ChannelShareScreen> createState() => _ChannelShareScreenState();
}

class _ChannelShareScreenState extends State<ChannelShareScreen> {
  /// The switch on this screen; until it's touched, the regions setting
  /// decides.
  bool? _includeRegion;

  Channel get channel => widget.channel;

  @override
  Widget build(BuildContext context) {
    final regions = context.watch<RegionService?>();
    final own = regions?.regionOf(channel.idKey);
    final region = RegionHelper.isRegionName(own) ? own : null;
    final include =
        region != null && (_includeRegion ?? regions!.regionsInQr);
    final shared = include ? region : null;
    final qrData = MeshCoreQr.encodeChannel(
      channel.name,
      channel.pskHex,
      region: shared,
    );

    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(context.l10n.channels_shareChannel),
        centerTitle: true,
        actions: [QrShareButton(data: qrData, name: channel.name)],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              QrCodeDisplay(
                data: qrData,
                size: 300,
                title: channel.name,
                instructions: context.l10n.channels_shareChannelInstructions,
                padding: EdgeInsets.zero,
              ),
              if (region != null) ...[
                const SizedBox(height: 16),
                SwitchListTile(
                  secondary: const Icon(Icons.hexagon_outlined),
                  title: Text(context.l10n.channelRegion_qrInclude(region)),
                  value: include,
                  onChanged: (on) => setState(() => _includeRegion = on),
                ),
              ],

              const SizedBox(height: 32),
              _buildSecretKeyCard(context, channel.pskHex),

              const SizedBox(height: 16),
              _buildUriCard(context, qrData),
              const SizedBox(height: 16),
              Text(
                context.l10n.channels_shareChannelWarning,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecretKeyCard(BuildContext context, String secretKey) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.channels_secretKey,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    secretKey,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: secretKey));
                    showDismissibleSnackBar(
                      context,
                      content: Text(context.l10n.common_copiedToClipboard),
                    );
                  },
                  tooltip: context.l10n.common_copyToClipboard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUriCard(BuildContext context, String uri) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.channels_meshcoreUri,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    uri,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: uri));
                    showDismissibleSnackBar(
                      context,
                      content: Text(context.l10n.common_copiedToClipboard),
                    );
                  },
                  tooltip: context.l10n.common_copyToClipboard,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
