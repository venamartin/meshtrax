import '../utils/platform_info.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/server_login_service.dart';
import '../services/storage_service.dart';
import '../connector/meshcore_connector.dart';
import '../utils/app_logger.dart';
import '../helpers/snack_bar_builder.dart';
import 'routing_dialog.dart';

class RoomLoginDialog extends StatefulWidget {
  final Contact room;
  final Function(String password, bool isAdmin) onLogin;

  const RoomLoginDialog({super.key, required this.room, required this.onLogin});

  @override
  State<RoomLoginDialog> createState() => _RoomLoginDialogState();
}

class _RoomLoginDialogState extends State<RoomLoginDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = true;
  bool _obscurePassword = true;
  late MeshCoreConnector _connector;
  late ServerLoginService _login;
  int _currentAttempt = 0;
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _login = ServerLoginService(_connector);
    _loadRememberedPassword();
  }

  /// Rooms remember the password that last worked; the field starts with it
  /// so logging in again, or with a different password, is one tap away.
  Future<void> _loadRememberedPassword() async {
    final remembered = await StorageService().getRepeaterPassword(
      widget.room.publicKeyHex,
    );
    if (!mounted) return;
    setState(() {
      if (remembered != null) _passwordController.text = remembered;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  bool _isLoggingIn = false;

  int _resolveRepeaterIndex = -1;

  Contact _resolveRepeater(MeshCoreConnector connector) {
    if (_resolveRepeaterIndex >= 0 &&
        _resolveRepeaterIndex < connector.contacts.length &&
        connector.contacts[_resolveRepeaterIndex].publicKeyHex ==
            widget.room.publicKeyHex) {
      return connector.contacts[_resolveRepeaterIndex];
    }
    _resolveRepeaterIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.room.publicKeyHex,
    );
    if (_resolveRepeaterIndex == -1) {
      return widget.room;
    }
    return connector.contacts[_resolveRepeaterIndex];
  }

  Future<void> _handleLogin() async {
    if (_isLoggingIn) return;

    setState(() {
      _isLoggingIn = true;
      _currentAttempt = 0;
    });

    try {
      final password = _passwordController.text;
      final room = _resolveRepeater(_connector);
      appLogger.info(
        'Login started for ${room.name} (${room.publicKeyHex})',
        tag: 'RoomLogin',
      );
      final outcome = await _login.login(
        room,
        password,
        maxAttempts: _maxAttempts,
        tag: 'RoomLogin',
        onAttempt: (attempt) {
          if (mounted) setState(() => _currentAttempt = attempt);
        },
      );
      if (outcome.success != true) {
        throw Exception('Wrong password or node is unreachable');
      }

      final isAdmin = await _login.rememberRoomLogin(room, password, outcome);

      if (mounted) {
        Navigator.pop(context, password);
        Future.microtask(() => widget.onLogin(password, isAdmin));
      }
    } catch (e) {
      final room = _resolveRepeater(_connector);
      appLogger.warn('Login error for ${room.name}: $e', tag: 'RoomLogin');
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
        });
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.login_failed(e.toString())),
          backgroundColor: Colors.red,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final repeater = _resolveRepeater(connector);
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.meeting_room, color: Colors.purple),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.login_roomLogin),
                Text(
                  repeater.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: _isLoading
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              ),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.login_roomDescription,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: l10n.login_password,
                      hintText: l10n.login_enterPassword,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    onSubmitted: (_) => _handleLogin(),
                    autofocus:
                        !PlatformInfo.isMobile &&
                        _passwordController.text.isEmpty,
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Row(
                    children: [
                      RoutingIcon(contact: repeater, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          repeater.pathLabel,
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: () =>
                            RoutingDialog.show(context, contact: repeater),
                        child: Text(l10n.routing_title),
                      ),
                    ],
                  ),
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        if (_isLoggingIn)
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.login_attempt(_currentAttempt, _maxAttempts)),
                ],
              ),
            ),
          )
        else
          FilledButton.icon(
            onPressed: _isLoading ? null : _handleLogin,
            icon: const Icon(Icons.login, size: 18),
            label: Text(l10n.login_login),
          ),
      ],
    );
  }
}
