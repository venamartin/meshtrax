import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../services/companion_cli_service.dart';
import 'scanner_screen.dart';
import 'tcp_screen.dart';

/// The firmware's fixed TCP port for WiFi companions (TCP_PORT in main.cpp).
const int companionWifiTcpPort = 5000;

/// WiFi for BLE+WiFi companions (firmware 1.18+). The radio has no binary
/// commands for it, only CLI keys, and every change needs a restart.
class WifiSettingsScreen extends StatefulWidget {
  const WifiSettingsScreen({super.key});

  @override
  State<WifiSettingsScreen> createState() => _WifiSettingsScreenState();
}

class _WifiSettingsScreenState extends State<WifiSettingsScreen> {
  final _ssidController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = true;
  bool _loadFailed = false;
  bool _busy = false;
  bool _enabled = false;
  bool _savedEnabled = false;
  String _savedSsid = '';
  // The radio's password once fetched with "Show"; null while unknown.
  String? _savedPassword;
  bool _obscurePassword = true;
  bool _connected = false;
  String? _address;

  CompanionCliService get _cli =>
      context.read<MeshCoreConnector>().companionCli;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _ssidController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<String> _get(String key) async =>
      CliReply(await _cli.run('get $key')).value;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final enabled = await _get('wifi.enabled') == '1';
      final ssid = await _get('wifi.ssid');
      final status = await _get('wifi.status');
      final ip = await _get('wifi.ip');
      if (!mounted) return;
      setState(() {
        _enabled = _savedEnabled = enabled;
        _savedSsid = ssid == '(not set)' ? '' : ssid;
        _ssidController.text = _savedSsid;
        _connected = status == 'connected';
        _address = _connected && ip != '(not connected)' ? ip : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadFailed = true;
      });
    }
  }

  Future<void> _revealPassword() async {
    if (_savedPassword == null) {
      try {
        final password = await _get('wifi.pwd');
        if (!mounted) return;
        _savedPassword = password;
        _passwordController.text = password;
      } catch (_) {
        return;
      }
    }
    setState(() => _obscurePassword = !_obscurePassword);
  }

  /// The commands that turn the radio's settings into the form's. An empty
  /// password field means "unchanged" until the real one has been shown;
  /// after that, emptying it means "no password".
  List<String> _pendingCommands() {
    final ssid = _ssidController.text;
    final password = _passwordController.text;
    return [
      if (ssid != _savedSsid) 'set wifi.ssid $ssid',
      if (_savedPassword != null
          ? password != _savedPassword
          : password.isNotEmpty)
        'set wifi.pwd $password',
      if (_enabled != _savedEnabled) 'set wifi.enabled ${_enabled ? 1 : 0}',
    ];
  }

  String? _validate() {
    final l10n = context.l10n;
    if (_enabled && _ssidController.text.isEmpty) return l10n.wifi_nameMissing;
    if (utf8.encode(_ssidController.text).length > 32) {
      return l10n.wifi_nameTooLong;
    }
    if (utf8.encode(_passwordController.text).length > 63) {
      return l10n.wifi_passwordTooLong;
    }
    return null;
  }

  Future<void> _save() async {
    final l10n = context.l10n;
    final problem = _validate();
    if (problem != null) {
      showDismissibleSnackBar(context, content: Text(problem));
      return;
    }
    final commands = _pendingCommands();
    if (commands.isEmpty) return;
    if (!await _runAll(commands)) return;
    if (!mounted) return;
    setState(() {
      _savedSsid = _ssidController.text;
      _savedEnabled = _enabled;
      _savedPassword = null;
      _passwordController.clear();
      _obscurePassword = true;
    });
    await _offerRestart(l10n.wifi_savedRestart);
  }

  Future<void> _forget() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.wifi_forget),
        content: Text(l10n.wifi_forgetConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.wifi_forget),
          ),
        ],
      ),
    );
    if (confirmed != true || !await _runAll(['set wifi.clear'])) return;
    _savedPassword = null;
    _passwordController.clear();
    await _load();
    if (mounted) await _offerRestart(l10n.wifi_savedRestart);
  }

  /// Runs [commands] in order and stops at the first the radio refuses.
  Future<bool> _runAll(List<String> commands) async {
    final l10n = context.l10n;
    setState(() => _busy = true);
    try {
      for (final command in commands) {
        final reply = CliReply(await _cli.run(command));
        if (reply.kind == CliReplyKind.error ||
            reply.kind == CliReplyKind.unknown) {
          if (mounted) {
            showDismissibleSnackBar(
              context,
              content: Text(l10n.wifi_notAccepted(reply.text)),
            );
          }
          return false;
        }
      }
      return true;
    } catch (_) {
      if (mounted) {
        showDismissibleSnackBar(context, content: Text(l10n.wifi_noReply));
      }
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _offerRestart(String message) async {
    final l10n = context.l10n;
    final restart = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.wifi_restartTitle),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.wifi_later),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.common_reboot),
          ),
        ],
      ),
    );
    if (restart == true && mounted) {
      await context.read<MeshCoreConnector>().rebootDevice();
    }
  }

  Future<void> _connectOverWifi(String address) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.wifi_connectOverWifi),
        content: Text(
          l10n.wifi_connectOverWifiBody(address, companionWifiTcpPort),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.common_continue),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final settings = context.read<AppSettingsService>();
    await settings.setTcpServerAddress(address);
    await settings.setTcpServerPort(companionWifiTcpPort);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    await context.read<MeshCoreConnector>().disconnect();
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ScannerScreen()),
      (route) => false,
    );
    navigator.push(MaterialPageRoute(builder: (_) => const TcpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wifi_title), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadFailed
          ? _buildLoadFailed(context)
          : _buildForm(context),
    );
  }

  Widget _buildLoadFailed(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.wifi_loadFailed),
          const SizedBox(height: 12),
          FilledButton(onPressed: _load, child: Text(l10n.common_retry)),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final address = _address;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: ListTile(
            leading: Icon(_connected ? Icons.wifi : Icons.wifi_off),
            title: Text(
              _connected && address != null
                  ? l10n.wifi_connectedTo(address)
                  : l10n.wifi_notConnected,
            ),
            subtitle: address != null
                ? Text(l10n.wifi_portNote(companionWifiTcpPort))
                : null,
            trailing: address != null
                ? TextButton(
                    onPressed: _busy ? null : () => _connectOverWifi(address),
                    child: Text(l10n.wifi_connectOverWifi),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: Text(l10n.wifi_use),
          value: _enabled,
          onChanged: _busy ? null : (v) => setState(() => _enabled = v),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _ssidController,
          enabled: !_busy,
          decoration: InputDecoration(
            labelText: l10n.wifi_networkName,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          enabled: !_busy,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: l10n.wifi_password,
            hintText: _savedPassword == null
                ? l10n.wifi_passwordUnchanged
                : null,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: l10n.wifi_showPassword,
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: _busy ? null : _revealPassword,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: _busy || _savedSsid.isEmpty ? null : _forget,
              child: Text(l10n.wifi_forget),
            ),
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: Text(l10n.common_save),
            ),
          ],
        ),
        const SizedBox(height: 24),
        for (final note in [
          l10n.wifi_noteRestart,
          l10n.wifi_noteSecurity,
          l10n.wifi_noteBattery,
          l10n.wifi_noteWrongPassword,
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
