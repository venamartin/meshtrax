import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/path_graph/path_graph_service.dart';
import 'routing_dialog.dart';

/// Above the chats list when most repeaters heard since connecting are new
/// to the open Pathfinder graph: another mesh on the same preset
/// ([PathGraphService.meshSuggestion]). Offers a new graph, or the graph
/// that knows those repeaters.
class PathfinderMeshBanner extends StatelessWidget {
  const PathfinderMeshBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PathGraphService?>();
    final suggestion = service?.meshSuggestion;
    if (service == null || suggestion == null) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final other = suggestion.other;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(RoutingIcon.icon,
                    size: 18, color: RoutingIcon.pathfinderColor(context)),
                const SizedBox(width: 8),
                Text(
                  l10n.pathfinder_meshTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              other == null
                  ? l10n.pathfinder_meshNewBody(suggestion.unknown,
                      suggestion.heard, suggestion.current.label)
                  : l10n.pathfinder_meshSwitchBody(
                      other.label, suggestion.current.label),
              style: TextStyle(color: scheme.onSecondaryContainer),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: service.dismissMeshSuggestion,
                  child: Text(l10n.pathfinder_meshKeep),
                ),
                TextButton(
                  onPressed: () async {
                    if (other != null) {
                      await service.acceptMeshSuggestion();
                      return;
                    }
                    final name = await showGraphNameDialog(context);
                    if (name != null) {
                      await service.acceptMeshSuggestion(name: name);
                    }
                  },
                  child: Text(other == null
                      ? l10n.pathfinder_meshNew
                      : l10n.pathfinder_meshSwitch),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks what to call a Pathfinder graph; null when cancelled or left
/// empty. [title] and [initial] serve a rename.
Future<String?> showGraphNameDialog(
  BuildContext context, {
  String? title,
  String? initial,
}) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _GraphNameDialog(title: title, initial: initial),
  );
  final trimmed = name?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

/// Owns its text controller: the field is still on screen while the
/// dialog animates away, after the name has been returned.
class _GraphNameDialog extends StatefulWidget {
  const _GraphNameDialog({this.title, this.initial});

  final String? title;
  final String? initial;

  @override
  State<_GraphNameDialog> createState() => _GraphNameDialogState();
}

class _GraphNameDialogState extends State<_GraphNameDialog> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.title ?? l10n.pathfinder_graphNameTitle),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(hintText: l10n.pathfinder_graphNameHint),
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.initial == null
              ? l10n.pathfinder_graphCreate
              : l10n.common_save),
        ),
      ],
    );
  }
}
