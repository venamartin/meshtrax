import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Downloads [url] to [to], checking it against [sha256] as it streams.
/// A mismatch deletes the file and throws.
///
/// Routing bundles and points of interest use this for the Linux test.
/// Phones will move them to the background downloader, as map packs use,
/// for resume and downloads that finish with the app closed.
Future<void> downloadVerified(
  http.Client client,
  Uri url,
  File to,
  String sha256Hex, {
  void Function(int received, int? total)? onProgress,
}) async {
  final response = await client.send(http.Request('GET', url));
  if (response.statusCode != 200) {
    throw HttpException('HTTP ${response.statusCode}', uri: url);
  }
  to.parent.createSync(recursive: true);
  final sink = to.openWrite();
  final digest = _DigestSink();
  final hasher = sha256.startChunkedConversion(digest);
  var received = 0;
  try {
    await for (final chunk in response.stream) {
      sink.add(chunk);
      hasher.add(chunk);
      received += chunk.length;
      onProgress?.call(received, response.contentLength);
    }
  } finally {
    await sink.close();
  }
  hasher.close();
  if (digest.value.toString() != sha256Hex) {
    to.deleteSync();
    throw HttpException('Checksum mismatch', uri: url);
  }
}

class _DigestSink implements Sink<Digest> {
  late Digest value;

  @override
  void add(Digest data) => value = data;

  @override
  void close() {}
}
