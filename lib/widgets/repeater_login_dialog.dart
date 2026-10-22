import '../utils/platform_info.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/server_login_service.dart';
import '../services/storage_service.dart';
import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../utils/app_logger.dart';
import 'app_map.dart';
import 'routing_dialog.dart';

class RepeaterLoginDialog extends StatefulWidget {
  final Contact repeater;
  final Function(String password, bool isAdmin) onLogin;

  const RepeaterLoginDialog({
    super.key,
    required this.repeater,
    required this.onLogin,
  });

  @override
  State<RepeaterLoginDialog> createState() => _RepeaterLoginDialogState();
}

class _RepeaterLoginDialogState extends State<RepeaterLoginDialog> {
  final TextEditingController _passwordController = TextEditingController();
  final StorageService _storage = StorageService();
  bool _savePassword = false;
  bool _isLoading = true;
  bool _obscurePassword = true;
  String? _loginError;
  late MeshCoreConnector _connector;
  int _currentAttempt = 0;
  static const int _maxAttempts = 5;

  @override
  void initState() {
    super.initState();
    _connector = Provider.of<MeshCoreConnector>(context, listen: false);
    _loadSavedPassword();
  }

  Future<void> _loadSavedPassword() async {
    final savedPassword = await _storage.getRepeaterPassword(
      widget.repeater.publicKeyHex,
    );
    if (savedPassword != null) {
      setState(() {
        _passwordController.text = savedPassword;
        _savePassword = true;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
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
            widget.repeater.publicKeyHex) {
      return connector.contacts[_resolveRepeaterIndex];
    }
    _resolveRepeaterIndex = connector.contacts.indexWhere(
      (c) => c.publicKeyHex == widget.repeater.publicKeyHex,
    );
    if (_resolveRepeaterIndex == -1) {
      return widget.repeater;
    }
    return connector.contacts[_resolveRepeaterIndex];
  }

  Future<void> _handleLogin() async {
    if (_isLoggingIn) return;

    setState(() {
      _isLoggingIn = true;
      _currentAttempt = 0;
      _loginError = null;
    });

    try {
      final password = _passwordController.text;
      final repeater = _resolveRepeater(_connector);
      
      final isSavedContact = _resolveRepeaterIndex != -1;
      if (!isSavedContact) {
        await _connector.importDiscoveredContact(repeater);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${repeater.name} automatically added to contacts.'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        // Give the firmware a moment to process the new contact
        await Future.delayed(const Duration(seconds: 2));
      }

      appLogger.info(
        'Login started for ${repeater.name} (${repeater.publicKeyHex})',
        tag: 'RepeaterLogin',
      );

      // The ladder sends direct when the radio has a route and floods when it
      // has none; a route that times out is reset so the next attempt floods,
      // since a flooded login is what teaches the radio a route.
      final outcome = await ServerLoginService(_connector).login(
        repeater,
        password,
        maxAttempts: _maxAttempts,
        tag: 'RepeaterLogin',
        onAttempt: (attempt) {
          if (mounted) setState(() => _currentAttempt = attempt);
        },
      );
      final isAdmin = outcome.isAdmin ?? false;

      if (outcome.success != true) {
        if (mounted) {
          setState(() {
            _isLoggingIn = false;
            _loginError = context.l10n.login_failedMessage;
          });
        }
        return;
      }

      // If we got a response, login succeeded
      // Save password if requested
      if (_savePassword) {
        await _storage.saveRepeaterPassword(
          widget.repeater.publicKeyHex,
          password,
        );
      } else {
        // Remove saved password if user unchecked the box
        await _storage.removeRepeaterPassword(widget.repeater.publicKeyHex);
      }

      final autoClockSync = await _storage
          .getRepeaterAutoClockSyncAfterLoginEnabled(
            widget.repeater.publicKeyHex,
          );
      if (autoClockSync) {
        try {
          final timestampSeconds =
              DateTime.now().millisecondsSinceEpoch ~/ 1000;
          await _connector.sendFrame(
            buildSendCliCommandFrame(
              repeater.publicKey,
              'clock sync',
              timestampSeconds: timestampSeconds,
            ),
          );
        } catch (e) {
          appLogger.warn(
            'Auto clock sync failed for ${repeater.name}: $e',
            tag: 'RepeaterLogin',
          );
        }
      }

      if (mounted) {
        // The attempt loop runs for many seconds; the user may have stacked
        // the Routing or custom-path dialog on top by now. A plain pop would
        // close that topmost dialog instead of this one.
        final ownRoute = ModalRoute.of(context);
        if (ownRoute != null && !ownRoute.isCurrent) {
          Navigator.of(context).popUntil((r) => r == ownRoute);
        }
        Navigator.pop(context, password);
        Future.microtask(() => widget.onLogin(password, isAdmin));
      }
    } catch (e) {
      final repeater = _resolveRepeater(_connector);
      appLogger.warn(
        'Login error for ${repeater.name}: $e',
        tag: 'RepeaterLogin',
      );
      if (mounted) {
        setState(() {
          _isLoggingIn = false;
          _loginError = context.l10n.login_failedMessage;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final repeater = _resolveRepeater(connector);
    final isSavedContact = _resolveRepeaterIndex != -1;
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.cell_tower, color: Colors.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.login_repeaterLogin),
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
          if (!isSavedContact)
            IconButton(
              icon: const Icon(Icons.person_add),
              tooltip: l10n.contacts_addContact,
              onPressed: () {
                connector.importDiscoveredContact(widget.repeater);
                if (mounted) setState(() {});
              },
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
          : SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Web has no map packs service, so no map.
                  if (repeater.hasLocation && !PlatformInfo.isWeb) ...[
                    SizedBox(
                      height: 180,
                      child: ExcludeSemantics(
                        child: AppMap(
                          compact: true,
                          initialCamera: MapCamera(
                            center: LatLng(repeater.latitude!, repeater.longitude!),
                            zoom: 13,
                          ),
                          overlays: [
                            MapMarker(
                              id: 'repeater',
                              position: LatLng(repeater.latitude!, repeater.longitude!),
                              size: const Size(40, 40),
                              interactive: false,
                              child: const Icon(
                                Icons.cell_tower,
                                color: Colors.red,
                                size: 32,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  ],
                  Text(
                    l10n.login_repeaterDescription,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  if (_loginError != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error,
                          size: 18,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loginError!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
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
                    onChanged: (_) {
                      if (_loginError != null && mounted) {
                        setState(() {
                          _loginError = null;
                        });
                      }
                    },
                    onSubmitted: (_) => _handleLogin(),
                    autofocus:
                        !PlatformInfo.isMobile &&
                        _passwordController.text.isEmpty,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: _savePassword,
                    onChanged: (value) {
                      setState(() {
                        _savePassword = value ?? false;
                      });
                    },
                    title: Text(
                      l10n.login_savePassword,
                      style: const TextStyle(fontSize: 14),
                    ),
                    // subtitle: Text(
                    //   l10n.login_savePasswordSubtitle,
                    //   style: const TextStyle(fontSize: 12),
                    // ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
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
