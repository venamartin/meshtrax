import 'package:material_ui/material_ui.dart';
import 'package:traxheard/traxheard.dart';

import '../helpers/snack_bar_builder.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../services/heard_service.dart';

/// "Check sends with observers" in App settings, Messaging: the switch and,
/// while it is on, the server it asks.
class HeardCheckSettings extends StatelessWidget {
  const HeardCheckSettings({super.key});

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: HeardService.instance,
        builder: (context, _) {
          final service = HeardService.instance;
          final l10n = context.l10n;
          return Column(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.hearing),
                title: Text(l10n.appSettings_heardCheck),
                subtitle: Text(l10n.appSettings_heardCheckSubtitle),
                value: service.enabled,
                onChanged: (on) async {
                  // Switching on with no server means picking one first.
                  if (on &&
                      service.server.isEmpty &&
                      await HeardServerDialog.show(context) != true) {
                    return;
                  }
                  await service.setEnabled(on);
                },
              ),
              if (service.enabled) ...[
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.dns_outlined),
                  title: Text(l10n.appSettings_heardServer),
                  subtitle: Text(serverLabel(service.server, l10n)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => HeardServerDialog.show(context),
                ),
              ],
            ],
          );
        },
      );
}

/// A known server by its area and host, any other by its address.
String serverLabel(String address, AppLocalizations l10n) {
  if (address.isEmpty) return l10n.appSettings_heardServerNotSet;
  final uri = observerServerUri(address);
  for (final known in knownServers) {
    if (observerServerUri(known.address) == uri) return known.label;
  }
  return address;
}

/// Picks the observer server: one from the list or another address. Save
/// asks the server first; if it doesn't answer, "Save anyway" saves it.
/// True once a server is saved.
class HeardServerDialog extends StatefulWidget {
  const HeardServerDialog({super.key});

  static Future<bool?> show(BuildContext context) => showDialog<bool>(
        context: context,
        builder: (_) => const HeardServerDialog(),
      );

  @override
  State<HeardServerDialog> createState() => _HeardServerDialogState();
}

class _HeardServerDialogState extends State<HeardServerDialog> {
  /// The list entry picked, or -1 for another address.
  late int _picked;
  late final TextEditingController _address;
  bool _checking = false;
  bool _noAnswer = false;

  @override
  void initState() {
    super.initState();
    final current = HeardService.instance.server;
    final uri = observerServerUri(current);
    final known = knownServers.indexWhere(
      (k) => observerServerUri(k.address) == uri,
    );
    _picked = current.isEmpty ? 0 : known;
    _address = TextEditingController(text: known < 0 ? current : '');
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  String get _chosenAddress =>
      _picked < 0 ? _address.text.trim() : knownServers[_picked].address;

  Future<void> _save({required bool anyway}) async {
    final address = _chosenAddress;
    if (observerServerUri(address) == null) return;
    if (!anyway) {
      setState(() => _checking = true);
      final answered = await HeardService.serverAnswers(address);
      if (!mounted) return;
      setState(() {
        _checking = false;
        _noAnswer = !answered;
      });
      if (!answered) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.appSettings_heardServerAnswered),
      );
    }
    await HeardService.instance.setServer(address);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.appSettings_heardServer),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.appSettings_heardServerAbout,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            DropdownButton<int>(
              isExpanded: true,
              value: _picked,
              items: [
                for (final (i, known) in knownServers.indexed)
                  DropdownMenuItem(
                    value: i,
                    child: Text(known.label, overflow: TextOverflow.ellipsis),
                  ),
                DropdownMenuItem(
                  value: -1,
                  child: Text(l10n.appSettings_heardServerOther),
                ),
              ],
              onChanged: _checking
                  ? null
                  : (value) => setState(() {
                        _picked = value ?? 0;
                        _noAnswer = false;
                      }),
            ),
            if (_picked < 0)
              TextField(
                controller: _address,
                enabled: !_checking,
                keyboardType: TextInputType.url,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.appSettings_heardServerAddress,
                  hintText: 'analyzer.example.org',
                ),
                onChanged: (_) => setState(() => _noAnswer = false),
              ),
            if (_checking) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.appSettings_heardServerChecking),
                ],
              ),
            ],
            if (_noAnswer) ...[
              const SizedBox(height: 16),
              Text(
                l10n.appSettings_heardServerNoAnswer,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _checking ? null : () => Navigator.pop(context, false),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _checking || observerServerUri(_chosenAddress) == null
              ? null
              : () => _save(anyway: _noAnswer),
          child: Text(
            _noAnswer
                ? l10n.appSettings_heardServerSaveAnyway
                : l10n.common_save,
          ),
        ),
      ],
    );
  }
}
