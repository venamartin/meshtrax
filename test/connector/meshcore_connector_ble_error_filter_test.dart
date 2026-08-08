import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';

bool ignore({
  bool manualDisconnect = false,
  MeshCoreConnectionState state = MeshCoreConnectionState.connecting,
  MeshCoreTransportType activeTransport = MeshCoreTransportType.bluetooth,
  bool supersededByNewerAttempt = false,
}) {
  return MeshCoreConnector.shouldIgnoreLateBleConnectError(
    manualDisconnect: manualDisconnect,
    state: state,
    activeTransport: activeTransport,
    supersededByNewerAttempt: supersededByNewerAttempt,
  );
}

void main() {
  group('shouldIgnoreLateBleConnectError', () {
    test('ignores the error raised by the user disconnecting mid-sync', () {
      // Disconnect during _startBleInitialSync makes the next sendFrame throw.
      // Treating that as a dropped link cleared the manual flag and scheduled a
      // reconnect, so the app reconnected right after the user disconnected.
      expect(
        ignore(
          manualDisconnect: true,
          state: MeshCoreConnectionState.disconnected,
        ),
        isTrue,
      );
      expect(
        ignore(
          manualDisconnect: true,
          state: MeshCoreConnectionState.disconnecting,
        ),
        isTrue,
      );
    });

    test('ignores the error once a newer attempt owns the connector', () {
      expect(ignore(supersededByNewerAttempt: true), isTrue);
      expect(
        ignore(
          supersededByNewerAttempt: true,
          state: MeshCoreConnectionState.connected,
        ),
        isTrue,
      );
    });

    test('ignores the error once another transport took over', () {
      expect(ignore(activeTransport: MeshCoreTransportType.usb), isTrue);
      expect(ignore(activeTransport: MeshCoreTransportType.tcp), isTrue);
    });

    test('handles a genuine drop: not manual, still ours', () {
      expect(ignore(state: MeshCoreConnectionState.disconnected), isFalse);
      expect(ignore(state: MeshCoreConnectionState.connected), isFalse);
    });

    test('handles a failure of the attempt the user just started', () {
      // _manualDisconnect is cleared by connect(); state stays connecting until
      // the handshake finishes, so a real failure here must still tear down.
      expect(
        ignore(
          manualDisconnect: true,
          state: MeshCoreConnectionState.connecting,
        ),
        isFalse,
      );
    });
  });
}
