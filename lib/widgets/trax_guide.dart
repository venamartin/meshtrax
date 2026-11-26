import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../models/trax.dart';
import '../storage/prefs_manager.dart';
import 'trax_dialogs.dart';

/// How TRAX works, told as a hike with friends behind you and more joining
/// the next day (Martin, 2026-11-26), then the icons it shows. After TRAX
/// mode goes on until "Don't show this again", and from the info button in
/// TRAX settings any time.
Future<void> showTraxGuide(
  BuildContext context, {
  bool offerDontShowAgain = false,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => TraxGuide(offerDontShowAgain: offerDontShowAgain),
);

class TraxGuide extends StatefulWidget {
  /// Shown by itself: it offers "Don't show this again".
  final bool offerDontShowAgain;

  static const prefKey = 'trax_guide_seen';

  const TraxGuide({super.key, this.offerDontShowAgain = false});

  /// After TRAX mode goes on, unless asked not to.
  static Future<void> showIfNotSeen(BuildContext context) async {
    if (PrefsManager.instance.getBool(prefKey) ?? false) return;
    await showTraxGuide(context, offerDontShowAgain: true);
  }

  @override
  State<TraxGuide> createState() => _TraxGuideState();
}

class _TraxGuideState extends State<TraxGuide> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final quiet = scheme.onSurfaceVariant;
    const orange = Color(Trax.orange);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.traxGuide_title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            l10n.traxGuide_lead,
            style: theme.textTheme.bodyMedium?.copyWith(color: quiet),
          ),
          const SizedBox(height: 8),
          _step(
            context,
            Icon(Icons.forum_outlined, color: quiet),
            l10n.traxGuide_beforeTitle,
            l10n.traxGuide_before,
          ),
          _step(
            context,
            const TraxIcon(color: orange),
            l10n.traxGuide_trailheadTitle,
            l10n.traxGuide_trailhead,
          ),
          _step(
            context,
            Icon(Icons.groups, color: quiet),
            l10n.traxGuide_trailTitle,
            l10n.traxGuide_trail,
          ),
          _step(
            context,
            Icon(Icons.repeat, color: quiet),
            l10n.traxGuide_behindTitle,
            l10n.traxGuide_behind,
          ),
          _step(
            context,
            Icon(Icons.settings_input_antenna, color: quiet),
            l10n.traxGuide_quietTitle,
            l10n.traxGuide_quiet,
          ),
          _step(
            context,
            Icon(Icons.group_add, color: quiet),
            l10n.traxGuide_joinTitle,
            l10n.traxGuide_join,
          ),
          _step(
            context,
            Icon(Icons.warning_rounded, color: scheme.error),
            l10n.traxGuide_sosTitle,
            l10n.traxGuide_sos,
          ),
          _step(
            context,
            Icon(Icons.event, color: quiet),
            l10n.traxGuide_endTitle,
            l10n.traxGuide_end,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(
              l10n.traxGuide_iconsTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                color: scheme.primary,
              ),
            ),
          ),
          _item(context, TraxIcon(color: quiet), l10n.iconHelp_traxOff),
          _item(
            context,
            const TraxIcon(color: orange),
            l10n.iconHelp_traxOn,
            l10n.iconHelp_traxOnText,
          ),
          _item(
            context,
            _pin(orange),
            l10n.traxGuide_member,
            l10n.traxGuide_memberText,
          ),
          _item(context, _pin(Colors.grey), l10n.traxGuide_old),
          _item(context, _dot(), l10n.traxGuide_you),
          _item(context, _line(Colors.blue[600]!), l10n.traxGuide_yourTrack),
          _item(context, _line(orange), l10n.traxGuide_theirTrack),
          _item(
            context,
            CircleAvatar(
              backgroundColor: orange.withValues(alpha: 0.2),
              child: const TraxIcon(size: 24, color: orange),
            ),
            l10n.traxGuide_tripChannel,
            l10n.traxGuide_tripChannelText,
          ),
          if (widget.offerDontShowAgain)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(l10n.traxGuide_dontShowAgain),
              value: _dontShowAgain,
              onChanged: (v) {
                setState(() => _dontShowAgain = v ?? false);
                unawaited(
                  PrefsManager.instance.setBool(
                    TraxGuide.prefKey,
                    _dontShowAgain,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _step(BuildContext context, Widget icon, String title, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 40, child: icon),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One icon and what it means, as "What the icons mean" shows them.
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

  /// A member's pin, as the map draws it.
  static Widget _pin(Color color) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2),
    ),
    child: const Icon(Icons.hiking, color: Colors.white, size: 20),
  );

  /// Your GPS position, as the map draws it.
  static Widget _dot() => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      color: Colors.blue[600],
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 3),
      boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 4)],
    ),
  );

  static Widget _line(Color color) => Container(
    width: 40,
    height: 4,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
