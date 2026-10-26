import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// What to delete from a chat: the messages older than [olderThan], or all
/// of them when it is null.
class ClearChatChoice {
  final Duration? olderThan;
  const ClearChatChoice(this.olderThan);
}

/// Asks how much of a chat's history to delete on this device. Picking an
/// option closes the dialog with it; Cancel returns null.
class ClearChatDialog extends StatelessWidget {
  const ClearChatDialog({super.key});

  static Future<ClearChatChoice?> show(BuildContext context) =>
      showDialog<ClearChatChoice>(
        context: context,
        builder: (_) => const ClearChatDialog(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    Widget option(String label, Duration? olderThan, {Color? color}) =>
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            olderThan == null ? Icons.delete_sweep : Icons.history,
            color: color,
          ),
          title: Text(label, style: TextStyle(color: color)),
          onTap: () => Navigator.pop(context, ClearChatChoice(olderThan)),
        );
    return AlertDialog(
      title: Text(l10n.contact_clearChat),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.clearChat_body),
            const SizedBox(height: 8),
            option(l10n.clearChat_olderThanDay, const Duration(days: 1)),
            option(l10n.clearChat_olderThanWeek, const Duration(days: 7)),
            option(l10n.clearChat_olderThanMonth, const Duration(days: 30)),
            option(l10n.clearChat_everything, null, color: Colors.red),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
      ],
    );
  }
}
