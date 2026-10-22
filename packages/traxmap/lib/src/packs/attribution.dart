import 'pack.dart';
import '../styles/style_registry.dart';

/// Credits for [packs], de-duplicated, as plain text (HTML stripped).
List<String> attributionOf(Iterable<Pack> packs) {
  final out = <String>[];
  for (final pack in packs) {
    final raw = pack.attribution;
    if (raw == null) continue;
    final text = _plain(raw);
    if (text.isNotEmpty && !out.contains(text)) out.add(text);
  }
  return out;
}

/// Notices the packs' licences require the app to show with the credits
/// (pack metadata `notice`, one per line), de-duplicated.
List<String> noticesOf(Iterable<Pack> packs) {
  final out = <String>[];
  for (final pack in packs) {
    final raw = pack.metadata['notice'];
    if (raw is! String) continue;
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
