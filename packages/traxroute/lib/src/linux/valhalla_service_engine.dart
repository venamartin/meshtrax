import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../engine.dart';
import '../route.dart';
import '../valhalla.dart';
import 'valhalla_defaults.dart';

/// Linux: runs Valhalla's service program (`valhalla_service`, 3.9.x) on
/// the loopback interface and asks it for routes over HTTP. The program
/// comes from the same Valhalla build as the tiles.
///
/// A small shell watchdog owns the service: it ignores hang-ups, so the
/// service outlives the terminal that started the app, and it ends the
/// service as soon as the app is gone, so the service never outlives the
/// app. Each start takes a free port, so a stray service can't answer in
/// its place.
class ValhallaServiceEngine implements RoutingEngine {
  final String executable;
  final Directory workDir;

  Process? _watchdog;
  int? _port;
  final _client = HttpClient();

  ValhallaServiceEngine({required this.executable, required this.workDir});

  static const _watchdogScript = r'''
trap '' HUP
"$1" "$2" 1 >/dev/null 2>&1 &
service=$!
trap 'kill -9 $service 2>/dev/null; exit 0' TERM INT
while kill -0 "$3" 2>/dev/null && kill -0 "$service" 2>/dev/null; do
  sleep 1
done
kill -9 $service 2>/dev/null
''';

  @override
  Future<void> open(File tiles) async {
    await _stop();
    workDir.createSync(recursive: true);
    final free = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = free.port;
    await free.close();
    final config = jsonDecode(valhallaDefaults) as Map<String, dynamic>;
    (config['mjolnir'] as Map<String, dynamic>)
      ..['tile_extract'] = tiles.absolute.path
      ..['tile_dir'] = '${workDir.path}/none';
    (config['additional_data'] as Map<String, dynamic>)['elevation'] =
        '${workDir.path}/none/';
    (config['httpd'] as Map<String, dynamic>)['service'] = {
      ...(config['httpd'] as Map<String, dynamic>)['service'] as Map,
      'listen': 'tcp://127.0.0.1:$port',
      'loopback': 'ipc://${workDir.absolute.path}/loopback',
      'interrupt': 'ipc://${workDir.absolute.path}/interrupt',
      // The tiles are read-only: nothing to finish before stopping.
      'drain_seconds': 0,
      'shutdown_seconds': 0,
    };
    final configFile = File('${workDir.path}/valhalla.json')
      ..writeAsStringSync(jsonEncode(config));
    _watchdog = await Process.start('/bin/sh', [
      '-c',
      _watchdogScript,
      'meshtrax-routing',
      executable,
      configFile.path,
      '$pid',
    ]);
    unawaited(_watchdog!.stdout.drain<void>());
    unawaited(_watchdog!.stderr.drain<void>());
    _port = port;
    for (var i = 0; i < 100; i++) {
      try {
        await _get('/status');
        return;
      } on SocketException {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    await _stop();
    throw const RouteError('The routing service did not start');
  }

  @override
  Future<RouteResult> route(RouteRequest request) async {
    final port = _port;
    if (_watchdog == null || port == null) {
      throw const RouteError('No routing data open');
    }
    final String body;
    try {
      final req = await _client.post('127.0.0.1', port, '/route');
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(valhallaRouteRequest(request)));
      final res = await req.close();
      body = await res.transform(utf8.decoder).join();
    } on IOException catch (e) {
      throw RouteError('The routing service is not answering: $e');
    }
    return parseValhallaRoute(
      request,
      jsonDecode(body) as Map<String, dynamic>,
    );
  }

  Future<String> _get(String path) async {
    final res = await (await _client.get('127.0.0.1', _port!, path)).close();
    return res.transform(utf8.decoder).join();
  }

  Future<void> _stop() async {
    final w = _watchdog;
    _watchdog = null;
    _port = null;
    if (w == null) return;
    w.kill();
    await w.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        w.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
  }

  @override
  Future<void> close() async {
    await _stop();
    _client.close(force: true);
  }
}
