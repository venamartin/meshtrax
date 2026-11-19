import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_graph/path_graph.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/services/path_graph/path_graph_service.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

// The connector asks Pathfinder whether a repeater is a car repeater the
// user tagged, so a repeat of a channel message from one does not count
// (owner, 2026-11-19).
class _Connector extends MeshCoreConnector {
  @override
  String get selfPublicKeyHex => 'ab' * 32;
  @override
  int get pathHashByteWidth => 2;
  @override
  int? get currentFreqHz => 910525;
  @override
  int? get currentBwHz => 62500;
  @override
  int? get currentSf => 7;
  @override
  int? get currentCr => 5;
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
  });

  testWidgets('only the user\'s word makes a car repeater', (tester) async {
    final connector = _Connector();
    final service = PathGraphService();
    await tester.runAsync(() => service.start(connector,
        openDatabase: (_) => NativeDatabase.memory()));
    final graph = service.graph!;
    graph.setMovingOverride('A277', MovingOverride.moves);
    graph.setMovingOverride('beef', MovingOverride.withMe);
    graph.setMovingOverride('1000', MovingOverride.staysPut);

    final isCar = connector.isCarRepeater!;
    expect(isCar([0xA2, 0x77], 2), isTrue);
    expect(isCar([0xBE, 0xEF], 2), isTrue);
    expect(isCar([0x10, 0x00], 2), isFalse, reason: 'the user said it stays');
    expect(isCar([0xAD, 0x77], 2), isFalse, reason: 'never tagged');
    expect(isCar([0xA2, 0x77, 0x11], 3), isTrue,
        reason: 'a wider code is cut to the graph\'s width');
    expect(isCar([0xA2], 1), isFalse, reason: 'too short to name anyone');
    expect(isCar([0xA2, 0x77], 3), isFalse, reason: 'bytes and width disagree');

    await tester.runAsync(() => service.stop());
    expect(connector.isCarRepeater, isNull);
  });
}
