import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../storage/prefs_manager.dart';

/// What Pathfinder is, how it works, and that it needs time to learn
/// before it does much. Shown once when Pathfinder is switched on, and
/// from the info button on its screen any time after.
class PathfinderHelpDialog extends StatefulWidget {
  const PathfinderHelpDialog({super.key, this.offerDontShowAgain = true});

  /// Whether to offer "Don't show this again" (the automatic showing
  /// does; the info button shows the same text without it).
  final bool offerDontShowAgain;

  static const prefKey = 'pathfinder_help_seen';

  /// Whether the automatic showing has been turned off.
  static bool get seen => PrefsManager.instance.getBool(prefKey) ?? false;

  static Future<void> show(BuildContext context,
      {bool offerDontShowAgain = true}) {
    return showDialog<void>(
      context: context,
      builder: (_) =>
          PathfinderHelpDialog(offerDontShowAgain: offerDontShowAgain),
    );
  }

  /// Shows the help once: the first time Pathfinder is switched on, unless
  /// the user asked not to see it again.
  static Future<void> showIfNotSeen(BuildContext context) async {
    if (seen) return;
    await show(context);
  }

  @override
  State<PathfinderHelpDialog> createState() => _PathfinderHelpDialogState();
}

class _PathfinderHelpDialogState extends State<PathfinderHelpDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final body = Theme.of(context).textTheme.bodyMedium;
    final paragraphs = [
      l10n.pathfinderHelp_what,
      l10n.pathfinderHelp_how,
      l10n.pathfinderHelp_learning,
      l10n.pathfinderHelp_guessed,
      l10n.pathfinderHelp_discover,
      l10n.pathfinderHelp_off,
    ];
    return AlertDialog(
      title: Text(l10n.pathfinderHelp_title),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final p in paragraphs) ...[
              Text(p, style: body),
              const SizedBox(height: 12),
            ],
            if (widget.offerDontShowAgain)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(l10n.pathfinderHelp_dontShowAgain),
                value: _dontShowAgain,
                onChanged: (v) => setState(() => _dontShowAgain = v ?? false),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            if (_dontShowAgain) {
              await PrefsManager.instance
                  .setBool(PathfinderHelpDialog.prefKey, true);
            }
            if (context.mounted) Navigator.of(context).pop();
          },
          child: Text(l10n.pathfinderHelp_ok),
        ),
      ],
    );
  }
}
