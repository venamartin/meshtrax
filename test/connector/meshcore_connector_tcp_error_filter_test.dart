import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';

void main() {
  group('shouldIgnoreLateTcpConnectError', () {
    test('returns true for manual cancel during disconnecting state', () {
      final result = MeshCoreConnector.shouldIgnoreLateTcpConnectError(
        manualDisconnect: true,
        state: MeshCoreConnectionState.disconnecting,
        activeTransport: MeshCoreTransportType.bluetooth,
        tcpManagerConnected: false,
      );

      expect(result, isTrue);
    });

    test(
      'returns true for manual cancel after reaching disconnected state',
      () {
        final result = MeshCoreConnector.shouldIgnoreLateTcpConnectError(
          manualDisconnect: true,
          state: MeshCoreConnectionState.disconnected,
          activeTransport: MeshCoreTransportType.bluetooth,
          tcpManagerConnected: false,
        );

        expect(result, isTrue);
      },
    );

    test('returns false when not a manual disconnect', () {
      final result = MeshCoreConnector.shouldIgnoreLateTcpConnectError(
        manualDisconnect: false,
        state: MeshCoreConnectionState.disconnecting,
        activeTransport: MeshCoreTransportType.bluetooth,
        tcpManagerConnected: false,
      );

      expect(result, isFalse);
    });

    test('returns false for connected state handshake failures', () {
      final result = MeshCoreConnector.shouldIgnoreLateTcpConnectError(
        manualDisconnect: true,
        state: MeshCoreConnectionState.connected,
        activeTransport: MeshCoreTransportType.tcp,
        tcpManagerConnected: true,
      );

      expect(result, isFalse);
    });

    test('returns false when TCP is still active while disconnecting', () {
      final result = MeshCoreConnector.shouldIgnoreLateTcpConnectError(
        manualDisconnect: true,
        state: MeshCoreConnectionState.disconnecting,
        activeTransport: MeshCoreTransportType.tcp,
        tcpManagerConnected: true,
      );

      expect(result, isFalse);
    });
  });

  group('shouldResetStateAfterTcpConnectAbort', () {
    test('returns true when TCP connect is still in connecting state', () {
      final result = MeshCoreConnector.shouldResetStateAfterTcpConnectAbort(
        state: MeshCoreConnectionState.connecting,
        activeTransport: MeshCoreTransportType.tcp,
      );

      expect(result, isTrue);
    });

    test('returns false when state is already disconnected', () {
      final result = MeshCoreConnector.shouldResetStateAfterTcpConnectAbort(
        state: MeshCoreConnectionState.disconnected,
        activeTransport: MeshCoreTransportType.tcp,
      );

      expect(result, isFalse);
    });

    test('returns false when transport switched away from TCP', () {
      final result = MeshCoreConnector.shouldResetStateAfterTcpConnectAbort(
        state: MeshCoreConnectionState.connecting,
        activeTransport: MeshCoreTransportType.bluetooth,
      );

      expect(result, isFalse);
    });
  });

  group('shouldScheduleTcpReconnect', () {
    test('schedules for a non-manual drop of an established TCP session', () {
      final result = MeshCoreConnector.shouldScheduleTcpReconnect(
        manual: false,
        transportAtDisconnect: MeshCoreTransportType.tcp,
        sessionWasEstablished: true,
      );

      expect(result, isTrue);
    });

    test('never schedules for a manual disconnect', () {
      final result = MeshCoreConnector.shouldScheduleTcpReconnect(
        manual: true,
        transportAtDisconnect: MeshCoreTransportType.tcp,
        sessionWasEstablished: true,
      );

      expect(result, isFalse);
    });

    test('never schedules when the session was not established', () {
      // A failed first attempt to a wrong address must not retry forever.
      final result = MeshCoreConnector.shouldScheduleTcpReconnect(
        manual: false,
        transportAtDisconnect: MeshCoreTransportType.tcp,
        sessionWasEstablished: false,
      );

      expect(result, isFalse);
    });

    test('never schedules for other transports', () {
      for (final transport in [
        MeshCoreTransportType.bluetooth,
        MeshCoreTransportType.usb,
      ]) {
        final result = MeshCoreConnector.shouldScheduleTcpReconnect(
          manual: false,
          transportAtDisconnect: transport,
          sessionWasEstablished: true,
        );

        expect(result, isFalse, reason: 'transport=$transport');
      }
    });
  });

  group('shouldRetryTcpReconnectOnResume', () {
    test('brings a pending TCP reconnect forward', () {
      final result = MeshCoreConnector.shouldRetryTcpReconnectOnResume(
        state: MeshCoreConnectionState.disconnected,
        manualDisconnect: false,
        tcpReconnectPending: true,
      );

      expect(result, isTrue);
    });

    test('does nothing when no TCP reconnect is pending', () {
      // Covers both a fresh session (the last TCP endpoint survives
      // relaunch, so resume alone must not start connecting) and a pending
      // BLE reconnect, which must be left alone.
      final result = MeshCoreConnector.shouldRetryTcpReconnectOnResume(
        state: MeshCoreConnectionState.disconnected,
        manualDisconnect: false,
        tcpReconnectPending: false,
      );

      expect(result, isFalse);
    });

    test('does nothing after a manual disconnect', () {
      final result = MeshCoreConnector.shouldRetryTcpReconnectOnResume(
        state: MeshCoreConnectionState.disconnected,
        manualDisconnect: true,
        tcpReconnectPending: true,
      );

      expect(result, isFalse);
    });

    test('does nothing unless disconnected', () {
      for (final state in [
        MeshCoreConnectionState.connecting,
        MeshCoreConnectionState.connected,
        MeshCoreConnectionState.disconnecting,
      ]) {
        final result = MeshCoreConnector.shouldRetryTcpReconnectOnResume(
          state: state,
          manualDisconnect: false,
          tcpReconnectPending: true,
        );

        expect(result, isFalse, reason: 'state=$state');
      }
    });
  });
}
