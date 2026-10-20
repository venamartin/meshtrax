import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:linkify/linkify.dart';
import 'package:meshtrax/helpers/link_handler.dart';

void main() {
  List<LinkifyElement> run(String text) => linkify(
        text,
        options: const LinkifyOptions(humanize: false, defaultToHttps: false),
        linkifiers: const [
          UrlLinkifier(),
          MeshCoreLinkifier(),
          CoordinateLinkifier(),
        ],
      );

  test('meshcore channel link becomes one element', () {
    const url =
        'meshcore://channel/add?name=SCCARC&secret=3350cbde34dd7687aafec7d3a97bdc95';
    final elements = run('join us: $url');
    final links = elements.whereType<MeshCoreLinkElement>().toList();
    expect(links, hasLength(1));
    expect(links.single.url, url);
  });

  test('coordinates become tappable, short numbers do not', () {
    final elements = run('meet at 47.070123, 15.440123 in 1.5, 2.5 hours');
    final coords = elements.whereType<CoordinateElement>().toList();
    expect(coords, hasLength(1));
    expect(coords.single.position, const LatLng(47.070123, 15.440123));
  });

  test('geo URI becomes tappable', () {
    final coords = run('here geo:47.0707,15.4395 ok')
        .whereType<CoordinateElement>()
        .toList();
    expect(coords.single.position, const LatLng(47.0707, 15.4395));
  });

  test('coordinates inside a maps URL stay part of the URL', () {
    final elements = run('https://www.google.com/maps?q=47.070123,15.440123');
    expect(elements.whereType<CoordinateElement>(), isEmpty);
    expect(elements.whereType<UrlElement>(), hasLength(1));
  });
}
