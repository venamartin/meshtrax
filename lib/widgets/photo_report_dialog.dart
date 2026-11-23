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
  final hasCode = store.codeFor(messageId) != null;
  var includePhoto = false;
  var block = false;
  final reason = TextEditingController();
  final go = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.photo_reportTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.photo_reportBody),
            const SizedBox(height: 12),
            TextField(
              controller: reason,
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
              value: includePhoto,
              onChanged: hasCode
                  ? (v) => setState(() => includePhoto = v ?? false)
                  : null,
              title: Text(l10n.photo_reportInclude),
              subtitle: Text(l10n.photo_reportIncludeHint),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: block,
              onChanged: (v) => setState(() => block = v ?? false),
              title: Text(l10n.photo_block(sender)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.photo_report),
          ),
        ],
      ),
    ),
  );
  final why = reason.text.trim();
  reason.dispose();
  if (go != true || !context.mounted) return;
  final code = includePhoto ? store.codeFor(messageId) : null;
  final report = PhotoReport(
    id: newReportId(),
    madeAt: DateTime.now(),
    sender: sender,
    photoTime: photoTime,
    bytes: record?.bytes ?? 0,
    flaggedByCheck: record?.flagged == true,
    code: code == null ? null : base64Encode(code),
    reason: why,
  );
  // Kept first: hiding the photo deletes its code.
  await PhotoReports.instance.add(report);
  await store.markReported(messageId);
  if (block && context.mounted) {
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
