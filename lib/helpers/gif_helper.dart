class GifHelper {
  static final _codePattern = RegExp(r'g:([A-Za-z0-9_-]{12,})');

  // Links must stand alone as a whitespace-separated token, so a GIF still
  // renders after a leading @[mention] or inside a reply body.
  static final _mediaUrlPattern = RegExp(
    r'(?<=^|\s)(?:https?:\/\/)?media\.giphy\.com\/media\/([A-Za-z0-9_-]+)\/giphy\.gif(?=\s|$)',
  );

  // Giphy understands page URLs with just the ID, or any string and a
  // dash before the ID, and redirects to a page with a dash-separated
  // title, a dash, and the ID. IDs in this form *probably* can't
  // contain dashes.
  static final _pageUrlPattern = RegExp(
    r'(?<=^|\s)(?:https?:\/\/)?(?:www\.)?giphy\.com\/gifs\/(?:[^/?\s]*-)?([A-Za-z0-9_]+)\/?(?=\s|$)',
  );

  static final _patterns = [_codePattern, _mediaUrlPattern, _pageUrlPattern];

  /// Parse a known GIF format, which can be any of:
  /// g:GIFID
  /// https://media.giphy.com/media/GIFID/giphy.gif
  /// https://giphy.com/gifs/Optional-title-with-dashes-GIFID
  ///
  /// GIFID is a Giphy GIF ID. The https:// is optional (and
  /// can also be http://). The giphy.com/gifs form can also
  /// include a trailing slash.
  ///
  /// Returns null if text contains no GIF
  static String? parseGif(String text) {
    for (final pattern in _patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }

  /// [text] with every GIF code or link removed, for display under the GIF.
  static String stripGif(String text) {
    var out = text;
    for (final pattern in _patterns) {
      out = out.replaceAll(pattern, '');
    }
    return out.trim();
  }

  /// Whether [text] is nothing but a GIF.
  static bool isGifOnly(String text) =>
      parseGif(text) != null && stripGif(text).isEmpty;

  /// Encode a GIF in a format that parseGif() can parse. A link is readable
  /// (and tappable) on apps that can't decode g: codes.
  static String encodeGif(String gifId, {bool asLink = false}) {
    return asLink ? 'https://giphy.com/gifs/$gifId' : 'g:$gifId';
  }
}
