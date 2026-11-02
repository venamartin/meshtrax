import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class AttachTile {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const AttachTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });
}

/// The round "+" at the end of the composer. Turns into a cross while the
/// tray is open.
class AttachButton extends StatelessWidget {
  final bool open;
  final VoidCallback onPressed;

  const AttachButton({super.key, required this.open, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      tooltip: context.l10n.tray_add,
      icon: AnimatedRotation(
        turns: open ? 0.125 : 0,
        duration: const Duration(milliseconds: 200),
        child: const Icon(Icons.add),
      ),
    );
  }
}

/// The button at the end of the composer: "+" while the text field is empty,
/// the send button once there is something to send.
class ComposerActionButton extends StatelessWidget {
  final TextEditingController controller;
  final bool trayOpen;
  final VoidCallback onToggleTray;
  final VoidCallback onSend;
  final String sendTooltip;

  const ComposerActionButton({
    super.key,
    required this.controller,
    required this.trayOpen,
    required this.onToggleTray,
    required this.onSend,
    required this.sendTooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final empty = value.text.trim().isEmpty;
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: empty
              ? AttachButton(
                  key: const ValueKey('attach'),
                  open: trayOpen,
                  onPressed: onToggleTray,
                )
              : IconButton.filled(
                  key: const ValueKey('send'),
                  icon: const Icon(Icons.send),
                  tooltip: sendTooltip,
                  onPressed: onSend,
                ),
        );
      },
    );
  }
}

/// A row of large icon tiles that slides in under the composer, as in
/// Signal. The host decides when it is open; this just draws the tiles.
class ComposerAttachTray extends StatelessWidget {
  final List<AttachTile> tiles;

  const ComposerAttachTray({super.key, required this.tiles});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      child: SizedBox(
        height: 118,
        // Tiles side by side: 14 dp between the squares (owner, 2026-10-27),
        // and the widest one-word labels still fit.
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            final tile = tiles[index];
            final color = tile.color ?? scheme.secondaryContainer;
            final onColor = tile.color == null
                ? scheme.onSecondaryContainer
                : scheme.onErrorContainer;
            return InkWell(
              onTap: tile.onTap,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 74,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(tile.icon, size: 28, color: onColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      tile.label,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        height: 1.1,
                        fontSize: 12,
                        color: scheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
