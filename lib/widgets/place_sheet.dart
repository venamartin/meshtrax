import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traxcoords/traxcoords.dart';
import 'package:traxpoi/traxpoi.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/geo_format.dart';
import '../helpers/poi_kinds.dart';
import '../helpers/position_text.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';

/// A point of interest: its photo, type, Wikipedia text with credits and
/// position, and what to do with it. Everything comes from the download.
class PlaceSheet extends StatelessWidget {
  final PlaceDetail detail;
  final CoordFormat format;
  final UnitSystem units;

  /// Null where this device can't route.
  final VoidCallback? onRoute;
  final VoidCallback? onShare;

  /// A link in the Wikipedia text to another place or feature in the same
  /// download.
  final ValueChanged<SummaryLink>? onLink;
  final ScrollController? controller;

  const PlaceSheet({
    super.key,
    required this.detail,
    required this.format,
    required this.units,
    required this.onRoute,
    this.onShare,
    this.onLink,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final p = detail.place;
    final photo = detail.photo;
    final wiki = detail.wiki;
    final muted = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    // An unnamed place has its kind as the title already.
    final kind = [
      if (p.name.isNotEmpty) poiKindLabel(l10n, p.kind),
      ?p.detail,
      if (p.heritage?.startsWith('nrhp:') ?? false) l10n.place_nrhp,
    ].join(' · ');
    final lines = positionLines(p.lat, p.lon, format);

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.memory(
                  photo.webp,
                  width: 110,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name.isEmpty ? poiKindLabel(l10n, p.kind) : p.name,
                    style: theme.textTheme.titleLarge,
                  ),
                  if (kind.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(kind, style: theme.textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SelectableText(
                          [
                            lines.first,
                            if (p.ele != null)
                              GeoFormat.heightText(p.ele!.toDouble(), units),
                          ].join(' · '),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      CopyPositionButton(text: lines.first),
                    ],
                  ),
                  if (lines.length > 1) SelectableText(lines[1], style: muted),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (onRoute != null)
              FilledButton.icon(
                icon: const Icon(Icons.directions),
                label: Text(l10n.route_here),
                onPressed: onRoute,
              ),
            if (onShare != null)
              OutlinedButton.icon(
                icon: const Icon(Icons.share_location),
                label: Text(l10n.map_shareMarkerHere),
                onPressed: onShare,
              ),
          ],
        ),
        if (wiki != null) ...[
          const SizedBox(height: 16),
          _Summary(
            wiki.summary,
            onLink: onLink,
            trailing: TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.place_readOnWikipedia),
              onPressed: () => _openArticle(context, wiki.title),
            ),
          ),
        ],
        if (wiki != null || photo != null) ...[
          const SizedBox(height: 8),
          Text(
            [
              if (wiki != null) l10n.place_textCredit,
              if (photo != null)
                l10n.place_photoCredit(photo.author, photo.licence),
            ].join(' · '),
            style: muted,
          ),
        ],
      ],
    );
  }
}

/// The full article, in the browser (online only).
Future<void> _openArticle(BuildContext context, String title) async {
  final url = Uri.https(
    'en.wikipedia.org',
    '/wiki/${title.replaceAll(' ', '_')}',
  );
  if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
      context.mounted) {
    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.chat_couldNotOpenLink(url.toString())),
    );
  }
}

/// Copies a position as written, and says so.
class CopyPositionButton extends StatelessWidget {
  final String text;

  const CopyPositionButton({super.key, required this.text});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.copy, size: 20),
    tooltip: context.l10n.map_copyPosition,
    onPressed: () async {
      await Clipboard.setData(ClipboardData(text: text));
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.common_copiedToClipboard),
        );
      }
    },
  );
}

/// A Wikipedia lead (README: wiki) can run to many paragraphs: a few
/// lines, then More. [trailing] sits at the end of the More row.
class _Summary extends StatefulWidget {
  final String text;
  final ValueChanged<SummaryLink>? onLink;
  final Widget trailing;

  const _Summary(this.text, {required this.onLink, required this.trailing});

  @override
  State<_Summary> createState() => _SummaryState();
}

class _SummaryState extends State<_Summary> {
  bool _open = false;
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  TextSpan _span(SummaryRun run) {
    final link = run.link;
    final onLink = widget.onLink;
    TapGestureRecognizer? tap;
    if (link != null && onLink != null) {
      tap = TapGestureRecognizer()..onTap = () => onLink(link);
      _recognizers.add(tap);
    }
    return TextSpan(
      text: run.text,
      style: TextStyle(
        fontWeight: run.bold ? FontWeight.bold : null,
        fontStyle: run.italic ? FontStyle.italic : null,
        decoration: tap == null ? null : TextDecoration.underline,
      ),
      recognizer: tap,
    );
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final style = Theme.of(context).textTheme.bodyMedium!;
    final text = TextSpan(
      style: style,
      children: [for (final run in parseSummary(widget.text)) _span(run)],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: text,
          maxLines: 6,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final long = painter.didExceedMaxLines;
        painter.dispose();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              text,
              maxLines: _open ? null : 6,
              overflow: _open ? null : TextOverflow.ellipsis,
            ),
            Row(
              children: [
                if (long)
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => setState(() => _open = !_open),
                    child: Text(
                      _open
                          ? context.l10n.common_less
                          : context.l10n.common_more,
                    ),
                  ),
                const Spacer(),
                widget.trailing,
              ],
            ),
          ],
        );
      },
    );
  }
}
