import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../storage/prefs_manager.dart';
import 'route_sheet.dart';
import 'water_route_parts.dart';

/// Before a new trip on the water, the boat it is for, until "Don't show
/// this again" (owner, 2026-11-25). The first time it also shows the data's
/// [notices], in place of the sheet's popup. False when cancelled.
Future<bool> askWaterBoatIfNeeded(
  BuildContext context, {
  required List<String> notices,
}) async {
  final service = context.read<AppSettingsService>();
  final settings = service.settings;
  if (settings.waterBoatAskDismissed) return true;
  final prefs = PrefsManager.instance;
  final tellNotice = !(prefs.getBool(RouteSheet.waterNoticeToldKey) ?? false);
  var boat = settings.waterRouteOptions;
  var dontShowAgain = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      final theme = Theme.of(dialogContext);
      final muted = theme.textTheme.bodyMedium!.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      );
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.water_yourBoat),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l10n.water_yourBoatIntro, style: muted),
              const SizedBox(height: 8),
              WaterRouteOptionsSection(
                options: boat,
                units: settings.unitSystem,
                onChanged: (b) => setDialogState(() => boat = b),
              ),
              if (tellNotice) ...[
                const SizedBox(height: 16),
                Text(
                  notices.isEmpty
                      ? l10n.water_notForNavigation
                      : notices.join('\n\n'),
                  style: muted,
                ),
              ],
              const SizedBox(height: 8),
              CheckboxListTile(
                title: Text(l10n.dmChannel_dontShowAgain),
                value: dontShowAgain,
                onChanged: (v) =>
                    setDialogState(() => dontShowAgain = v ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.common_cancel),
            ),
            TextButton(
              onPressed: () async {
                // A number still being typed counts: it is taken as its
                // field loses focus.
                FocusManager.instance.primaryFocus?.unfocus();
                await Future<void>.delayed(Duration.zero);
                if (dialogContext.mounted) Navigator.pop(dialogContext, true);
              },
              child: Text(l10n.common_ok),
            ),
          ],
        ),
      );
    },
  );
  if (ok != true) return false;
  if (tellNotice) await prefs.setBool(RouteSheet.waterNoticeToldKey, true);
  if (boat != settings.waterRouteOptions) {
    await service.setWaterRouteOptions(boat);
  }
  if (dontShowAgain) await service.setWaterBoatAskDismissed(true);
  return true;
}
