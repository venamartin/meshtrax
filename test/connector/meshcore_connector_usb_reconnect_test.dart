import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';

void main() {
  group('shouldScheduleUsbReconnect', () {
    test('schedules for a non-manual drop of a session the radio answered', () {
      final result = MeshCoreConnector.shouldScheduleUsbReconnect(
        manual: false,
        transportAtDisconnect: MeshCoreTransportType.usb,
        sessionWasEstablished: true,
      );

      expect(result, isTrue);
    });

    test('never schedules for a manual disconnect', () {
      final result = MeshCoreConnector.shouldScheduleUsbReconnect(
        manual: true,
        transportAtDisconnect: MeshCoreTransportType.usb,
        sessionWasEstablished: true,
      );

      expect(result, isFalse);
    });

    test('never schedules when no radio answered on the port', () {
      final result = MeshCoreConnector.shouldScheduleUsbReconnect(
        manual: false,
        transportAtDisconnect: MeshCoreTransportType.usb,
        sessionWasEstablished: false,
      );

      expect(result, isFalse);
    });

    test('never schedules for other transports', () {
      for (final transport in [
        MeshCoreTransportType.bluetooth,
        MeshCoreTransportType.tcp,
      ]) {
        final result = MeshCoreConnector.shouldScheduleUsbReconnect(
          manual: false,
          transportAtDisconnect: transport,
          sessionWasEstablished: true,
        );

        expect(result, isFalse, reason: 'transport=$transport');
      }
    });
  });
}
