import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';

void main() {
  group('shouldSkipChannelFetch', () {
    test('skips when the map is both loaded and verified', () {
      expect(
        MeshCoreConnector.shouldSkipChannelFetch(
          hasLoadedChannels: true,
          channelsVerified: true,
          force: false,
        ),
        isTrue,
      );
    });

    // The reconnect regression: an unexpected BLE drop invalidates the slot
    // map (verified=false) and the reconnect fetches without force. Skipping
    // there left the map unverified for the rest of the session, which gates
    // every channel send — messages sat on the pending clock forever.
    test('fetches after a drop left the map loaded but unverified', () {
      expect(
        MeshCoreConnector.shouldSkipChannelFetch(
          hasLoadedChannels: true,
          channelsVerified: false,
          force: false,
        ),
        isFalse,
      );
    });

    test('fetches when nothing has been loaded yet', () {
      expect(
        MeshCoreConnector.shouldSkipChannelFetch(
          hasLoadedChannels: false,
          channelsVerified: false,
          force: false,
        ),
        isFalse,
      );
    });

    test('force always fetches', () {
      expect(
        MeshCoreConnector.shouldSkipChannelFetch(
          hasLoadedChannels: true,
          channelsVerified: true,
          force: true,
        ),
        isFalse,
      );
    });
  });
}
