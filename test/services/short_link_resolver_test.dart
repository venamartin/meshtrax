import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/services/short_link_resolver.dart';

void main() {
  const short = 'https://maps.app.goo.gl/AbCdEf';

  test('follows redirects to a URL with coordinates', () async {
    var calls = 0;
    final resolver = ShortLinkResolver(
      clientFactory: () => MockClient((request) async {
        calls++;
        if (request.url.toString() == short) {
          return http.Response('', 302, headers: {
            'location': 'https://www.google.com/maps/place/Hauptplatz/@47.0707,15.4395,17z',
          });
        }
        return http.Response('not reached', 200);
      }),
    );
    expect(resolver.cached(short), isNull);
    final position = await resolver.resolve(short);
    expect(position, const LatLng(47.0707, 15.4395));
    expect(resolver.cached(short), position);
    await resolver.resolve(short);
    expect(calls, 1, reason: 'answer is cached');
  });

  test('a chain that never yields coordinates resolves to null', () async {
    final resolver = ShortLinkResolver(
      clientFactory: () => MockClient((request) async {
        return http.Response('', 302, headers: {
          'location': 'https://www.google.com/maps?q=Hauptplatz',
        });
      }),
    );
    expect(await resolver.resolve(short), isNull);
    expect(resolver.cached(short), isNull);
  });

  test('network errors resolve to null', () async {
    final resolver = ShortLinkResolver(
      clientFactory: () => MockClient((_) async => throw Exception('offline')),
    );
    expect(await resolver.resolve(short), isNull);
  });

  test('listeners hear about a finished lookup', () async {
    final resolver = ShortLinkResolver(
      clientFactory: () => MockClient((_) async => http.Response('', 302,
          headers: {'location': 'https://maps.google.com/?q=1.2345,2.3456'})),
    );
    var notified = 0;
    resolver.addListener(() => notified++);
    await resolver.resolve(short);
    expect(notified, 1);
  });
}
