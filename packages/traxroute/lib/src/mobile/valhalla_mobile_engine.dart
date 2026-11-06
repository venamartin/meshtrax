import 'dart:convert';
import 'dart:io';

import '../engine.dart';
import '../route.dart';
import '../valhalla.dart';
import '../valhalla_defaults.dart';

/// Calls the app's native side: [method] with [argument], answering a
/// string. The shape of Flutter's `MethodChannel.invokeMethod<String>`.
typedef ValhallaInvoke =
    Future<String?> Function(String method, [Object? argument]);

/// Phones: Valhalla as a library inside the app (valhalla-mobile 0.6.x,
/// Valhalla 3.9.1 like the tiles), reached through the app's platform
/// channel. The config and the requests are the Linux engine's; the native
/// side only opens the config and runs requests, one at a time.
///
/// Channel methods:
/// - `open`: the config file's path. Closes the engine already open.
/// - `route`: a route request as JSON; answers Valhalla's JSON, or
///   `{"error": "<Valhalla's message>"}` when Valhalla finds no route.
/// - `close`.
class ValhallaMobileEngine implements RoutingEngine {
  final ValhallaInvoke invoke;
  final Directory workDir;

  bool _open = false;

  ValhallaMobileEngine({required this.invoke, required this.workDir});

  @override
  Future<void> open(File tiles) async {
    _open = false;
    workDir.createSync(recursive: true);
    final config = File('${workDir.path}/valhalla.json')
      ..writeAsStringSync(jsonEncode(valhallaConfig(tiles, workDir)));
    await invoke('open', config.absolute.path);
    _open = true;
  }

  @override
  Future<RouteResult> route(RouteRequest request) async {
    if (!_open) throw const RouteError('No routing data open');
    final String? body;
    try {
      body = await invoke('route', jsonEncode(valhallaRouteRequest(request)));
    } on Exception catch (e) {
      throw RouteError('The routing engine failed: $e');
    }
    if (body == null) {
      throw const RouteError('The routing engine gave no answer');
    }
    return parseValhallaRoute(
      request,
      jsonDecode(body) as Map<String, dynamic>,
    );
  }

  @override
  Future<void> close() async {
    _open = false;
    await invoke('close');
  }
}
