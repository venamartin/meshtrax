import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../storage/prefs_manager.dart';

/// One-time, first-launch acceptance of the content policy / Terms of Use.
///
/// Required for a user-generated-content app: users must agree not to send
/// objectionable content before they can use the app. The acceptance is stored
/// locally so the prompt only appears once.
class TermsGate {
  TermsGate._();

  static const String _acceptedKey = 'terms_accepted_v1';

  static bool get isAccepted {
    try {
      return PrefsManager.instance.getBool(_acceptedKey) ?? false;
    } catch (_) {
      return true; // prefs unavailable (e.g. tests) — don't block.
    }
  }

  static Future<void> _setAccepted() async {
    try {
      await PrefsManager.instance.setBool(_acceptedKey, true);
    } catch (_) {}
  }

  /// Shows a non-dismissible content-policy dialog if the user hasn't accepted
  /// yet. Declining exits the app.
  static Future<void> ensureAccepted(BuildContext context) async {
    if (isAccepted) return;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Community Guidelines'),
          content: const SingleChildScrollView(
            child: Text(
              'MeshTrax lets you exchange messages over a decentralized LoRa '
              'mesh. By continuing you agree to our Terms of Use:\n\n'
              '• No objectionable, abusive, harassing, or illegal content.\n'
              '• There is zero tolerance for such content and behavior.\n'
              '• You can report content and block users from any message.\n\n'
              'Content travels peer-to-peer; the developer does not host or '
              'control it, but will act on reports. You can review the full '
              'Terms in Settings → Privacy.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => SystemNavigator.pop(),
              child: const Text('Decline'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Agree'),
            ),
          ],
        ),
      ),
    );
    if (accepted == true) {
      await _setAccepted();
    }
  }
}
