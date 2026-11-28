import 'package:material_ui/material_ui.dart';

import '../helpers/meshtrax_dm.dart';
import '../l10n/l10n.dart';
import 'meshtrax_pill.dart';

/// Under the message box of a contact whose phone runs MeshTrax: where the
/// text stands while it is typed, and which way it will go. The text is
/// packed exactly as a MeshTrax DM packs it ([MeshTraxDmText.pack]) on
/// every change, and the bytes left of [room] are shown beside a MeshTrax
/// mark; packing can make the number go up as well as down. Past the line
/// the message goes as a standard (firmware) one, and [standard], the
/// counter that way has, is shown under the words that say so.
class MeshTraxDmCounter extends StatelessWidget {
  const MeshTraxDmCounter({
    super.key,
    required this.text,
    required this.room,
    required this.standard,
  });

  final String text;

  /// The most packed bytes of text a MeshTrax DM carries.
  final int room;

  final Widget standard;

  @override
  Widget build(BuildContext context) {
    final left = room - MeshTraxDmText.pack(text).bytes.length;
    final scheme = Theme.of(context).colorScheme;
    if (left < 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            context.l10n.chat_meshTraxTooLong,
            style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
          ),
          standard,
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MeshTraxPill(),
        const SizedBox(width: 6),
        Text(
          context.l10n.chat_meshTraxBytesLeft(left),
          style: TextStyle(
            fontSize: 11,
            color: left < room * 0.1 ? Colors.orange : scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// Under a DM this phone sent to a contact on MeshTrax: the way it went,
/// as MeshTrax's own packet or as a standard (firmware) message. A message
/// can change way while it is being sent, when the other phone stops
/// answering.
class SentWayMark extends StatelessWidget {
  const SentWayMark({super.key, required this.meshTrax});

  final bool meshTrax;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      meshTrax ? 'MeshTrax' : context.l10n.chat_sentStandard,
      style: TextStyle(
        fontSize: 10,
        fontWeight: meshTrax ? FontWeight.w600 : FontWeight.w400,
        color: meshTrax ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }
}
