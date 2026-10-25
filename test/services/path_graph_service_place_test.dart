import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/services/path_graph/place_cell.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The graph learns where the radio is only as a cell, and only from a
// live fix of the radio's own GPS (owner, 2026-10-25: no precise location
// is stored; the phone's GPS is never asked).
class _Connector extends MeshCoreConnector {
  bool connected = true, gps = true, gpsIsOn = true, live = true;
  int? ver = 8;

  @override
  String get selfPublicKeyHex => 'ab' * 32;
  @override
  int get pathHashByteWidth => 2;
  @override
  bool get isConnected => connected;
  @override
  bool get hasGps => gps;
  @override
  bool get gpsOn => gpsIsOn;
  @override
  int? get firmwareVerCode => ver;
  @override
  bool get selfPositionIsLive => live;

  void fix(double lat, double lon) => selfGps.value =
      (latitude: lat, longitude: lon, altitude: 0, at: DateTime.now());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  const lat = 36.9712, lon = -121.7334;

  test('a live fix becomes a cell; losing it clears the cell', () async {
    final c = _Connector();
    final service = PathGraphService();
    await service.start(c, database: NativeDatabase.memory());
    final graph = service.graph!;
    expect(graph.currentCell, isNull);

    c.fix(lat, lon);
    final cell = PlaceCell.of(lat, lon);
    expect(graph.currentCell, cell.key);
    expect(graph.nearCells, {cell.key, ...cell.near});

    c.fix(lat + 0.05, lon); // a few kilometres: another cell
    expect(graph.currentCell, PlaceCell.of(lat + 0.05, lon).key);

    c.selfGps.value = null;
    expect(graph.currentCell, isNull);
    await service.stop();
  });

  test('every gate must hold: GPS present and on, firmware, a live reading',
      () async {
    final c = _Connector();
    final service = PathGraphService();
    await service.start(c, database: NativeDatabase.memory());
    final graph = service.graph!;

    for (final gate in [
      () => c.gps = false,
      () => c.gpsIsOn = false,
      () => c.ver = 5,
      () => c.live = false,
      () => c.connected = false,
    ]) {
      c.gps = true;
      c.gpsIsOn = true;
      c.ver = 8;
      c.live = true;
      c.connected = true;
      gate();
      c.selfGps.value = null;
      c.fix(lat, lon);
      expect(graph.currentCell, isNull);
    }
    await service.stop();
  });
}
