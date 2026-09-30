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
  });

  final String text;
  final bool showSpinner;

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
                : Icon(
                    Icons.bluetooth_disabled,
                    size: 16,
                    color: colors.onPrimaryContainer,
                  ),
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
        ],
      ),
    );
  }
}
