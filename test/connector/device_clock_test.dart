import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';

// The firmware accepts CMD_SET_DEVICE_TIME only when the new time is at or
// after the radio's current time (MyMesh.cpp rejects anything earlier with
// ERR_CODE_ILLEGAL_ARG). So a radio running BEHIND can be corrected, and a
// radio running AHEAD cannot be corrected from the app at all — it can only be
// reported. Those two cases must never be conflated: the second one leaves the
// radio stamping every message it transmits with a future timestamp.
void main() {
  group('decideDeviceClockAction', () {
    test('a clock within tolerance is left alone', () {
      expect(
        MeshCoreConnector.decideDeviceClockAction(Duration.zero),
        DeviceClockAction.ok,
      );
      expect(
        MeshCoreConnector.decideDeviceClockAction(const Duration(seconds: 4)),
        DeviceClockAction.ok,
      );
      expect(
        MeshCoreConnector.decideDeviceClockAction(const Duration(seconds: -4)),
        DeviceClockAction.ok,
      );
    });

    test('exactly at tolerance is still left alone', () {
      expect(
        MeshCoreConnector.decideDeviceClockAction(
          MeshCoreConnector.deviceClockTolerance,
        ),
        DeviceClockAction.ok,
      );
    });

    test('a radio behind us is wound forward', () {
      expect(
        MeshCoreConnector.decideDeviceClockAction(const Duration(minutes: -20)),
        DeviceClockAction.windForward,
      );
      expect(
        MeshCoreConnector.decideDeviceClockAction(const Duration(hours: -3)),
        DeviceClockAction.windForward,
      );
    });

    // The case that used to be invisible: the app sent a SET, the firmware
    // refused it, and nothing checked the reply.
    test('a radio ahead of us is reported as uncorrectable', () {
      expect(
        MeshCoreConnector.decideDeviceClockAction(const Duration(minutes: 20)),
        DeviceClockAction.stuckAhead,
      );
      expect(
        MeshCoreConnector.decideDeviceClockAction(const Duration(days: 400)),
        DeviceClockAction.stuckAhead,
      );
    });

    test('one second past tolerance already acts', () {
      final justOver =
          MeshCoreConnector.deviceClockTolerance + const Duration(seconds: 1);
      expect(
        MeshCoreConnector.decideDeviceClockAction(justOver),
        DeviceClockAction.stuckAhead,
      );
      expect(
        MeshCoreConnector.decideDeviceClockAction(-justOver),
        DeviceClockAction.windForward,
      );
    });
  });
}
