import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/date_time_helper.dart';
import '../l10n/l10n.dart';
import '../screens/channel_chat_screen.dart';
import '../services/sos_service.dart';

/// The user's own SOS on the Chats and Map screens while it lasts: one line
/// on how it stands. A tap opens its chat, where its full bar has the rest.
class ActiveSosStrip extends StatelessWidget {
  const ActiveSosStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final sos = context.watch<SosService?>()?.current;
    if (sos == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final ink = scheme.onErrorContainer;
    return Material(
      color: scheme.errorContainer,
      child: InkWell(
        onTap: () => _open(context, sos),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
          child: Row(
            children: [
              Icon(Icons.warning_rounded, color: scheme.error, size: 20),
              const SizedBox(width: 10),
              // Smaller rather than cut: the time comes last.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    sos.status(
                      context.l10n,
                      (t) => DateTimeHelper.time(context, t),
                    ),
                    maxLines: 1,
                    style: TextStyle(
                      color: ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: ink, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _open(BuildContext context, ActiveSos sos) {
    final channel = context
        .read<MeshCoreConnector>()
        .channels
        .where((c) => c.idKey == sos.channelIdKey)
        .firstOrNull;
    if (channel == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChannelChatScreen(channel: channel)),
    );
  }
}
