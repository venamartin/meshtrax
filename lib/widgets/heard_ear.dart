import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../services/heard_service.dart';

/// A grey ear after a channel message's checkmark: observers heard it. The
/// packet path screen lists them ([HeardBySection]). Nothing at all when
/// none did.
class HeardEar extends StatelessWidget {
  const HeardEar(this.messageId, {super.key});

  final String messageId;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: HeardService.instance,
        builder: (context, _) {
          final heard = HeardService.instance.heardBy(messageId);
          if (heard == null || heard.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(left: 3),
            child: Icon(
              Icons.hearing,
              size: 14,
              color: Colors.grey[600],
              semanticLabel: context.l10n.chat_heardBy(heard.length),
            ),
          );
        },
      );
}

/// The packet path screen's list of the observers that heard a message,
/// below the path: name, direct or through how many repeaters, and
/// signal. Nothing at all when none did.
class HeardBySection extends StatelessWidget {
  const HeardBySection(this.messageId, {super.key});

  final String messageId;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: HeardService.instance,
        builder: (context, _) {
          final heard = HeardService.instance.heardBy(messageId);
          if (heard == null || heard.isEmpty) return const SizedBox.shrink();
          final l10n = context.l10n;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                l10n.chat_heardBy(heard.length),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              for (final sighting in heard)
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.hearing, color: Colors.grey[600]),
                    title: Text(sighting.observer),
                    subtitle: switch (sighting.hops) {
                      null => null,
                      0 => Text(l10n.chat_heardDirect),
                      final hops => Text(l10n.chat_heardVia(hops)),
                    },
                    trailing: sighting.snr == null
                        ? null
                        : Text('${sighting.snr!.toStringAsFixed(1)} dB'),
                  ),
                ),
            ],
          );
        },
      );
}
