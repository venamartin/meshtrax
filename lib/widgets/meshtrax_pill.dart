import 'package:material_ui/material_ui.dart';

/// Beside a contact's name: their phone runs MeshTrax, so direct messages
/// to them go as MeshTrax's own packets. It follows what is heard from
/// them: shown once one of those packets arrives, gone when they stop
/// answering that way.
class MeshTraxPill extends StatelessWidget {
  const MeshTraxPill({super.key});

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ink.withValues(alpha: 0.55), width: 0.8),
      ),
      child: Text(
        'MeshTrax',
        maxLines: 1,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: ink,
          height: 1.25,
        ),
      ),
    );
  }
}
