import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';

/// Shown wherever the photo model is: the Stability AI Community License
/// (IV.a.iii) asks for it. A name, so not translated.
const String kPoweredByStability = 'Powered by Stability AI';

/// The photo model's NOTICE and licences, which its licences require to go
/// with it.
class PhotoLicencesScreen extends StatelessWidget {
  final Directory dir;

  const PhotoLicencesScreen({super.key, required this.dir});

  /// The NOTICE first, then the licences by name.
  List<File> get _files {
    if (!dir.existsSync()) return const [];
    int rank(File f) => f.uri.pathSegments.last.startsWith('NOTICE') ? 0 : 1;
    return dir.listSync().whereType<File>().toList()..sort(
      (a, b) => rank(a) != rank(b)
          ? rank(a).compareTo(rank(b))
          : a.path.compareTo(b.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    final files = _files;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.photo_licencesTitle),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            kPoweredByStability,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(context.l10n.photo_licencesIntro),
          const SizedBox(height: 12),
          if (files.isEmpty) Text(context.l10n.photo_licencesMissing),
          for (final f in files)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(f.uri.pathSegments.last),
              children: [
                SelectableText(
                  f.readAsStringSync(),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
