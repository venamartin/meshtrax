/// A download size in decimal units, as storage is sold: `840 kB`, `1.7 MB`,
/// `34 MB`, `1.2 GB`.
String formatBytes(int bytes) {
  if (bytes >= 1e9) return '${(bytes / 1e9).toStringAsFixed(1)} GB';
  if (bytes >= 1e7) return '${(bytes / 1e6).round()} MB';
  if (bytes >= 1e6) return '${(bytes / 1e6).toStringAsFixed(1)} MB';
  return '${(bytes / 1e3).round()} kB';
}
