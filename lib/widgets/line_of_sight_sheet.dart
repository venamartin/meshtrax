import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:traxlos/traxlos.dart';

import '../helpers/geo_format.dart';
import '../helpers/position_text.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/line_of_sight.dart';
import '../services/line_of_sight_session.dart';
import '../services/map_packs_service.dart';
import '../utils/format_bytes.dart';
import 'elevation_profile.dart';
import 'route_sheet.dart';

/// The radio reach's shade: not green, which the map uses for parks.
Color losReachColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
    ? const Color(0xFFE040FB)
    : const Color(0xFFD500F9);

/// Each answer's colour, on the map and in the sheet. The word always goes
/// with it.
Color losVerdictColor(BuildContext context, Verdict verdict) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  return switch (verdict) {
    Verdict.clear => dark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32),
    Verdict.marginal =>
      dark ? const Color(0xFFFFCA28) : const Color(0xFFF9A825),
    Verdict.blocked => dark ? const Color(0xFFEF5350) : const Color(0xFFC62828),
    Verdict.unknown => dark ? const Color(0xFF9E9E9E) : const Color(0xFF757575),
  };
}

String losVerdictWord(AppLocalizations l10n, Verdict verdict) =>
    switch (verdict) {
      Verdict.clear => l10n.los_clear,
      Verdict.marginal => l10n.los_marginal,
      Verdict.blocked => l10n.los_blocked,
      Verdict.unknown => l10n.los_cantTell,
    };

/// The radio reach list's order: who can hear you first, Clear then
/// Marginal, then Blocked, then Can't tell, then a guessed position, which
/// has no answer ([a] or [b] null); nearest first within each.
int compareReachRows(Verdict? a, double aM, Verdict? b, double bM) {
  int rank(Verdict? v) => switch (v) {
    Verdict.clear => 0,
    Verdict.marginal => 1,
    Verdict.blocked => 2,
    Verdict.unknown => 3,
    null => 4,
  };
  final byAnswer = rank(a).compareTo(rank(b));
  return byAnswer != 0 ? byAnswer : aM.compareTo(bM);
}

/// How long ago [at] was: "Just now", "12m ago".
String losAge(AppLocalizations l10n, DateTime at, DateTime now) {
  final d = now.difference(at);
  if (d.inSeconds < 60) return l10n.time_justNow;
  if (d.inMinutes < 60) return l10n.time_minutesAgo(d.inMinutes);
  if (d.inHours < 24) return l10n.time_hoursAgo(d.inHours);
  return l10n.time_daysAgo(d.inDays);
}

/// An antenna height as the presets say it: "5 ft", "1.5 m".
String antennaHeightText(double metres, UnitSystem units) {
  if (units == UnitSystem.imperial) return '${(metres / 0.3048).round()} ft';
  if (metres >= 10) return '${metres.round()} m';
  final tenths = (metres * 10).round();
  return tenths % 10 == 0 ? '${tenths ~/ 10} m' : '${tenths / 10} m';
}

/// Line of sight or radio reach, in a sheet over the bottom of the map
/// that slides between a bar (the answer in a word and a sentence) and
/// open (the height profile, both ends and their antennas, the credits).
/// On a wide screen it is a panel at the [side] of the map instead, as the
/// route sheet is.
class LineOfSightSheet extends StatefulWidget {
  final LineOfSightSession session;
  final VoidCallback onClose;

  /// Opens Offline maps with these packs ticked.
  final ValueChanged<List<String>> onDownload;
  final bool side;

  /// As [RouteSheet.bottomInset].
  final double bottomInset;

  /// How much of the map's bottom the sheet covers, as it slides.
  final ValueChanged<double>? onHeight;

  /// For the ages of positions.
  final DateTime Function() clock;

  const LineOfSightSheet({
    super.key,
    required this.session,
    required this.onClose,
    required this.onDownload,
    this.side = false,
    this.bottomInset = 0,
    this.onHeight,
    this.clock = DateTime.now,
  });

  @override
  State<LineOfSightSheet> createState() => LineOfSightSheetState();
}

class LineOfSightSheetState extends State<LineOfSightSheet> {
  final _sheet = DraggableScrollableController();
  final _headerKey = GlobalKey();
  final _bodyKey = GlobalKey();
  ScrollController? _scroll;

  /// The bar's height and the whole sheet's, measured after each layout.
  double _bar = 96, _open = 320;

  /// The height the sheet slides in.
  double room = 0;

  /// Slid down to the bar: it stays there while answers change.
  bool _lowered = false;

  /// Where the next layout takes the sheet: back to rest.
  bool _toRest = true;

  /// Whether the sheet in the tree has its stops at [_bar] and [_open]:
  /// it can't go to a stop it wasn't built with.
  bool _stopsBuilt = false;

  @override
  void initState() {
    super.initState();
    _sheet.addListener(_onSlide);
  }

  @override
  void dispose() {
    _sheet.dispose();
    super.dispose();
  }

  double get _low => (_bar / room).clamp(0.0, 1.0);
  double get _top => (_open / room).clamp(_low, 1.0);

  /// Open, but never over more than 60% of the map: the rest scrolls.
  double get _rest => (math.min(_open, 0.6 * room) / room).clamp(_low, _top);

  var _reporting = false;

  /// Reports the sheet's height once the frame is done: it moves during
  /// layout.
  void _onSlide() {
    if (_reporting || widget.onHeight == null) return;
    _reporting = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reporting = false;
      if (!mounted || !_sheet.isAttached || room == 0) return;
      widget.onHeight?.call(_sheet.pixels + widget.bottomInset);
    });
  }

  /// How much of the map the sheet covers at rest, for fitting a line
  /// above it: measured now, as a new answer changes what it holds.
  double restHeight() {
    if (widget.side) return 0;
    _measure();
    if (!_sheet.isAttached || room == 0) return _open + widget.bottomInset;
    return (_lowered ? _low : _rest) * room + widget.bottomInset;
  }

  /// Brings a raised sheet back down; false when it wasn't raised.
  bool lower() {
    if (!_sheet.isAttached || room == 0 || _sheet.size <= _rest + 0.02) {
      return false;
    }
    _slideTo(_rest);
    return true;
  }

  void _toggle() {
    if (!_sheet.isAttached || room == 0) return;
    _lowered = _sheet.size > _low + 0.02;
    _slideTo(_lowered ? _low : _rest);
  }

  void _slideTo(double size) {
    if (size < 1 && (_scroll?.hasClients ?? false)) _scroll!.jumpTo(0);
    _sheet.animateTo(
      size,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  double _heightOf(GlobalKey key) =>
      (key.currentContext?.findRenderObject() as RenderBox?)?.size.height ?? 0;

  void _measure() {
    if (!mounted) return;
    final bar = _heightOf(_headerKey);
    if (bar == 0) return;
    final open = bar + _heightOf(_bodyKey);
    if (bar != _bar || open != _open) {
      setState(() {
        _bar = bar;
        _open = open;
        _toRest = true;
        _stopsBuilt = false;
      });
      return;
    }
    if (_toRest && _stopsBuilt && _sheet.isAttached && room > 0) {
      _toRest = false;
      _sheet.jumpTo(_lowered ? _low : _rest);
      _onSlide();
    }
  }

  @override
  Widget build(BuildContext context) {
    _units = context.watch<AppSettingsService>().settings.unitSystem;
    // A pack installed or removed changes what is missing.
    context.watch<MapPacksService>();
    return ListenableBuilder(
      listenable: widget.session,
      builder: (context, _) {
        if (widget.side) return _content(null);
        return Padding(
          padding: EdgeInsets.only(bottom: widget.bottomInset),
          child: LayoutBuilder(
            builder: (context, box) {
              if (box.maxHeight != room) {
                room = box.maxHeight;
                _toRest = true;
              }
              _stopsBuilt = true;
              WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
              final low = _low, top = _top, rest = _rest;
              return NotificationListener<DraggableScrollableNotification>(
                // Scaffold dims the map under a tall bottom sheet: not this
                // one.
                onNotification: (n) {
                  _lowered = n.extent <= low + 0.01;
                  return true;
                },
                child: DraggableScrollableSheet(
                  controller: _sheet,
                  expand: false,
                  shouldCloseOnMinExtent: false,
                  snap: true,
                  snapSizes: [if (rest - low > 0.02 && top - rest > 0.02) rest],
                  minChildSize: low,
                  initialChildSize: _lowered ? low : rest,
                  maxChildSize: top,
                  builder: (context, scroll) {
                    _scroll = scroll;
                    return ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          dragDevices: PointerDeviceKind.values.toSet(),
                        ),
                        child: _content(scroll),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _content(ScrollController? scroll) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerLow,
      child: SafeArea(
        top: false,
        right: false,
        // As the route sheet: the app bar would keep a tint from this.
        child: NotificationListener<ViewportNotificationMixin>(
          onNotification: (_) => true,
          child: CustomScrollView(
            controller: scroll,
            slivers: [
              PinnedHeaderSliver(
                child: KeyedSubtree(key: _headerKey, child: _header()),
              ),
              SliverToBoxAdapter(
                child: KeyedSubtree(key: _bodyKey, child: _body()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  LineOfSightSession get _s => widget.session;

  /// The units, read as the sheet builds.
  UnitSystem _units = UnitSystem.metric;

  Widget _header() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final s = _s;
    final from = s.from, to = s.to;
    final line = s.currentLine;
    final reach = s.mode == LosMode.reach;

    final Widget title;
    if (!reach && line != null) {
      title = _VerdictWord(line.verdict);
    } else {
      title = Text(
        switch ((reach, from?.kind)) {
          (false, _) => l10n.los_lineOfSight,
          (true, LosPlaceKind.me) => l10n.los_reachFromMe,
          (true, LosPlaceKind.contact) => l10n.los_reachFrom(from!.name!),
          (true, _) => l10n.los_reachFromHere,
        },
        style: theme.textTheme.titleMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final distance = !reach && from != null && to != null
        ? GeoFormat.distanceText(
            distanceM(geoOf(from.position), geoOf(to.position)),
            _units,
          )
        : null;

    return Material(
      color: scheme.surfaceContainerLow,
      child: InkWell(
        onTap: widget.side ? null : _toggle,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.side)
                const SizedBox(height: 8)
              else
                SizedBox(
                  height: 16,
                  child: Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  if (s.canGoBack)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.arrow_back),
                      tooltip: MaterialLocalizations.of(context)
                          .backButtonTooltip,
                      onPressed: s.backToReach,
                    ),
                  Expanded(
                    child: Align(alignment: Alignment.centerLeft, child: title),
                  ),
                  if (distance != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(distance, style: theme.textTheme.titleSmall),
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close),
                    tooltip: l10n.common_close,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(_sentence(l10n), style: theme.textTheme.bodyMedium),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 6, right: 12, bottom: 6),
                child: SizedBox(
                  height: 2,
                  child: s.busy
                      ? LinearProgressIndicator(
                          minHeight: 2,
                          value: reach ? s.progress : null,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The answer in a sentence, or what to do next.
  String _sentence(AppLocalizations l10n) {
    final s = _s;
    final from = s.from;
    if (from == null) return l10n.los_noPosition;
    if (s.mode == LosMode.reach) {
      final r = s.reach;
      if (r == null) return s.failed ? l10n.los_failed : l10n.los_checking;
      if (!r.centerGround.isKnown) {
        return _heightIssue(l10n, from, r.centerGround.issue);
      }
      return l10n.los_reachShaded(GeoFormat.distanceText(r.radiusM, _units));
    }
    final to = s.to;
    if (to == null) return l10n.los_pickTarget;
    final r = s.currentLine;
    if (r == null) return s.failed ? l10n.los_failed : l10n.los_checking;
    final fromMe = from.isMe;
    switch (r.verdict) {
      case Verdict.clear:
        return l10n.los_nothingInWay;
      case Verdict.marginal || Verdict.blocked:
        final d = r.deciding!;
        final distance = GeoFormat.distanceText(d.distanceM, _units);
        final above = d.aboveLineM;
        final height = GeoFormat.heightText(above.abs(), _units);
        final text = above > 0
            ? (fromMe
                  ? l10n.los_groundAbove(distance, height)
                  : l10n.los_groundAboveStart(distance, height))
            : (fromMe
                  ? l10n.los_groundWithin(distance, height)
                  : l10n.los_groundWithinStart(distance, height));
        return r.verdict == Verdict.marginal
            ? '$text ${l10n.los_higherHelps}'
            : text;
      case Verdict.unknown:
        if (r.notDownloaded.isNotEmpty) {
          return _missingSentence(
            l10n,
            _missingFor(r, () => pointsAlong(r.notDownloaded))!,
            r.notDownloaded.fold<double>(0, (sum, x) => sum + x.lengthM),
          );
        }
        if (!r.fromGround.isKnown) {
          return _heightIssue(l10n, from, r.fromGround.issue);
        }
        if (!r.toGround.isKnown) {
          return _heightIssue(l10n, to, r.toGround.issue);
        }
        return l10n.los_failed;
    }
  }

  String _heightIssue(AppLocalizations l10n, LosPlace at, HeightIssue? issue) {
    switch (issue) {
      case HeightIssue.belowLowestContour:
        return switch (at.kind) {
          LosPlaceKind.me => l10n.los_youBelowLowest,
          LosPlaceKind.contact => l10n.los_nameBelowLowest(at.name!),
          LosPlaceKind.point => l10n.los_spotBelowLowest,
        };
      case HeightIssue.noLinesNearby:
        return l10n.los_noLinesNear;
      case HeightIssue.notDownloaded || null:
        return _missingSentence(l10n, _missing([at.position]), null);
    }
  }

  MissingContours _missing(List<LatLng> points) =>
      missingContours(context.read<MapPacksService>(), _units, points);

  /// [_missing] for an answer, kept while the sheet shows that answer.
  (Object?, MissingContours?) _missingKept = (null, null);

  MissingContours? _missingFor(Object answer, List<LatLng> Function() points) {
    if (!identical(_missingKept.$1, answer)) {
      final p = points();
      _missingKept = (answer, p.isEmpty ? null : _missing(p));
    }
    return _missingKept.$2;
  }

  /// No contour lines for part of the line ([lengthM]) or of the area.
  String _missingSentence(
    AppLocalizations l10n,
    MissingContours missing,
    double? lengthM,
  ) {
    if (missing.offers.isEmpty && missing.noData) return l10n.los_noHeightData;
    final names = missing.offers.map((o) => o.region.name).join(', ');
    if (lengthM == null) {
      return names.isEmpty
          ? l10n.los_noContoursArea
          : l10n.los_noContoursAreaIn(names);
    }
    final length = GeoFormat.distanceText(lengthM, _units);
    return names.isEmpty
        ? l10n.los_noContours(length)
        : l10n.los_noContoursIn(length, names);
  }

  /// A good part of the reach can't be worked out (below sea level, say)
  /// and isn't shaded, for some reason other than contours not downloaded.
  bool _unknownUnexplained(MissingContours? missing) {
    final s = _s;
    final r = s.reach;
    if (s.mode != LosMode.reach || r == null || !r.centerGround.isKnown) {
      return false;
    }
    return (missing == null || missing.isEmpty) &&
        r.share(const {Verdict.unknown}) >= 0.1;
  }

  /// Where contours are missing for the answer shown, if anywhere.
  MissingContours? _missingNow() {
    final s = _s;
    final from = s.from;
    if (from == null) return null;
    if (s.mode == LosMode.reach) {
      final r = s.reach;
      if (r == null) return null;
      return _missingFor(
        r,
        () => uncoveredAround(
          losPacksFrom(context.read<MapPacksService>(), _units),
          from.position,
          r.radiusM,
        ),
      );
    }
    final r = s.currentLine;
    if (r == null || r.notDownloaded.isEmpty) return null;
    return _missingFor(r, () => pointsAlong(r.notDownloaded));
  }

  Widget _body() {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final s = _s;
    final units = _units;
    final reach = s.mode == LosMode.reach;
    final from = s.from;
    // The last answer stays, dimmed, while the next one is worked out, so
    // the sheet keeps its height.
    final line = reach ? null : s.currentLine ?? (s.busy ? s.line : null);
    final missing = _missingNow();
    final credits = reach ? s.reach?.credits : line?.credits;
    final small = theme.textTheme.bodySmall!.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Opacity(
        opacity: s.busy && !reach ? 0.35 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_unknownUnexplained(missing))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  l10n.los_reachUnknownPart,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            if (missing != null && !missing.isEmpty) ...[
              if (reach)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _missingSentence(l10n, missing, null),
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              _DownloadOffer(missing: missing, onDownload: widget.onDownload),
              const SizedBox(height: 12),
            ],
            if (line != null && line.profile.distancesM.length > 1) ...[
              SizedBox(
                height: 120,
                child: _Chart(line: line, units: units),
              ),
              const SizedBox(height: 8),
            ],
            if (from != null)
              _EndRow(
                label: reach ? l10n.los_thisRadio : l10n.los_from,
                place: _placeText(l10n, from),
                antenna: s.fromAntenna,
                units: units,
                onAntenna: s.setFromAntenna,
              ),
            if (!reach && s.to != null)
              _EndRow(
                label: l10n.los_to,
                place: _placeText(l10n, s.to!),
                antenna: s.toAntenna,
                units: units,
                onAntenna: s.setToAntenna,
              ),
            if (reach) ..._reachList(l10n, theme),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(child: Text(l10n.los_terrainOnly, style: small)),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.info_outline),
                  tooltip: l10n.los_aboutTitle,
                  onPressed: () => _showHelp(context),
                ),
              ],
            ),
            if (credits != null && credits.isNotEmpty)
              Text(l10n.los_credits(credits.join(' · ')), style: small),
          ],
        ),
      ),
    );
  }

  String _placeText(AppLocalizations l10n, LosPlace p) {
    final now = widget.clock();
    switch (p.kind) {
      case LosPlaceKind.me:
        return switch (p.source) {
          MyPosition.gps when p.seenAt != null => l10n.los_meAgo(
            losAge(l10n, p.seenAt!, now),
          ),
          MyPosition.notYetGps => l10n.los_meNotYetGps,
          _ => l10n.los_meByHand,
        };
      case LosPlaceKind.contact:
        return p.seenAt == null
            ? p.name!
            : l10n.los_nameAgo(p.name!, losAge(l10n, p.seenAt!, now));
      case LosPlaceKind.point:
        return p.name ??
            positionLines(
              p.position.latitude,
              p.position.longitude,
              coordFormatOf(context.read<AppSettingsService>().settings),
            ).first;
    }
  }

  List<Widget> _reachList(AppLocalizations l10n, ThemeData theme) {
    final s = _s;
    final r = s.reach;
    final units = _units;
    final radius = GeoFormat.distanceText(s.listRadiusM, units);
    // Who can hear you first, so they need no scrolling (owner,
    // 2026-11-18); a guessed position has no answer.
    final rows = <(LosPlace, LineOfSight?, double)>[
      if (r != null) ...[
        for (var i = 0; i < s.reachPeople.length; i++)
          (s.reachPeople[i], s.reachAnswers[i], s.reachAnswers[i].distanceM),
        for (final p in s.reachGuessed)
          (p, null, distanceM(r.center, geoOf(p.position))),
      ],
    ]..sort(
        (a, b) => compareReachRows(a.$2?.verdict, a.$3, b.$2?.verdict, b.$3),
      );
    final now = widget.clock();
    return [
      if (r != null && s.reachRadiusM < LineOfSightSession.farRadiusM)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: s.busy ? null : s.lookFurther,
            icon: const Icon(Icons.zoom_out_map),
            label: Text(
              l10n.los_lookFurther(
                GeoFormat.distanceText(LineOfSightSession.farRadiusM, units),
              ),
            ),
          ),
        ),
      if (r != null && rows.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(l10n.los_nobodyWithin(radius)),
        ),
      for (final (place, answer, distance) in rows)
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          title: Text(
            place.isMe ? l10n.los_me : place.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: switch (place.guessedVia) {
            final via? => Text(
              via.isEmpty
                  ? l10n.los_positionGuessed
                  : l10n.los_positionGuessedVia(via.join(', ')),
            ),
            null when place.seenAt != null => Text(
              losAge(l10n, place.seenAt!, now),
            ),
            null => null,
          },
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (answer != null) _VerdictWord(answer.verdict, small: true),
              const SizedBox(width: 12),
              SizedBox(
                width: 64,
                child: Text(
                  '${answer == null ? '~' : ''}'
                  '${GeoFormat.distanceText(distance, units)}',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          onTap: answer == null ? null : () => s.openLine(place),
        ),
    ];
  }
}

Future<void> _showHelp(BuildContext context) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    title: Text(context.l10n.los_aboutTitle),
    content: SingleChildScrollView(child: Text(context.l10n.los_helpBody)),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: Text(context.l10n.common_close),
      ),
    ],
  ),
);

/// The answer in a word, on its colour.
class _VerdictWord extends StatelessWidget {
  final Verdict verdict;
  final bool small;

  const _VerdictWord(this.verdict, {this.small = false});

  @override
  Widget build(BuildContext context) {
    final color = losVerdictColor(context, verdict);
    final text = Theme.of(context).textTheme;
    final onColor =
        ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 12,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        losVerdictWord(context.l10n, verdict),
        style: (small ? text.labelMedium : text.titleMedium)!.copyWith(
          color: onColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// One end: what it is, and its antenna.
class _EndRow extends StatelessWidget {
  final String label;
  final String place;
  final Antenna antenna;
  final UnitSystem units;
  final ValueChanged<Antenna> onAntenna;

  const _EndRow({
    required this.label,
    required this.place,
    required this.antenna,
    required this.units,
    required this.onAntenna,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56),
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                label,
                style: theme.textTheme.labelLarge!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              place,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          _AntennaButton(antenna: antenna, units: units, onChanged: onAntenna),
        ],
      ),
    );
  }
}

String _antennaName(AppLocalizations l10n, AntennaKind kind) => switch (kind) {
  AntennaKind.handHeld => l10n.los_handHeld,
  AntennaKind.vehicle => l10n.los_vehicle,
  AntennaKind.raised => l10n.los_raised,
};

class _AntennaButton extends StatelessWidget {
  final Antenna antenna;
  final UnitSystem units;
  final ValueChanged<Antenna> onChanged;

  const _AntennaButton({
    required this.antenna,
    required this.units,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    String height(AntennaKind kind) =>
        antennaHeightText(antenna.withKind(kind).metres, units);
    return PopupMenuButton<AntennaKind>(
      tooltip: l10n.los_antenna,
      initialValue: antenna.kind,
      onSelected: (kind) async {
        if (kind != AntennaKind.raised) {
          onChanged(antenna.withKind(kind));
          return;
        }
        final metres = await _askRaisedHeight(context, antenna.raisedM, units);
        if (metres != null) {
          onChanged(Antenna(AntennaKind.raised, raisedM: metres));
        }
      },
      itemBuilder: (context) => [
        for (final kind in AntennaKind.values)
          PopupMenuItem(
            value: kind,
            child: Text(
              '${_antennaName(l10n, kind)} · ${height(kind)}'
              '${kind == AntennaKind.raised ? '…' : ''}',
            ),
          ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              antenna.kind == AntennaKind.raised
                  ? '${_antennaName(l10n, antenna.kind)} · '
                        '${height(antenna.kind)}'
                  : _antennaName(l10n, antenna.kind),
              style: theme.textTheme.labelLarge!.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

/// The raised antenna's height, typed in [units]; null when cancelled.
Future<double?> _askRaisedHeight(
  BuildContext context,
  double metres,
  UnitSystem units,
) {
  final feet = units == UnitSystem.imperial;
  final unit = feet ? 'ft' : 'm';
  final shown = feet ? metres / 0.3048 : metres;
  final controller = TextEditingController(
    text: shown == shown.roundToDouble()
        ? '${shown.round()}'
        : shown.toStringAsFixed(1),
  );
  double? parse() {
    final v = double.tryParse(controller.text.trim().replaceAll(',', '.'));
    if (v == null || v <= 0) return null;
    return (feet ? v * 0.3048 : v).clamp(0.5, 300.0);
  }

  return showDialog<double>(
    context: context,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return AlertDialog(
        title: Text(l10n.los_raisedTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            labelText: l10n.los_raisedLabel,
            suffixText: unit,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(dialogContext, parse()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, parse()),
            child: Text(l10n.common_ok),
          ),
        ],
      );
    },
  );
}

/// What to download where contours are missing, or why it can't be now.
class _DownloadOffer extends StatelessWidget {
  final MissingContours missing;
  final ValueChanged<List<String>> onDownload;

  const _DownloadOffer({required this.missing, required this.onDownload});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final maps = context.watch<MapPacksService>();
    final offline =
        missing.noCatalogue ||
        (maps.status == CatalogueStatus.error && maps.drive == null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (missing.offers.isNotEmpty && !offline)
          FilledButton.tonalIcon(
            icon: const Icon(Icons.download_for_offline_outlined),
            onPressed: () =>
                onDownload([for (final o in missing.offers) o.pack.id]),
            label: Text(
              l10n.los_downloadContours(
                missing.offers.map((o) => o.region.name).join(', '),
                formatBytes(missing.bytes),
              ),
            ),
          )
        else if (missing.offers.isNotEmpty || missing.noCatalogue)
          Text(l10n.los_downloadBeforeTrip, style: theme.textTheme.bodyMedium),
        if (missing.noData && missing.offers.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(l10n.los_noHeightData),
          ),
      ],
    );
  }
}

/// The ground along the line with the earth's curve, the radio line, the
/// room the signal needs around it, and the spot that decides.
class _Chart extends StatelessWidget {
  final LineOfSight line;
  final UnitSystem units;

  const _Chart({required this.line, required this.units});

  @override
  Widget build(BuildContext context) {
    final r = line;
    final d = r.profile.distancesM;
    final g = r.profile.groundM;
    final start = r.lineAt(0), end = r.lineAt(r.distanceM);
    final deciding = r.verdict == Verdict.clear || r.verdict == Verdict.unknown
        ? null
        : r.deciding;
    return ElevationProfile(
      elevations: [for (var i = 0; i < d.length; i++) g[i] + r.bulgeAt(d[i])],
      distances: d,
      units: units,
      color: Theme.of(context).colorScheme.outline,
      line: start == null || end == null ? null : (start: start, end: end),
      band: start == null
          ? null
          : [for (var i = 0; i < d.length; i++) r.neededAt(d[i])],
      lineColor: losVerdictColor(context, r.verdict),
      mark: deciding?.distanceM,
    );
  }
}
