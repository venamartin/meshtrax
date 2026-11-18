import 'package:material_ui/material_ui.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../l10n/l10n.dart';

class MessageStatusIcon extends StatelessWidget {
  final bool isAcked;
  final bool isDelivered;
  final bool isFailed;
  final bool isUnheard;
  final double size;

  const MessageStatusIcon({
    super.key,
    required this.isAcked,
    this.isDelivered = false,
    this.isFailed = false,
    this.isUnheard = false,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (isFailed) {
      return Icon(Icons.cancel, size: size, color: Colors.red);
    }

    if (isUnheard) {
      return Tooltip(
        message: context.l10n.chat_channelNoSign,
        child: Icon(Icons.check, size: size, color: Colors.amber[700]),
      );
    }

    if (isDelivered) {
      return SvgPicture.asset(
        'assets/icons/done_all.svg',
        width: size,
        height: size,
        colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn),
      );
    }

    if (isAcked) {
      return Icon(Icons.check, size: size, color: Colors.grey[600]);
    }

    return Icon(Icons.schedule, size: size, color: Colors.grey[600]);
  }
}
