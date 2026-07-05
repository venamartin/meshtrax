import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MessageStatusIcon extends StatelessWidget {
  final bool isAcked;
  final bool isDelivered;
  final bool isFailed;
  final bool isChannelMessage;
  final double size;

  const MessageStatusIcon({
    super.key,
    required this.isAcked,
    this.isDelivered = false,
    this.isFailed = false,
    this.isChannelMessage = false,
    this.size = 14,
  });

  @override
  Widget build(BuildContext context) {
    if (isFailed) {
      if (isChannelMessage) {
        return Icon(Icons.check, size: size, color: Colors.amber[700]);
      }
      return Icon(Icons.cancel, size: size, color: Colors.red);
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
