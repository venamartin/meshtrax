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
class ValhallaServiceEngine implements RoutingEngine {
  final String executable;
  final Directory workDir;
  final int port;

  Process? _process;
  final _client = HttpClient();

  ValhallaServiceEngine({
    required this.executable,
    required this.workDir,
    this.port = 8771,
  });

  @override
  Future<void> open(File tiles) async {
    await _stop();
    workDir.createSync(recursive: true);
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
    };
    final configFile = File('${workDir.path}/valhalla.json')
      ..writeAsStringSync(jsonEncode(config));
    _process = await Process.start(executable, [configFile.path, '1']);
    unawaited(_process!.stdout.drain<void>());
    unawaited(_process!.stderr.drain<void>());
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
    if (_process == null) throw const RouteError('No routing data open');
    final req = await _client.post('127.0.0.1', port, '/route');
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode(valhallaRouteRequest(request)));
    final res = await req.close();
    final body = await res.transform(utf8.decoder).join();
    return parseValhallaRoute(
      request,
      jsonDecode(body) as Map<String, dynamic>,
    );
  }

  Future<String> _get(String path) async {
    final res = await (await _client.get('127.0.0.1', port, path)).close();
    return res.transform(utf8.decoder).join();
  }

  Future<void> _stop() async {
    final p = _process;
    _process = null;
    if (p == null) return;
    p.kill();
    await p.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        p.kill(ProcessSignal.sigkill);
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
