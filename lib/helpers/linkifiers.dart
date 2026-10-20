import 'package:latlong2/latlong.dart';
import 'package:linkify/linkify.dart';

import 'maps_link.dart';
import 'structured_message.dart';

/// Linkifiers for the pieces of a message that are tappable and never
/// formatted inside: URLs, emails, meshcore:// links, coordinates, mentions
/// and hashtags, in the order they must run.
const messageLinkifiers = <Linkifier>[
  UrlLinkifier(),
  EmailLinkifier(),
  MeshCoreLinkifier(),
  CoordinateLinkifier(),
  MentionLinkifier(),
  HashtagLinkifier(),
];

/// Splits [TextElement]s on [pattern], turning each match into an element
/// built by [make]. Shared by the custom linkifiers below.
List<LinkifyElement> _splitOn(
  List<LinkifyElement> elements,
  RegExp pattern,
  LinkifyElement? Function(RegExpMatch match) make,
) {
  final list = <LinkifyElement>[];
  for (final element in elements) {
    if (element is! TextElement) {
      list.add(element);
      continue;
    }
    var lastIndex = 0;
    for (final match in pattern.allMatches(element.text)) {
      final made = make(match);
      if (made == null) continue;
      if (match.start > lastIndex) {
        list.add(TextElement(element.text.substring(lastIndex, match.start)));
      }
      list.add(made);
      lastIndex = match.end;
    }
    if (lastIndex < element.text.length) {
      list.add(TextElement(element.text.substring(lastIndex)));
    }
  }
  return list;
}

class MentionLinkifier extends Linkifier {
  const MentionLinkifier();

  static final _pattern = RegExp(r'@\[([^\]]+)\]');

  @override
  List<LinkifyElement> parse(List<LinkifyElement> elements, LinkifyOptions options) {
    return _splitOn(elements, _pattern, (m) => MentionElement(m.group(0)!));
  }
}

class MentionElement extends LinkableElement {
  MentionElement(String text) : super(text, text);
}

/// `meshcore://channel/add?...` and `meshcore://contact/add?...` links.
class MeshCoreLinkifier extends Linkifier {
  const MeshCoreLinkifier();

  static final _pattern = RegExp(r'meshcore://[^\s<>"]+');

  @override
  List<LinkifyElement> parse(List<LinkifyElement> elements, LinkifyOptions options) {
    return _splitOn(elements, _pattern, (m) => MeshCoreLinkElement(m.group(0)!));
  }
}

class MeshCoreLinkElement extends LinkableElement {
  MeshCoreLinkElement(String url) : super(url, url);
}

/// A standalone `lat, lon` token or `geo:` URI, tappable to open the map.
class CoordinateLinkifier extends Linkifier {
  const CoordinateLinkifier();

  static final _pattern = RegExp(
    '${StructuredMessage.coordinatePattern.pattern}|geo:[^\\s]+',
  );

  @override
  List<LinkifyElement> parse(List<LinkifyElement> elements, LinkifyOptions options) {
    return _splitOn(elements, _pattern, (m) {
      final text = m.group(0)!;
      final position = text.startsWith('geo:')
          ? MapsLink.parse(text)?.position
          : StructuredMessage.parseCoordinates(text);
      return position == null ? null : CoordinateElement(text, position);
    });
  }
}

class CoordinateElement extends LinkableElement {
  final LatLng position;
  CoordinateElement(String text, this.position) : super(text, text);
}

class HashtagLinkifier extends Linkifier {
  const HashtagLinkifier();

  static final _pattern = RegExp(r'#[a-zA-Z0-9_-]+');

  @override
  List<LinkifyElement> parse(List<LinkifyElement> elements, LinkifyOptions options) {
    return _splitOn(elements, _pattern, (m) => HashtagElement(m.group(0)!));
  }
}

class HashtagElement extends LinkableElement {
  HashtagElement(String text) : super(text, text);
}

/// A markdown `[text](https://…)` link: shows [text], opens [url].
class MaskedLinkElement extends LinkableElement {
  MaskedLinkElement(super.text, super.url);
}
