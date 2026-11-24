import 'dart:async';
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/region_helper.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/repeater_regions.dart';
import '../services/region_service.dart';
import '../services/repeater_command_service.dart';
import '../services/repeater_regions_controller.dart';

/// A logged-in repeater's regions: which ones it passes on, whether it
/// passes on messages with no region, and its own region. Every change is
/// saved on the repeater.
class RepeaterRegionsScreen extends StatefulWidget {
  final Contact repeater;

  /// Tests pass a controller with a fake repeater behind it.
  final RepeaterRegionsController? controller;

  const RepeaterRegionsScreen({
    super.key,
    required this.repeater,
    this.controller,
  });

  @override
  State<RepeaterRegionsScreen> createState() => _RepeaterRegionsScreenState();
}

class _RepeaterRegionsScreenState extends State<RepeaterRegionsScreen> {
  /// Like the settings screen: a repeater defers replies while the channel
  /// is busy, so one attempt fails commands that actually ran.
  static const int _retries = 3;

  late final RepeaterRegionsController _controller;
  RepeaterCommandService? _service;
  StreamSubscription<Uint8List>? _frames;

  @override
  void initState() {
    super.initState();
    final given = widget.controller;
    if (given != null) {
      _controller = given;
    } else {
      final connector = context.read<MeshCoreConnector>();
      final service = _service = RepeaterCommandService(connector);
      _frames = connector.receivedFrames.listen((frame) {
        if (frame.isEmpty ||
            (frame[0] != respCodeContactMsgRecv &&
                frame[0] != respCodeContactMsgRecvV3)) {
          return;
        }
        final parsed = parseContactMessageText(frame);
        if (parsed == null || !_isRepeater(parsed.senderPrefix)) return;
        service.handleResponse(widget.repeater, parsed.text);
      });
      _controller = RepeaterRegionsController(
        (command) => service.sendCommand(
          _liveRepeater(connector),
          command,
          retries: _retries,
        ),
      );
    }
    _controller.addListener(_onChange);
    unawaited(_controller.load());
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    if (widget.controller == null) _controller.dispose();
    _frames?.cancel();
    _service?.dispose();
    super.dispose();
  }

  Contact _liveRepeater(MeshCoreConnector connector) =>
      connector.contacts
          .where((c) => c.publicKeyHex == widget.repeater.publicKeyHex)
          .firstOrNull ??
      widget.repeater;

  bool _isRepeater(Uint8List prefix) {
    final key = widget.repeater.publicKey;
    if (key.length < 6 || prefix.length < 6) return false;
    for (var i = 0; i < 6; i++) {
      if (prefix[i] != key[i]) return false;
    }
    return true;
  }

  RepeaterRegionsProblem? _shownProblem;

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    final problem = _controller.problem;
    if (problem == null || _controller.busy) {
      _shownProblem = null;
      return;
    }
    if (problem == _shownProblem) return;
    _shownProblem = problem;
    final l10n = context.l10n;
    showDismissibleSnackBar(
      context,
      content: Text(switch (problem) {
        RepeaterRegionsProblem.noAnswer => l10n.repeaterRegions_noAnswer,
        RepeaterRegionsProblem.hasChildren => l10n.repeaterRegions_hasChildren,
        RepeaterRegionsProblem.refused => l10n.repeaterRegions_refused(
          _controller.refusal ?? '',
        ),
      }),
      backgroundColor: Colors.red,
    );
  }

  Future<void> _setNoRegion(bool on) async {
    if (!on) {
      final l10n = context.l10n;
      final sure = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.repeaterRegions_noRegionOffTitle),
          content: Text(l10n.repeaterRegions_noRegionOffBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.common_cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(l10n.repeaterRegions_turnOff),
            ),
          ],
        ),
      );
      if (sure != true) return;
    }
    await _controller.setRepeats(null, on);
  }

  /// A choice among [options] (null first, shown as [nullLabel]); the
  /// record tells "picked null" from "cancelled".
  Future<({String? value})?> _pick({
    required String title,
    required String nullLabel,
    required List<String> options,
    required String? current,
  }) {
    final l10n = context.l10n;
    return showDialog<({String? value})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: RadioGroup<String?>(
            groupValue: current,
            onChanged: (value) => Navigator.pop(dialogContext, (value: value)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String?>(title: Text(nullLabel), value: null),
                for (final option in options)
                  RadioListTile<String?>(title: Text(option), value: option),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_cancel),
          ),
        ],
      ),
    );
  }

  Future<void> _pickOwnRegion() async {
    final l10n = context.l10n;
    final picked = await _pick(
      title: l10n.repeaterRegions_own,
      nullLabel: l10n.regions_none,
      options: [for (final r in _controller.regions.regions) r.name],
      current: _controller.ownRegion,
    );
    if (picked == null || picked.value == _controller.ownRegion) return;
    await _controller.setOwnRegion(picked.value);
  }

  Future<void> _remove(RepeaterRegion region) async {
    final l10n = context.l10n;
    final sure = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.repeaterRegions_removeTitle(region.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.common_remove),
          ),
        ],
      ),
    );
    if (sure == true) await _controller.remove(region.name);
  }

  Future<void> _add() async {
    final onRepeater = {for (final r in _controller.regions.regions) r.name};
    final mine = context.read<RegionService?>()?.regions ?? const <String>[];
    final names = await showDialog<List<String>>(
      context: context,
      builder: (_) => _AddDialog(
        onRepeater: onRepeater,
        offered: [for (final r in mine) if (!onRepeater.contains(r)) r],
      ),
    );
    if (names == null) return;
    await _controller.add(names);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final c = _controller;
    final ready = c.status == RepeaterRegionsStatus.ready;
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.regions_title),
            Text(
              widget.repeater.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.common_reload,
            onPressed: c.busy || c.status == RepeaterRegionsStatus.loading
                ? null
                : c.load,
          ),
        ],
        bottom: c.busy
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              )
            : null,
      ),
      floatingActionButton: ready
          ? FloatingActionButton.extended(
              onPressed: c.busy ? null : _add,
              icon: const Icon(Icons.add),
              label: Text(l10n.regions_add),
            )
          : null,
      body: SafeArea(
        child: switch (c.status) {
          RepeaterRegionsStatus.loading => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.repeaterRegions_reading),
              ],
            ),
          ),
          RepeaterRegionsStatus.tooOld => _message(l10n.repeaterRegions_tooOld),
          RepeaterRegionsStatus.noAnswer => _message(
            l10n.repeaterRegions_noAnswer,
            action: FilledButton(
              onPressed: c.load,
              child: Text(l10n.common_retry),
            ),
          ),
          RepeaterRegionsStatus.ready => _list(context),
        },
      ),
    );
  }

  Widget _message(String text, {Widget? action}) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    ),
  );

  Widget _list(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final c = _controller;
    final regions = c.regions;
    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
      children: [
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile(
                title: Text(l10n.repeaterRegions_noRegion),
                subtitle: Text(l10n.repeaterRegions_noRegionHelp),
                value: regions.noRegionRepeats,
                onChanged: c.busy ? null : _setNoRegion,
              ),
              const Divider(height: 1),
              ListTile(
                title: Text(l10n.repeaterRegions_own),
                subtitle: Text(c.ownRegion ?? l10n.regions_none),
                trailing: const Icon(Icons.chevron_right),
                enabled: !c.busy,
                onTap: _pickOwnRegion,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  l10n.repeaterRegions_ownHelp,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Text(
            l10n.repeaterRegions_onRepeater,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        if (regions.mayBeIncomplete)
          Card(
            child: ListTile(
              leading: const Icon(Icons.warning_amber, color: Colors.orange),
              title: Text(l10n.repeaterRegions_mayBeIncomplete),
            ),
          ),
        if (regions.regions.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(l10n.repeaterRegions_empty),
          )
        else
          Card(
            child: Column(
              children: [
                for (final region in _sorted(regions.regions))
                  ListTile(
                    contentPadding: const EdgeInsetsDirectional.only(
                      start: 16,
                      end: 4,
                    ),
                    leading: const Icon(Icons.hexagon_outlined),
                    title: Text(region.name),
                    subtitle: Text(
                      region.repeats
                          ? l10n.repeaterRegions_repeated
                          : l10n.repeaterRegions_notRepeated,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: region.repeats,
                          onChanged: c.busy
                              ? null
                              : (on) => c.setRepeats(region.name, on),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n.common_remove,
                          onPressed: c.busy ? null : () => _remove(region),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

List<RepeaterRegion> _sorted(List<RepeaterRegion> regions) => [...regions]
  ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

class _AddDialog extends StatefulWidget {
  final Set<String> onRepeater;
  final List<String> offered;

  const _AddDialog({required this.onRepeater, required this.offered});

  @override
  State<_AddDialog> createState() => _AddDialogState();
}

class _AddDialogState extends State<_AddDialog> {
  final _name = TextEditingController();
  final _ticked = <String>{};

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? get _typed {
    final name = RegionHelper.normalize(_name.text);
    return name.isEmpty ? null : name;
  }

  String? _problem() {
    final l10n = context.l10n;
    final typed = _typed;
    if (typed == null) return null;
    return switch (RegionHelper.check(typed)) {
      RegionNameProblem.empty => null,
      RegionNameProblem.tooLong => l10n.regions_nameTooLong,
      RegionNameProblem.badCharacter => l10n.regions_nameBadCharacter,
      null =>
        widget.onRepeater.contains(typed)
            ? l10n.repeaterRegions_alreadyThere
            : null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final problem = _problem();
    final names = [
      if (_typed case final typed? when problem == null) typed,
      for (final r in _ticked) if (r != _typed) r,
    ];
    return AlertDialog(
      title: Text(l10n.regions_add),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _name,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: l10n.regions_nameLabel,
                helperText: l10n.regions_nameHelp,
                helperMaxLines: 3,
                errorText: problem,
                errorMaxLines: 3,
              ),
              onChanged: (_) => setState(() {}),
            ),
            if (widget.offered.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                l10n.repeaterRegions_fromYours,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              for (final region in widget.offered)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(region),
                  value: _ticked.contains(region),
                  onChanged: (on) => setState(
                    () => on == true
                        ? _ticked.add(region)
                        : _ticked.remove(region),
                  ),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: names.isEmpty
              ? null
              : () => Navigator.pop(context, names),
          child: Text(l10n.common_add),
        ),
      ],
    );
  }
}
