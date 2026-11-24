import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

/// The MeshTrax report inbox. A report about a photo goes from inside the app
/// to the developer's inbox over the internet, as the app stores ask for
/// content that users share and content that AI makes. Nothing about the
/// person reporting is sent.
const String kReportInboxUrl = 'https://reports.meshtrax.io/v1/report';

/// A random id for a report, which the inbox uses to drop a report sent
/// twice.
String newReportId() {
  final random = Random.secure();
  return [
    for (var i = 0; i < 16; i++)
      random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}

/// This app's version and platform, as a report names them.
Future<({String app, String platform})> reportSource() async {
  final info = await PackageInfo.fromPlatform();
  return (
    app: 'MeshTrax ${info.version}+${info.buildNumber}',
    platform: Platform.operatingSystem,
  );
}

/// Sends one report. True once the inbox has it; false with no internet or
/// any other failure, so the report is kept and sent later.
Future<bool> postReport(
  Map<String, Object?> body, {
  http.Client? client,
}) async {
  final c = client ?? http.Client();
  try {
    final response = await c
        .post(
          Uri.parse(kReportInboxUrl),
          headers: {
            'content-type': 'application/json',
            'user-agent': 'MeshTrax',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));
    return response.statusCode == 202 || response.statusCode == 200;
  } on Object catch (_) {
    return false;
  } finally {
    if (client == null) c.close();
  }
}
