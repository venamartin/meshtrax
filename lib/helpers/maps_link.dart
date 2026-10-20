import 'package:latlong2/latlong.dart';

/// A position pulled out of a maps link, plus the place name when the link
/// carried one.
class MapsLinkResult {
  final LatLng position;
  final String? name;

  const MapsLinkResult(this.position, {this.name});
}

/// Reads coordinates out of the links people paste from Google Maps, Apple
/// Maps and `geo:` URIs. A Google short link (maps.app.goo.gl) carries no
/// coordinates at all; see [isShortLink] and ShortLinkResolver.
class MapsLink {
  static final _shortLink = RegExp(
    r'^(?:https?://)?(?:maps\.app\.goo\.gl|goo\.gl/maps)/\S+',
    caseSensitive: false,
  );

  static final _anyMapsUrl = RegExp(
    r'(?:https?://)?(?:'
    r'(?:www\.)?google\.[a-z.]+/maps\S*'
    r'|maps\.google\.[a-z.]+/?\S*'
    r'|maps\.apple\.com/\S*'
    r'|maps\.app\.goo\.gl/\S+'
    r'|goo\.gl/maps/\S+'
    r')|geo:[^\s]+',
    caseSensitive: false,
  );

  static final _pair =
      RegExp(r'^(-?\d{1,3}(?:\.\d+)?)\s*,\s*(-?\d{1,3}(?:\.\d+)?)');

  /// Every maps link or geo: URI found in [text], in order.
  static Iterable<String> findAll(String text) =>
      _anyMapsUrl.allMatches(text).map((m) => m.group(0)!);

  static bool isShortLink(String url) => _shortLink.hasMatch(url.trim());

  static bool isMapsUrl(String url) {
    final trimmed = url.trim();
    final m = _anyMapsUrl.firstMatch(trimmed);
    return m != null && m.start == 0 && m.end == trimmed.length;
  }

  /// Coordinates carried inside [url], or null when the link has none (a
  /// short link, or a search for a place name).
  static MapsLinkResult? parse(String url) {
    final trimmed = url.trim();
    if (trimmed.toLowerCase().startsWith('geo:')) return _parseGeo(trimmed);
    final withScheme =
        RegExp(r'^https?://', caseSensitive: false).hasMatch(trimmed)
            ? trimmed
            : 'https://$trimmed';
    final uri = Uri.tryParse(withScheme);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (host.endsWith('maps.apple.com')) return _parseApple(uri);
    if (host.contains('google.')) return _parseGoogle(uri);
    return null;
  }

  static MapsLinkResult? _parseGeo(String uri) {
    // geo:47.07,15.44  or  geo:0,0?q=47.07,15.44(Name)
    final body = uri.substring(4);
    final qIndex = body.indexOf('?');
    final head = qIndex < 0 ? body : body.substring(0, qIndex);
    final query = qIndex < 0 ? '' : body.substring(qIndex + 1);
    String? name;
    LatLng? fromQuery;
    for (final part in query.split('&')) {
      if (!part.startsWith('q=')) continue;
      final value = Uri.decodeQueryComponent(part.substring(2));
      final paren = value.indexOf('(');
      final coordsText = paren < 0 ? value : value.substring(0, paren);
      if (paren >= 0 && value.endsWith(')')) {
        name = value.substring(paren + 1, value.length - 1).trim();
      }
      fromQuery = _coords(coordsText);
      if (fromQuery == null && name == null && value.trim().isNotEmpty) {
        name = value.trim();
      }
    }
    final headCoords = _coords(head.split(';').first);
    final position = fromQuery ?? headCoords;
    if (position == null) return null;
    return MapsLinkResult(position, name: _cleanName(name));
  }

  static MapsLinkResult? _parseGoogle(Uri uri) {
    final q = uri.queryParameters;
    String? name;
    LatLng? position;
    for (final key in const [
      'q',
      'query',
      'll',
      'destination',
      'center',
      'daddr',
      'saddr',
    ]) {
      final value = q[key];
      if (value == null) continue;
      final coords = _coords(
        value.replaceFirst(RegExp(r'^loc:', caseSensitive: false), ''),
      );
      if (coords != null) {
        position ??= coords;
      } else if (key == 'q' || key == 'query') {
        name ??= value;
      }
    }
    final path = uri.path;
    final at = RegExp(r'/@(-?\d{1,3}(?:\.\d+)?),(-?\d{1,3}(?:\.\d+)?)')
        .firstMatch(path);
    if (at != null) {
      position ??= _coords('${at.group(1)},${at.group(2)}');
    }
    final place = RegExp(r'/place/([^/@]+)').firstMatch(path);
    if (place != null) {
      final raw = Uri.decodeComponent(place.group(1)!.replaceAll('+', ' '));
      if (_coords(raw) == null) name ??= raw;
    }
    if (position == null) return null;
    return MapsLinkResult(position, name: _cleanName(name));
  }

  static MapsLinkResult? _parseApple(Uri uri) {
    final q = uri.queryParameters;
    LatLng? position;
    String? name = q['name'];
    for (final key in const ['ll', 'coordinate', 'q', 'sll', 'daddr']) {
      final value = q[key];
      if (value == null) continue;
      final coords = _coords(value);
      if (coords != null) {
        position ??= coords;
      } else if (key == 'q') {
        name ??= value;
      }
    }
    if (position == null) return null;
    return MapsLinkResult(position, name: _cleanName(name));
  }

  static LatLng? _coords(String text) {
    final m = _pair.firstMatch(text.trim());
    if (m == null) return null;
    final lat = double.tryParse(m.group(1)!);
    final lon = double.tryParse(m.group(2)!);
    if (lat == null || lon == null) return null;
    if (lat.abs() > 90 || lon.abs() > 180) return null;
    return LatLng(lat, lon);
  }

  static String? _cleanName(String? name) {
    if (name == null) return null;
    final cleaned = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.isEmpty ? null : cleaned;
  }
}
