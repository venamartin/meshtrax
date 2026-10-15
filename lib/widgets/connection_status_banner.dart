import 'package:flutter/material.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';

/// Strip above a message list: sync progress, or the connection state
/// whenever the radio is not connected.
class ConnectionStatusBanner extends StatelessWidget {
  const ConnectionStatusBanner({
    super.key,
    required this.text,
    this.showSpinner = true,
    this.icon = Icons.bluetooth_disabled,
    this.onDismiss,
  });

  final String text;
  final bool showSpinner;
  final IconData icon;
  final VoidCallback? onDismiss;

  /// The warning for a radio another app is also driving, or null.
  static Widget? ifSecondApp(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    if (!connector.isConnected || !connector.secondAppSuspected) return null;
    return ConnectionStatusBanner(
      text: context.l10n.connection_secondApp,
      showSpinner: false,
      icon: Icons.devices_other,
      onDismiss: connector.dismissSecondAppWarning,
    );
  }

  /// The banner for a radio that is not connected, or null while it is.
  static Widget? ifDisconnected(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    if (connector.isConnected ||
        connector.state == MeshCoreConnectionState.disconnecting) {
      return null;
    }
    final l10n = context.l10n;
    if (!connector.willAutoReconnect) {
      return ConnectionStatusBanner(
        text: l10n.common_disconnected,
        showSpinner: false,
      );
    }
    return ConnectionStatusBanner(
      text: connector.state == MeshCoreConnectionState.connecting
          ? l10n.common_reconnecting
          : l10n.common_connectionLost,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colors.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: showSpinner
                ? CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.onPrimaryContainer,
                  )
                : Icon(icon, size: 16, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: colors.onPrimaryContainer,
              tooltip: context.l10n.common_close,
              visualDensity: VisualDensity.compact,
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
