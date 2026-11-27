import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../services/photo_mesh.dart';

/// The photos coming in on [channel], above its message box: how many of
/// their packets came, and for one with lost packets, a button that asks its
/// sender for them ([PhotoMesh.askForRest]).
class PhotoReceivingStrip extends StatelessWidget {
  const PhotoReceivingStrip({super.key, required this.channel});

  final Channel channel;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<PhotoReceiving>>(
      valueListenable: PhotoMesh.receiving,
      builder: (context, receiving, _) {
        final here = [
          for (final r in receiving)
            if (r.key.channelIndex == channel.index) r,
        ];
        if (here.isEmpty) return const SizedBox.shrink();
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [for (final r in here) _line(context, r)],
          ),
        );
      },
    );
  }

  Widget _line(BuildContext context, PhotoReceiving r) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final id = PhotoMesh.idText(r.key.imgId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 8, 2),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                r.lost > 0
                    ? l10n.photo_receivingLost(
                        id,
                        r.senderName,
                        r.received,
                        r.total,
                        r.lost,
                      )
                    : l10n.photo_receiving(
                        id,
                        r.senderName,
                        r.received,
                        r.total,
                      ),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          if (r.canAsk)
            TextButton(
              onPressed: () => _ask(context, r),
              child: Text(l10n.photo_askForRest),
            )
          else if (r.asking || r.othersAsked || r.asked > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                r.asking
                    ? l10n.photo_asking
                    : r.othersAsked
                    ? l10n.photo_othersAsked
                    : l10n.photo_askedFor(r.asked),
                style: theme.textTheme.labelSmall,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _ask(BuildContext context, PhotoReceiving r) async {
    final messenger = ScaffoldMessenger.of(context);
    final failed = context.l10n.photo_askFailed;
    final mesh = PhotoMesh.of(context.read<MeshCoreConnector>());
    if (!await mesh.askForRest(r.key)) {
      messenger.showSnackBar(SnackBar(content: Text(failed)));
    }
  }
}
