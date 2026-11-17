import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';
import 'package:traxheard/traxheard.dart';

void main() {
  group('observerServerUri', () {
    test('a bare host gets https', () {
      expect(
        observerServerUri('analyzer.example.org').toString(),
        'https://analyzer.example.org/',
      );
    });

    test('a scheme, port and path are kept', () {
      expect(
        observerServerUri(' http://10.0.0.5:8080/mesh ').toString(),
        'http://10.0.0.5:8080/mesh/',
      );
    });

    test('not a web address', () {
      for (final address in ['', '   ', 'ftp://example.org', 'https://']) {
        expect(observerServerUri(address), isNull, reason: address);
      }
    });
  });

  test('asks for the hashes and reads who heard them', () async {
    late http.Request asked;
    final server = observerServer(
      ObserverServerKind.coreScope,
      'analyzer.example.org/mesh',
      client: MockClient((request) async {
        asked = request;
        return http.Response(
          jsonEncode({
            'results': {
              'aaaa000011112222': [
                {
                  'observer_id': 'obs-1',
                  'observer_name': 'Ridge',
                  'snr': -8.5,
                  'rssi': -110,
                  'path_json': '[]',
                  'timestamp': '2026-11-17T17:05:50Z',
                },
                {
                  'observer_id': 'obs-2',
                  'observer_name': '',
                  'snr': '6.25',
                  'path_json': '["A2","77"]',
                },
              ],
              'bbbb000011112222': [],
            },
          }),
          200,
        );
      }),
    )!;

    final found = await server.sightings(['AAAA000011112222', 'bbbb000011112222']);

    expect(asked.method, 'POST');
    expect(
      asked.url.toString(),
      'https://analyzer.example.org/mesh/api/packets/observations',
    );
    expect(jsonDecode(asked.body), {
      'hashes': ['aaaa000011112222', 'bbbb000011112222'],
    });
    expect(found.keys, ['aaaa000011112222'], reason: 'nobody heard bbbb');
    final [ridge, second] = found['aaaa000011112222']!;
    expect(ridge.observer, 'Ridge');
    expect(ridge.snr, -8.5);
    expect(ridge.rssi, -110);
    expect(ridge.hops, 0, reason: 'an empty path: it heard us directly');
    expect(ridge.heardAt, DateTime.utc(2026, 11, 17, 17, 5, 50));
    expect(second.observer, 'obs-2', reason: 'no name: its id');
    expect(second.snr, 6.25);
    expect(second.hops, 2);
    expect(second.heardAt, isNull);
  });

  test('more than 200 hashes take more than one request', () async {
    final sizes = <int>[];
    final server = observerServer(
      ObserverServerKind.coreScope,
      'analyzer.example.org',
      client: MockClient((request) async {
        sizes.add((jsonDecode(request.body)['hashes'] as List).length);
        return http.Response('{"results":{}}', 200);
      }),
    )!;
    await server.sightings([for (var i = 0; i < 450; i++) 'h$i']);
    expect(sizes, [200, 200, 50]);
  });

  test('no hashes, no request', () async {
    var requests = 0;
    final server = observerServer(
      ObserverServerKind.coreScope,
      'analyzer.example.org',
      client: MockClient((_) async {
        requests++;
        return http.Response('{"results":{}}', 200);
      }),
    )!;
    expect(await server.sightings(const []), isEmpty);
    expect(requests, 0);
  });

  test('an error answer throws', () async {
    final server = observerServer(
      ObserverServerKind.coreScope,
      'analyzer.example.org',
      client: MockClient((_) async => http.Response('nope', 503)),
    )!;
    await expectLater(server.sightings(['aa']), throwsA(isA<http.ClientException>()));
  });
}
