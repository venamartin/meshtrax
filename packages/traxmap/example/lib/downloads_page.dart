import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:traxmap/traxmap.dart';

/// "Get maps": the server's pack index, with download, pause, resume and
/// cancel. Example chrome only; MeshTrax builds its own screen from the same
/// [PackDownloader] calls.
class DownloadsPage extends StatefulWidget {
  final PackDownloader downloader;
  final PackManager manager;
  final Uri indexUrl;

  const DownloadsPage({
    super.key,
    required this.downloader,
    required this.manager,
    required this.indexUrl,
  });

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  PackIndex? _index;
  String? _error;
  Set<String> _installed = const {};
  late final StreamSubscription<PackDownload> _updates;

  @override
  void initState() {
    super.initState();
    _updates = widget.downloader.updates.listen((d) {
      if (d.state == PackDownloadState.installed) _loadInstalled();
      if (mounted) setState(() {});
    });
    _load();
  }

  @override
  void dispose() {
    _updates.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final index = await fetchIndex(widget.indexUrl);
      await _loadInstalled();
      if (mounted) setState(() => _index = index);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  Future<void> _loadInstalled() async {
    final ids = {for (final p in await widget.manager.listInstalled()) p.id};
    if (mounted) setState(() => _installed = ids);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Get maps')),
    body: switch ((_index, _error)) {
      (_, final String error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not read ${widget.indexUrl}\n\n$error'),
        ),
      ),
      (null, _) => const Center(child: CircularProgressIndicator()),
      (final PackIndex index, _) => ListView(
        children: [
          for (final entry in index.packs) _tile(entry),
          ListTile(
            dense: true,
            title: Text(
              'Index: ${widget.indexUrl}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    },
  );

  Widget _tile(PackIndexEntry entry) {
    final d = widget.downloader.downloads
        .where((d) => d.id == entry.id)
        .firstOrNull;
    final state = d?.state;
    final active = state != null && !state.isFinal;
    final mb = (entry.bytes / 1e6).toStringAsFixed(entry.bytes < 1e7 ? 1 : 0);
    final status = switch (state) {
      null || PackDownloadState.canceled =>
        _installed.contains(entry.id) ? 'installed' : null,
      PackDownloadState.running || PackDownloadState.paused =>
        '${state.name} · ${(d!.bytesDone / 1e6).toStringAsFixed(0)} of $mb MB',
      PackDownloadState.failed => 'failed: ${d!.error ?? 'unknown error'}',
      _ => state.name,
    };
    final dl = widget.downloader;
    return ListTile(
      title: Text(entry.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${entry.kind.name} · $mb MB${status == null ? '' : ' · $status'}',
          ),
          if (active)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: LinearProgressIndicator(value: d!.progress),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (state == PackDownloadState.running)
            IconButton(
              tooltip: 'Pause',
              icon: const Icon(Icons.pause),
              onPressed: () => dl.pause(entry.id),
            ),
          if (state == PackDownloadState.paused ||
              state == PackDownloadState.failed)
            IconButton(
              tooltip: 'Resume',
              icon: const Icon(Icons.play_arrow),
              onPressed: () => dl.resume(entry.id),
            ),
          if (active && state != PackDownloadState.verifying)
            IconButton(
              tooltip: 'Cancel',
              icon: const Icon(Icons.close),
              onPressed: () => dl.cancel(entry.id),
            ),
          if (!active && state != PackDownloadState.failed)
            IconButton(
              tooltip: _installed.contains(entry.id)
                  ? 'Download again'
                  : 'Download',
              icon: Icon(
                _installed.contains(entry.id)
                    ? Icons.download_done
                    : Icons.download,
              ),
              onPressed: () async {
                if (dl is BackgroundPackDownloader) {
                  await dl.requestNotificationPermission();
                }
                await dl.start(entry);
              },
            ),
        ],
      ),
    );
  }
}

/// Fetches and parses the pack index (dart:io, so no extra dependency).
Future<PackIndex> fetchIndex(Uri url) async {
  final client = HttpClient();
  try {
    final response = await (await client.getUrl(url)).close();
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode}', uri: url);
    }
    return PackIndex.parse(await response.transform(utf8.decoder).join());
  } finally {
    client.close();
  }
}
