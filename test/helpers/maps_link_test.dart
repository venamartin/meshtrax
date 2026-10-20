import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/helpers/maps_link.dart';

void main() {
  const p = LatLng(47.0707, 15.4395);

  test('Google query forms', () {
    for (final url in [
      'https://www.google.com/maps?q=47.0707,15.4395',
      'https://maps.google.com/?q=47.0707,15.4395',
      'https://maps.google.com/maps?q=loc:47.0707,15.4395',
      'https://www.google.com/maps/search/?api=1&query=47.0707,15.4395',
      'https://www.google.com/maps/dir/?api=1&destination=47.0707,15.4395',
      'https://www.google.com/maps?ll=47.0707,15.4395&z=15',
      'www.google.com/maps?q=47.0707,15.4395',
    ]) {
      final r = MapsLink.parse(url);
      expect(r, isNotNull, reason: url);
      expect(r!.position, p, reason: url);
    }
  });

  test('Google place path carries the name', () {
    final r = MapsLink.parse(
      'https://www.google.com/maps/place/Hauptplatz+Graz/@47.0707,15.4395,17z/data=!3m1',
    );
    expect(r!.position, p);
    expect(r.name, 'Hauptplatz Graz');
  });

  test('Google @ path without place', () {
    final r = MapsLink.parse('https://www.google.com/maps/@47.0707,15.4395,15z');
    expect(r!.position, p);
    expect(r.name, isNull);
  });

  test('Google search by name has no position', () {
    expect(MapsLink.parse('https://www.google.com/maps?q=Hauptplatz+Graz'), isNull);
  });

  test('Apple Maps forms', () {
    final a = MapsLink.parse('https://maps.apple.com/?ll=47.0707,15.4395&q=Hauptplatz');
    expect(a!.position, p);
    expect(a.name, 'Hauptplatz');
    final b = MapsLink.parse('https://maps.apple.com/?q=47.0707,15.4395');
    expect(b!.position, p);
    final c = MapsLink.parse('https://maps.apple.com/place?coordinate=47.0707,15.4395&name=Graz');
    expect(c!.position, p);
    expect(c.name, 'Graz');
  });

  test('geo URIs', () {
    expect(MapsLink.parse('geo:47.0707,15.4395')!.position, p);
    final q = MapsLink.parse('geo:0,0?q=47.0707,15.4395(Hauptplatz)');
    expect(q!.position, p);
    expect(q.name, 'Hauptplatz');
    expect(MapsLink.parse('geo:47.0707,15.4395?z=14')!.position, p);
  });

  test('short links are recognised but carry nothing', () {
    const s = 'https://maps.app.goo.gl/AbCdEfGh1234';
    expect(MapsLink.isShortLink(s), isTrue);
    expect(MapsLink.isShortLink('https://goo.gl/maps/AbCd'), isTrue);
    expect(MapsLink.isShortLink('https://www.google.com/maps?q=1,2'), isFalse);
    expect(MapsLink.parse(s), isNull);
    expect(MapsLink.isMapsUrl(s), isTrue);
  });

  test('bounds', () {
    expect(MapsLink.parse('https://www.google.com/maps?q=91,15'), isNull);
    expect(MapsLink.parse('geo:47,181'), isNull);
  });

  test('findAll pulls links out of share text', () {
    final links = MapsLink.findAll(
      'Check out Hauptplatz\nhttps://maps.app.goo.gl/AbCd and geo:1,2',
    ).toList();
    expect(links, ['https://maps.app.goo.gl/AbCd', 'geo:1,2']);
  });
}
