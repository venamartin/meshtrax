import 'package:material_ui/material_ui.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../utils/qr_share.dart';

/// App bar button that sends a QR code and its link to another app.
class QrShareButton extends StatelessWidget {
  final String data;
  final String name;

  const QrShareButton({super.key, required this.data, required this.name});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share),
      tooltip: context.l10n.common_share,
      onPressed: () async {
        final box = context.findRenderObject() as RenderBox?;
        final origin = box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size;
        try {
          await shareQrCode(
            data: data,
            name: name,
            sharePositionOrigin: origin,
          );
        } catch (e) {
          if (context.mounted) {
            showDismissibleSnackBar(context, content: Text('$e'));
          }
        }
      },
    );
  }
}
