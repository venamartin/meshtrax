import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

/// One entry of a message's action menu.
class MessageAction {
  final IconData icon;
  final String label;
  final VoidCallback onSelected;

  const MessageAction(this.icon, this.label, this.onSelected);
}

/// Shows a message's [actions]: as a bottom sheet after a long-press, or,
/// with [position] (a right-click on desktop), as a menu at the pointer.
Future<void> showMessageActions(
  BuildContext context,
  List<MessageAction> actions, {
  Offset? position,
}) async {
  if (position != null) {
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final chosen = await showMenu<MessageAction>(
      context: context,
      position: RelativeRect.fromRect(
        position & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: [
        for (final a in actions)
          PopupMenuItem(
            value: a,
            child: Row(
              children: [
                Icon(a.icon, size: 20),
                const SizedBox(width: 12),
                Flexible(child: Text(a.label)),
              ],
            ),
          ),
      ],
    );
    chosen?.onSelected();
    return;
  }
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final a in actions)
              ListTile(
                leading: Icon(a.icon),
                title: Text(a.label),
                onTap: () {
                  Navigator.pop(sheetContext);
                  a.onSelected();
                },
              ),
            ListTile(
              leading: const Icon(Icons.close),
              title: Text(context.l10n.common_cancel),
              onTap: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Reports a right-click anywhere inside [child], text included, where
/// SelectableText would otherwise take it. Raw pointer events, so no
/// gesture inside can win it away; it fires on release, like a desktop
/// context menu.
class ContextMenuRegion extends StatefulWidget {
  final void Function(Offset globalPosition)? onContextMenu;
  final Widget child;

  const ContextMenuRegion({
    super.key,
    required this.onContextMenu,
    required this.child,
  });

  @override
  State<ContextMenuRegion> createState() => _ContextMenuRegionState();
}

class _ContextMenuRegionState extends State<ContextMenuRegion> {
  int? _pointer;

  @override
  Widget build(BuildContext context) {
    if (widget.onContextMenu == null) return widget.child;
    return Listener(
      onPointerDown: (e) => _pointer =
          e.kind == PointerDeviceKind.mouse &&
                  e.buttons == kSecondaryMouseButton
              ? e.pointer
              : null,
      onPointerUp: (e) {
        if (e.pointer != _pointer) return;
        _pointer = null;
        widget.onContextMenu!(e.position);
      },
      onPointerCancel: (_) => _pointer = null,
      child: widget.child,
    );
  }
}
