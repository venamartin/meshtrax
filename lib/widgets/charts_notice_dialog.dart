import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';

var _shownThisRun = false;

/// Shows [showChartsNotice] the first time the map draws charts in each
/// app run, until the user checks "don't show again".
Future<void> showChartsNoticeIfNeeded(BuildContext context) async {
  if (_shownThisRun) return;
  if (context.read<AppSettingsService>().settings.chartsNoticeDismissed) {
    return;
  }
  await showChartsNotice(context);
}

@visibleForTesting
void resetChartsNoticeShown() => _shownThisRun = false;

/// Why the charts are not for navigation. The checkbox shows the saved
/// choice, so reopening it (from the Charts tab) can also undo it.
Future<void> showChartsNotice(BuildContext context) async {
  _shownThisRun = true;
  final settingsService = context.read<AppSettingsService>();
  var dontShowAgain = settingsService.settings.chartsNoticeDismissed;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.map_notForNavigation),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Text(l10n.map_chartsNoticeIntro),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    l10n.map_chartsNoticeWhy,
                    style: Theme.of(dialogContext).textTheme.titleSmall,
                  ),
                  for (final reason in [
                    l10n.map_chartsNoticeOutOfDate,
                    l10n.map_chartsNoticeLeftOut,
                    l10n.map_chartsNoticePositions,
                    l10n.map_chartsNoticeNotPlotter,
                  ])
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(reason)),
                      ],
                    ),
                ],
              ),
              Text(l10n.map_chartsNoticeUse),
              CheckboxListTile(
                title: Text(l10n.dmChannel_dontShowAgain),
                value: dontShowAgain,
                onChanged: (value) =>
                    setDialogState(() => dontShowAgain = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l10n.common_ok),
            ),
          ],
        ),
      );
    },
  );
  if (dontShowAgain != settingsService.settings.chartsNoticeDismissed) {
    await settingsService.setChartsNoticeDismissed(dontShowAgain);
  }
}
