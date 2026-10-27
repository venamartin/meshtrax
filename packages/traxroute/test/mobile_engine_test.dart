import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:traxroute/traxroute.dart';

void main() {
  const ouray = (lat: 38.0228, lon: -107.6714);
  const campBird = (lat: 37.9706, lon: -107.7253);
  const request = RouteRequest([ouray, campBird], PathType.dirt);
  final answer = File(
    'test/fixtures/ouray_camp_bird_auto.json',
  ).readAsStringSync();

  late Directory tmp;
  late List<(String, Object?)> calls;
  late String? Function(String method, Object? argument) native;
  late ValhallaMobileEngine engine;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('traxroute-mobile');
    calls = [];
    native = (method, argument) => method == 'route' ? answer : null;
    engine = ValhallaMobileEngine(
      workDir: Directory('${tmp.path}/engine'),
      invoke: (method, [argument]) async {
        calls.add((method, argument));
        return native(method, argument);
      },
    );
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  test('opens the native engine on a config for the tile file', () async {
    final tiles = File('${tmp.path}/tiles.tar')..writeAsStringSync('');
    await engine.open(tiles);
    final (method, path) = calls.single;
    expect(method, 'open');
    final config =
        jsonDecode(File(path! as String).readAsStringSync())
            as Map<String, dynamic>;
    expect(config['mjolnir']['tile_extract'], tiles.absolute.path);
    expect(config['mjolnir']['tile_dir'], endsWith('/none'));
  });

  test("routes with Valhalla's answer from the native side", () async {
    await engine.open(File('${tmp.path}/tiles.tar'));
    final r = await engine.route(request);
    expect(r.km, closeTo(9.492, 1e-9));
    final sent = jsonDecode(calls.last.$2! as String) as Map<String, dynamic>;
    expect(sent['costing'], 'auto');
  });

  test("Valhalla's refusal is a RouteError with its message", () async {
    await engine.open(File('${tmp.path}/tiles.tar'));
    native = (method, argument) =>
        '{"error": "No path could be found for input"}';
    await expectLater(
      engine.route(request),
      throwsA(
        isA<RouteError>().having(
          (e) => e.message,
          'message',
          'No path could be found for input',
        ),
      ),
    );
  });

  test('a native failure is a RouteError', () async {
    await engine.open(File('${tmp.path}/tiles.tar'));
    native = (method, argument) =>
        method == 'route' ? throw Exception('channel') : null;
    await expectLater(engine.route(request), throwsA(isA<RouteError>()));
  });

  test('nothing open: no route, and closing closes', () async {
    await expectLater(engine.route(request), throwsA(isA<RouteError>()));
    await engine.open(File('${tmp.path}/tiles.tar'));
    await engine.close();
    expect(calls.last.$1, 'close');
    await expectLater(engine.route(request), throwsA(isA<RouteError>()));
  });
}
