import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../services/photo_reports.dart';
import '../services/photo_store.dart';
import '../services/report_inbox.dart';

/// Asks whether to report a received photo (and block its sender), then
/// hides it at once and sends the report to the MeshTrax report inbox, from
/// inside the app: now, or when there's internet.
Future<void> reportPhoto(
  BuildContext context, {
  required String messageId,
  required String sender,
  required DateTime photoTime,
}) async {
  final l10n = context.l10n;
  final store = PhotoStore.instance;
  final record = store.recordFor(messageId);
  final choice = await showDialog<_ReportChoice>(
    context: context,
    builder: (context) => _ReportDialog(
      sender: sender,
      hasCode: store.codeFor(messageId) != null,
    ),
  );
  if (choice == null || !context.mounted) return;
  final code = choice.includePhoto ? store.codeFor(messageId) : null;
  final report = PhotoReport(
    id: newReportId(),
    madeAt: DateTime.now(),
    sender: sender,
    photoTime: photoTime,
    bytes: record?.bytes ?? 0,
    flaggedByCheck: record?.flagged == true,
    code: code == null ? null : base64Encode(code),
    reason: choice.reason,
  );
  // Kept first: hiding the photo deletes its code.
  await PhotoReports.instance.add(report);
  await store.markReported(messageId);
  if (choice.block && context.mounted) {
    await context.read<AppSettingsService>().blockSender(sender);
  }
  final sent = await PhotoReports.instance.send(report);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(sent ? l10n.photo_reportedSent : l10n.photo_reportedQueued),
    ),
  );
}

typedef _ReportChoice = ({String reason, bool includePhoto, bool block});

/// The report's questions. It scrolls, so with the keyboard up for the
/// reason the boxes below it can still be reached.
class _ReportDialog extends StatefulWidget {
  final String sender;
  final bool hasCode;

  const _ReportDialog({required this.sender, required this.hasCode});

  @override
  State<_ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<_ReportDialog> {
  final _reason = TextEditingController();
  var _includePhoto = false;
  var _block = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.photo_reportTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.photo_reportBody),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            maxLength: 500,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.photo_reportReason,
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _includePhoto,
            onChanged: widget.hasCode
                ? (v) => setState(() => _includePhoto = v ?? false)
                : null,
            title: Text(l10n.photo_reportInclude),
            subtitle: Text(l10n.photo_reportIncludeHint),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            value: _block,
            onChanged: (v) => setState(() => _block = v ?? false),
            title: Text(l10n.photo_block(widget.sender)),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop<_ReportChoice>((
            reason: _reason.text.trim(),
            includePhoto: _includePhoto,
            block: _block,
          )),
          child: Text(l10n.photo_report),
        ),
      ],
    );
  }
}
