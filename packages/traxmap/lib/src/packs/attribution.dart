import 'pack.dart';
import '../styles/style_registry.dart';

/// Credits for [packs], one per source and de-duplicated, as plain text
/// (HTML stripped). See [creditsIn].
List<String> attributionOf(Iterable<Pack> packs) =>
    creditsIn([for (final pack in packs) pack.attribution]);

/// [attributions] as plain-text credits (HTML stripped), one per source,
/// each shown once. Packs and routing regions join their sources' credits
/// with "; ", so data that shares a source (Copernicus in Hawaii's base,
/// contours and terrain) shows it once. A credit another one already holds
/// is left out: the street map's "© OpenMapTiles © OpenStreetMap
/// contributors" covers the routing data's OpenStreetMap credit.
List<String> creditsIn(Iterable<String?> attributions) {
  final out = <String>[];
  for (final raw in attributions) {
    if (raw == null) continue;
    for (final credit in _credits(_plain(raw))) {
      if (!out.contains(credit)) out.add(credit);
    }
  }
  return [
    for (final credit in out)
      if (!out.any((other) => other != credit && other.contains(credit)))
        credit,
  ];
}

/// [text] split into its sources' credits. Copernicus's own credit ends
/// "; all rights reserved", which stays with it.
List<String> _credits(String text) {
  final out = <String>[];
  for (final part in text.split('; ')) {
    final credit = part.trim();
    if (credit.isEmpty) continue;
    if (out.isNotEmpty &&
        credit.toLowerCase().startsWith('all rights reserved')) {
      out.last = '${out.last}; $credit';
    } else {
      out.add(credit);
    }
  }
  return out;
}

/// Notices the packs' licences require the app to show with the credits
/// (pack metadata `notice`), de-duplicated.
List<String> noticesOf(Iterable<Pack> packs) => noticesIn([
  for (final pack in packs)
    if (pack.metadata['notice'] case final String notice) notice,
]);

/// The distinct lines of [notices], each one notice per line.
List<String> noticesIn(Iterable<String?> notices) {
  final out = <String>[];
  for (final raw in notices) {
    if (raw == null) continue;
    for (final line in raw.split('\n')) {
      final text = line.trim();
      if (text.isNotEmpty && !out.contains(text)) out.add(text);
    }
  }
  return out;
}

/// The packs among [packs] that a resolved [style] actually draws from, so
/// an installed but unused pack (e.g. OSM under the USGS Topo style) isn't
/// credited.
List<Pack> packsUsedBy(
  Map<String, Object?> style,
  Iterable<Pack> packs,
  StyleContext context,
) {
  final urls = {
    for (final s in ((style['sources'] as Map?) ?? const {}).values)
      if (s is Map) ...sourceUrls(s),
  };
  return [
    for (final p in packs)
      if (urls.contains(context.pmtilesUrl(p))) p,
  ];
}

/// The pack URLs a resolved style source reads: `ovm:urls` when several
/// packs serve it, else its `url`.
List<String> sourceUrls(Map<Object?, Object?> source) {
  final many = source['ovm:urls'];
  if (many is List) return [for (final u in many) u as String];
  final one = source['url'];
  return one is String ? [one] : const [];
}

String _plain(String html) => html
    .replaceAll(RegExp(r'<[^>]*>'), '')
    .replaceAll('&copy;', '©')
    .replaceAll('&amp;', '&')
    .replaceAll('&nbsp;', ' ')
    .replaceAll(RegExp(r'\s+'), ' ')
    .trim();
