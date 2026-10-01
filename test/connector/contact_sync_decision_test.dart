import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';

void main() {
  group('shouldSyncIncrementally', () {
    test('needs the toggle, a cached list and a stored cursor', () {
      expect(
        MeshCoreConnector.shouldSyncIncrementally(
          enabled: true,
          cachedCount: 312,
          cursor: 1790782801,
        ),
        isTrue,
      );
    });

    test('off when the toggle is off', () {
      expect(
        MeshCoreConnector.shouldSyncIncrementally(
          enabled: false,
          cachedCount: 312,
          cursor: 1790782801,
        ),
        isFalse,
      );
    });

    test('off with nothing cached — there is nothing to merge onto', () {
      expect(
        MeshCoreConnector.shouldSyncIncrementally(
          enabled: true,
          cachedCount: 0,
          cursor: 1790782801,
        ),
        isFalse,
      );
    });

    test('off without a cursor — the first full pass seeds it', () {
      expect(
        MeshCoreConnector.shouldSyncIncrementally(
          enabled: true,
          cachedCount: 312,
          cursor: 0,
        ),
        isFalse,
      );
    });
  });

  group('mergeSyncCursor', () {
    test('keeps the stored cursor when the radio reports 0 (nothing passed '
        'the filter)', () {
      expect(MeshCoreConnector.mergeSyncCursor(1790782801, 0), 1790782801);
    });

    test('moves forward to a newer lastmod', () {
      expect(MeshCoreConnector.mergeSyncCursor(1790782801, 1790790000),
          1790790000);
    });

    test('never moves backward', () {
      expect(MeshCoreConnector.mergeSyncCursor(1790790000, 1790782801),
          1790790000);
    });
  });
}
