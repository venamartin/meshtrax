import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../models/trax.dart';
import '../storage/prefs_manager.dart';
import 'location_icon.dart';
import 'signal_ui.dart';
import 'snr_indicator.dart';
import 'trax_dialogs.dart';

/// Every top-bar icon with a few words (Martin, 2026-11-21: "We are going
/// to have to have a help somewhere so people know what all these
/// different icons mean"). In the ⋮ menu, at the foot of the My location
/// sheet, and once after the update. A dialog with an X, as How TRAX works
/// is (Martin, 2026-11-27): as a sheet its last row sat behind the
/// navigation bar.
Future<void> showIconHelp(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const IconHelp());

class IconHelp extends StatelessWidget {
  const IconHelp({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quiet = scheme.onSurfaceVariant;
    final signal = signalUiForStrengthTier(1);
    Widget pin(LocationAudience audience, LocationGps gps, Color color) =>
        LocationIcon(audience: audience, gps: gps, color: color);

    final help = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.iconHelp_tap,
            style: theme.textTheme.bodyMedium?.copyWith(color: quiet),
          ),
          _head(context, l10n.iconHelp_radio),
          _item(
            context,
            const Icon(Icons.battery_full, color: Colors.green),
            l10n.iconHelp_battery,
            l10n.iconHelp_batteryText,
          ),
          _item(
            context,
            Icon(signal.icon, color: signal.color),
            l10n.iconHelp_signal,
            l10n.iconHelp_signalText,
          ),
          _item(
            context,
            const Text('1: B4E1: 22s', style: SNRIndicator.repeatersStyle),
            l10n.iconHelp_repeaters,
            l10n.iconHelp_repeatersText,
          ),
          _head(context, l10n.trax_title),
          _item(context, TraxIcon(color: quiet), l10n.iconHelp_traxOff),
          _item(
            context,
            const TraxIcon(color: Color(Trax.orange)),
            l10n.iconHelp_traxOn,
            l10n.iconHelp_traxOnText,
          ),
          _head(context, l10n.iconHelp_who),
          _item(
            context,
            pin(LocationAudience.onlyYou, LocationGps.on, quiet),
            l10n.myLocation_onlyYou,
          ),
          _item(
            context,
            pin(LocationAudience.people, LocationGps.on, scheme.primary),
            l10n.iconHelp_people,
            l10n.iconHelp_peopleText,
          ),
          _item(
            context,
            pin(LocationAudience.adverts, LocationGps.on, scheme.primary),
            l10n.myLocation_adverts,
            l10n.iconHelp_advertsText,
          ),
          _head(context, l10n.iconHelp_gps),
          _item(
            context,
            pin(LocationAudience.onlyYou, LocationGps.on, quiet),
            l10n.iconHelp_filled,
          ),
          _item(
            context,
            pin(LocationAudience.onlyYou, LocationGps.off, quiet),
            l10n.iconHelp_outline,
          ),
          _item(
            context,
            pin(LocationAudience.onlyYou, LocationGps.noFix, quiet),
            l10n.iconHelp_dashed,
          ),
          _item(
            context,
            pin(LocationAudience.onlyYou, LocationGps.noFix, scheme.error),
            l10n.iconHelp_red,
          ),
        ],
      ),
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      namesRoute: true,
                      header: true,
                      child: Text(
                        l10n.iconHelp_title,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.common_close,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(child: help),
          ],
        ),
      ),
    );
  }

  Widget _head(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall
          ?.copyWith(color: Theme.of(context).colorScheme.primary),
    ),
  );

  Widget _item(BuildContext context, Widget icon, String name, [String? text]) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Center(
              child: IconTheme.merge(
                data: const IconThemeData(size: 22),
                child: icon,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyLarge),
                if (text != null)
                  Text(
                    text,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Once after the update that made the GPS and Who can see my location
/// buttons one (Martin, 2026-11-21).
abstract final class LocationButtonNote {
  static const prefKey = 'location_button_note_seen';

  static Future<void> showOnce(BuildContext context) async {
    final prefs = PrefsManager.instance;
    if (prefs.getBool(prefKey) ?? false) return;
    await prefs.setBool(prefKey, true);
    if (!context.mounted) return;
    final help = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = context.l10n;
        final scheme = Theme.of(context).colorScheme;
        final quiet = scheme.onSurfaceVariant;
        return AlertDialog(
          title: Text(l10n.locationNote_title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.gps_fixed, color: quiet),
                  const SizedBox(width: 4),
                  Icon(Icons.share_location, color: quiet),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward, color: quiet),
                  ),
                  LocationIcon(
                    audience: LocationAudience.people,
                    gps: LocationGps.on,
                    size: 28,
                    color: scheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(l10n.locationNote_body),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.iconHelp_title),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.common_ok),
            ),
          ],
        );
      },
    );
    if (help == true && context.mounted) await showIconHelp(context);
  }
}
