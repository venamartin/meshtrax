/// What one download fetches: a map pack (`PackIndexEntry`), or a file the
/// app installs itself ([DownloadFile]).
abstract interface class DownloadItem {
  String get id;

  /// Shown in download lists and the notification.
  String get name;

  /// The region it belongs to, a `picker.geojson` path; null when none.
  String? get region;

  Uri get url;
  int get bytes;
  String get sha256;

  /// Kept with the download across restarts, so it can be read back.
  Map<String, Object?> toJson();
}

/// A file downloaded beside the map packs that the app installs itself:
/// routing data, points of interest. The downloader fetches it, checks its
/// SHA-256 and reports it `PackDownloadState.downloaded` with its path; the
/// app installs it and calls `PackDownloader.finish`.
class DownloadFile implements DownloadItem {
  @override
  final String id;
  @override
  final String name;
  @override
  final String? region;
  @override
  final Uri url;
  @override
  final int bytes;
  @override
  final String sha256;

  /// What the app makes of it, e.g. `routing`.
  final String kind;

  /// Whatever the app needs to install it, JSON values only.
  final Map<String, Object?> payload;

  const DownloadFile({
    required this.id,
    required this.name,
    this.region,
    required this.url,
    required this.bytes,
    required this.sha256,
    required this.kind,
    this.payload = const {},
  });

  factory DownloadFile.fromJson(Map<String, Object?> j) => DownloadFile(
    id: j['id'] as String,
    name: j['name'] as String,
    region: j['region'] as String?,
    url: Uri.parse(j['url'] as String),
    bytes: (j['bytes'] as num).toInt(),
    sha256: j['sha256'] as String,
    kind: j['kind'] as String,
    payload: (j['payload'] as Map?)?.cast<String, Object?>() ?? const {},
  );

  /// Whether [json] is a [DownloadFile]'s, not a pack entry's.
  static bool isFile(Map<String, Object?> json) => json['type'] == 'file';

  @override
  Map<String, Object?> toJson() => {
    'type': 'file',
    'id': id,
    'name': name,
    'region': ?region,
    'url': url.toString(),
    'bytes': bytes,
    'sha256': sha256,
    'kind': kind,
    'payload': payload,
  };
}
