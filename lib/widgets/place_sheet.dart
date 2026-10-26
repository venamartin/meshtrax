import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:traxcoords/traxcoords.dart';
import 'package:traxpoi/traxpoi.dart';

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
  final ScrollController? controller;

  const PlaceSheet({
    super.key,
    required this.detail,
    required this.format,
    required this.units,
    required this.onRoute,
    this.onShare,
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
    final kind = [
      poiKindLabel(l10n, p.kind),
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
                  const SizedBox(height: 4),
                  Text(kind, style: theme.textTheme.bodyMedium),
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
          _Summary(wiki.summary),
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

/// A Wikipedia lead can run to many paragraphs: a few lines, then More.
class _Summary extends StatefulWidget {
  final String text;

  const _Summary(this.text);

  @override
  State<_Summary> createState() => _SummaryState();
}

class _SummaryState extends State<_Summary> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 6,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);
        final long = painter.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: style,
              maxLines: _open ? null : 6,
              overflow: _open ? null : TextOverflow.ellipsis,
            ),
            if (long)
              TextButton(
                style: TextButton.styleFrom(padding: EdgeInsets.zero),
                onPressed: () => setState(() => _open = !_open),
                child: Text(
                  _open ? context.l10n.common_less : context.l10n.common_more,
                ),
              ),
          ],
        );
      },
    );
  }
}
