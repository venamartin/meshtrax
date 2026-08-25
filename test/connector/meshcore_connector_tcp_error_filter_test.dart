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
}
