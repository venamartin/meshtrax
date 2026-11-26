import 'package:material_ui/material_ui.dart';

import '../helpers/add_input.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/qr_scanner_widget.dart';

/// Scans a contact or channel QR code, any format the Add page reads, and
/// returns what it holds to the caller.
class QrImportScannerScreen extends StatefulWidget {
  const QrImportScannerScreen({super.key});

  @override
  State<QrImportScannerScreen> createState() => _QrImportScannerScreenState();
}

class _QrImportScannerScreenState extends State<QrImportScannerScreen> {
  bool _done = false;

  void _scanned(String data) {
    if (_done) return;
    setState(() => _done = true);
    Navigator.pop(context, data);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.channels_scanQrCode),
        centerTitle: true,
      ),
      body: _done
          ? const Center(child: CircularProgressIndicator())
          : QrScannerWidget(
              onScanned: _scanned,
              validator: (data) => AddInput.read(data) != null,
              onValidationFailed: (_) => showDismissibleSnackBar(
                context,
                content: Text(l10n.add_scanUnreadable),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
              instructions: l10n.add_scanInstructions,
            ),
    );
  }
}
