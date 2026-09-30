import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';

void main() {
  group('shouldKeepAutoReconnect', () {
    test('a silent handshake on an automatic retry keeps the loop alive', () {
      // Field report: the radio at the edge of range linked but never
      // answered SELF_INFO. Treating that like a user attempt marked the
      // disconnect manual and ended reconnection with nothing on screen.
      expect(
        MeshCoreConnector.shouldKeepAutoReconnect(
          autoRetry: true,
          kind: MeshCoreBleFailure.handshakeTimeout,
        ),
        isTrue,
      );
    });

    test('a pairing failure stops the loop even on an automatic retry', () {
      expect(
        MeshCoreConnector.shouldKeepAutoReconnect(
          autoRetry: true,
          kind: MeshCoreBleFailure.pairingFailed,
        ),
        isFalse,
      );
    });

    test('a user attempt always stops so the scanner can show the error', () {
      for (final kind in MeshCoreBleFailure.values) {
        expect(
          MeshCoreConnector.shouldKeepAutoReconnect(
            autoRetry: false,
            kind: kind,
          ),
          isFalse,
          reason: kind.name,
        );
      }
    });
  });
}
