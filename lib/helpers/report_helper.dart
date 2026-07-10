import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'snack_bar_builder.dart';

/// Handles reporting objectionable user-generated content.
///
/// The mesh is decentralized (there is no server to receive reports), so a
/// report opens the user's email client with a prefilled message to the
/// developer. This satisfies the "report objectionable content" requirement
/// for apps with user-generated content.
class ReportHelper {
  ReportHelper._();

  static const String _reportEmail = 'venahamtrack@gmail.com';

  static Future<void> reportMessage(
    BuildContext context, {
    required String sender,
    required String text,
    required DateTime timestamp,
  }) async {
    final body =
        'I would like to report the following message:\n\n'
        'From: $sender\n'
        'Time: ${timestamp.toIso8601String()}\n'
        'Message: $text\n\n'
        'Reason for report: ';
    final uri = Uri(
      scheme: 'mailto',
      path: _reportEmail,
      query:
          'subject=${Uri.encodeComponent('MeshTrax content report')}'
          '&body=${Uri.encodeComponent(body)}',
    );

    var launched = false;
    try {
      launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      launched = false;
    }
    if (!launched && context.mounted) {
      showDismissibleSnackBar(
        context,
        content: const Text('No email app available to send the report.'),
      );
    }
  }
}
