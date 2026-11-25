import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:traxwater/traxwater.dart' hide LatLon;

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';

/// The colour a trip on the water is drawn in on the chart: its own, so it
/// never reads as a route on land. It follows the chart's colours, which
/// stay light in the app's dark theme unless set otherwise.
Color waterRouteColor({required bool darkMap}) =>
    darkMap ? const Color(0xFFE1A6FF) : const Color(0xFF8E24AA);

const _ftPerM = 3.28084;

/// A distance on the water in nautical miles: "0.4 nm", "12.3 nm",
/// "1,242 nm"; under a tenth of a mile in feet or metres, as the units
/// setting says.
String waterDistanceText(double metres, UnitSystem units) {
  final nm = metres / 1852;
  return nm < 0.1
      ? depthText(metres, units)
      : nm < 100
      ? '${nm.toStringAsFixed(1)} nm'
      : '${NumberFormat('#,##0').format(nm.round())} nm';
}

/// A depth, draft or height in the units setting: "6 ft", "1.8 m".
String depthText(double metres, UnitSystem units) =>
    units == UnitSystem.imperial
    ? '${(metres * _ftPerM).round()} ft'
    : metres < 10
    ? '${metres.toStringAsFixed(1)} m'
    : '${metres.round()} m';

/// A draft that gets through, rounded down: "4 ft", "1.2 m".
String draftDownText(double metres, UnitSystem units) =>
    units == UnitSystem.imperial
    ? '${(metres * _ftPerM).floor()} ft'
    : '${((metres * 10).floor() / 10).toStringAsFixed(1)} m';

/// A charted depth band: "6–12 ft", "1.8–3.6 m"; the depth alone where
/// the band has no deep end.
String bandText(double from, double? to, UnitSystem units) => to == null
    ? depthText(from, units)
    : units == UnitSystem.imperial
    ? '${(from * _ftPerM).round()}–${(to * _ftPerM).round()} ft'
    : '${from.toStringAsFixed(1)}–${to.toStringAsFixed(1)} m';

/// "6", "6.5", "0.25".
String _number(double v) => v == v.roundToDouble()
    ? '${v.round()}'
    : v.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');

/// The boat in one line: "6 kn · 6 ft draft + 2 ft · 1 nm off land".
String boatSummary(
  AppLocalizations l10n,
  WaterRouteOptions o,
  UnitSystem units,
) => [
  '${_number(o.speedKn)} kn',
  l10n.water_boatDraft(
    depthText(o.draftM, units),
    depthText(o.underKeelM, units),
  ),
  if (o.offLandNm case final nm?) l10n.water_boatOffLand('${_number(nm)} nm'),
  if (o.mastHeightM case final m?) l10n.water_boatMast(depthText(m, units)),
].join(' · ');

/// What a chart calls an area or object, where it has no name of its own.
String chartClassLabel(AppLocalizations l10n, WaterArea area) =>
    switch (area.chartClass) {
      'RESARE' => l10n.water_classRestricted,
      'CTNARE' => l10n.water_classCaution,
      'MIPARE' => l10n.water_classMilitary,
      'ACHARE' => l10n.water_classAnchorage,
      'DMPGRD' => l10n.water_classDumping,
      'TSSLPT' => l10n.water_classTrafficLane,
      'TSEZNE' => l10n.water_classSeparation,
      'PRCARE' => l10n.water_classPrecautionary,
      'ISTZNE' => l10n.water_classInshoreTraffic,
      'MARCUL' => l10n.water_classMarineFarm,
      'BRIDGE' => l10n.water_classBridge,
      'CBLOHD' => l10n.water_classCable,
      'PIPOHD' => l10n.water_classPipe,
      'CONVYR' => l10n.water_classConveyor,
      'GATCON' => l10n.water_classGate,
      final other => area.info ?? other,
    };

/// Why a trip's end moved from the point picked.
String _whyMoved(AppLocalizations l10n, EndMoved why) => switch (why) {
  EndMoved.notInWater => l10n.water_movedLand,
  EndMoved.depth => l10n.water_movedShallow,
  EndMoved.hazard => l10n.water_movedHazard,
  EndMoved.noEntry => l10n.water_movedNoEntry,
  EndMoved.mastHeight => l10n.water_movedMast,
};

/// The notes over a trip: ends moved off the points picked, and why it
/// ends short of [destination].
List<String> waterTripNotes(
  AppLocalizations l10n,
  WaterTrip trip,
  String destination,
  UnitSystem units,
) {
  String distance(double m) => waterDistanceText(m, units);
  return [
    if (trip.from case WaterEnd(:final moved?, :final movedM)
        when _worthSaying(moved, movedM))
      l10n.water_startMoved(distance(movedM), _whyMoved(l10n, moved)),
    if (trip.to case WaterEnd(:final moved?, :final movedM)
        when trip.endsShort == null && _worthSaying(moved, movedM))
      l10n.water_endMoved(distance(movedM), _whyMoved(l10n, moved)),
    if (trip.endsShort case final short?)
      _endsShort(l10n, short, distance(short.remainingM), destination, units),
  ];
}

/// A point picked on the shore moves to the water beside it: under 100 m,
/// as on land, that goes without saying. The boat's limits always say.
bool _worthSaying(EndMoved why, double movedM) =>
    why != EndMoved.notInWater || movedM > 100;

String _endsShort(
  AppLocalizations l10n,
  EndsShort short,
  String distance,
  String destination,
  UnitSystem units,
) => switch (short.reason) {
  EndsShortReason.depth => switch ((short.deepestWayM, short.deepestDraftM)) {
    (final depth?, final draft?) when draft > 0 => l10n.water_endsShortDepth(
      distance,
      destination,
      bandText(depth, short.deepestWayToM, units),
      draftDownText(draft, units),
    ),
    (final depth?, _) => l10n.water_endsShortTooShallow(
      distance,
      destination,
      bandText(depth, short.deepestWayToM, units),
    ),
    _ => l10n.water_endsShortTooShallow(distance, destination, '—'),
  },
  EndsShortReason.mastHeight => l10n.water_endsShortMast(
    distance,
    destination,
    {for (final o in short.lowObjects) o.name ?? chartClassLabel(l10n, o)}
        .join(', '),
  ),
  EndsShortReason.noConnection => l10n.water_endsShortNoWater(
    distance,
    destination,
  ),
  EndsShortReason.tooLong => l10n.water_endsShortTooLong(distance, destination),
};

/// What a trip passes: its least depth and lowest clearance, the
/// stretches shallower than preferred or poorly surveyed, and where it
/// couldn't keep its distance off land; then one row that opens to the
/// bridges and objects it goes under and the areas it runs through.
class WaterTripPasses extends StatelessWidget {
  final WaterTrip trip;
  final WaterRouteOptions boat;
  final UnitSystem units;

  const WaterTripPasses({
    super.key,
    required this.trip,
    required this.boat,
    required this.units,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    String distance(double m) => waterDistanceText(m, units);
    String name(WaterArea a) => a.name ?? chartClassLabel(l10n, a);
    final poor = [4, 5, 6].fold(0.0, (sum, z) => sum + (trip.surveyM[z] ?? 0));
    final offLand = trip.offLand;
    final low = trip.lowestClearance;

    // A bridge charted twice, or an area cut by a chart's edge, is one row.
    final overhead = <String>{
      for (final a in trip.areas)
        if (a.area.isOverhead)
          [
            name(a.area),
            if (a.area.clearanceM case final c?) depthText(c, units),
            if (a.note == BridgeNote.needsOpening) l10n.water_needsOpening,
          ].join(' · '),
    };
    final areas = <String, double>{};
    for (final a in trip.areas) {
      if (a.area.isOverhead) continue;
      final label = chartClassLabel(l10n, a.area);
      final text = a.area.name == null ? label : '${a.area.name} · $label';
      areas[text] = (areas[text] ?? 0) + a.metres;
    }
    final byMiles = areas.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (trip.leastDepthM case final depth?)
          _PassRow(
            Symbols.water,
            l10n.water_leastDepth(bandText(depth, trip.leastDepthToM, units)),
          ),
        if (low?.clearanceM case final clearance?)
          _PassRow(
            Symbols.height,
            low!.object == null
                ? l10n.water_lowestClearance(depthText(clearance, units))
                : l10n.water_lowestClearanceUnder(
                    depthText(clearance, units),
                    name(low.object!),
                  ),
          ),
        if (low != null && low.uncharted > 0)
          _PassRow(
            Symbols.help_outline,
            l10n.water_unchartedSpans(low.uncharted),
          ),
        if (trip.shallowerThanPreferredM case final m? when m >= 1)
          _PassRow(
            Symbols.vertical_align_bottom,
            l10n.water_shallower(depthText(boat.preferDepthM!, units)),
            distance(m),
          ),
        if (poor >= 1)
          _PassRow(Symbols.query_stats, l10n.water_poorSurvey, distance(poor)),
        if (offLand != null && offLand.insideElsewhereM >= 1)
          _OpensRow(
            icon: Symbols.landscape,
            text: l10n.water_couldntKeep('${_number(offLand.distanceNm)} nm'),
            trailing: distance(offLand.insideElsewhereM),
            children: [
              for (final s in offLand.couldntKeep)
                Text(
                  l10n.water_stretch(distance(s.metres), distance(s.fromM)),
                  style: _muted(context),
                ),
            ],
          ),
        if (trip.magneticModelExpired)
          _PassRow(Symbols.explore, l10n.water_magneticModelOld),
        if (overhead.isNotEmpty || byMiles.isNotEmpty)
          _OpensRow(
            icon: Symbols.format_list_bulleted,
            text: l10n.water_onTheWay,
            trailing: '${overhead.length + byMiles.length}',
            children: [
              for (final text in overhead) _PassRow(Symbols.road, text),
              for (final e in byMiles)
                _PassRow(Symbols.select, e.key, distance(e.value)),
            ],
          ),
      ],
    );
  }
}

TextStyle _muted(BuildContext context) {
  final theme = Theme.of(context);
  return theme.textTheme.bodyMedium!.copyWith(
    color: theme.colorScheme.onSurfaceVariant,
  );
}

/// A line of what a trip passes: its icon, text and miles.
class _PassRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? trailing;

  const _PassRow(this.icon, this.text, [this.trailing]);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text)),
        if (trailing case final t?) ...[
          const SizedBox(width: 8),
          Text(t, style: _muted(context)),
        ],
      ],
    ),
  );
}

/// A line of what a trip passes that opens to what it adds up.
class _OpensRow extends StatefulWidget {
  final IconData icon;
  final String text;
  final String trailing;
  final List<Widget> children;

  const _OpensRow({
    required this.icon,
    required this.text,
    required this.trailing,
    required this.children,
  });

  @override
  State<_OpensRow> createState() => _OpensRowState();
}

class _OpensRowState extends State<_OpensRow> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(widget.icon, size: 18, color: muted),
                const SizedBox(width: 12),
                Expanded(child: Text(widget.text)),
                const SizedBox(width: 8),
                Text(widget.trailing, style: _muted(context)),
                Icon(
                  _open ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: muted,
                ),
              ],
            ),
          ),
        ),
        if (_open)
          for (final child in widget.children)
            Padding(
              padding: const EdgeInsets.only(left: 30, top: 2, bottom: 2),
              child: child,
            ),
      ],
    );
  }
}

/// A leg of the trip: its course in degrees magnetic, distance and time.
class WaterLegTile extends StatelessWidget {
  final WaterLeg leg;
  final String time;
  final UnitSystem units;

  const WaterLegTile({
    super.key,
    required this.leg,
    required this.time,
    required this.units,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(
      '${leg.courseMagnetic.round() % 360}°M · '
      '${waterDistanceText(leg.distanceM, units)}',
    ),
    trailing: Text(time),
  );
}

/// The boat's speed, depths, distance off land, what to avoid and its mast
/// height, remembered for every trip on the water.
class WaterRouteOptionsSection extends StatelessWidget {
  final WaterRouteOptions options;
  final UnitSystem units;
  final ValueChanged<WaterRouteOptions> onChanged;

  const WaterRouteOptionsSection({
    super.key,
    required this.options,
    required this.units,
    required this.onChanged,
  });

  /// Feet or metres, as the units setting says, for what's typed in.
  double get _unit => units == UnitSystem.imperial ? 1 / _ftPerM : 1;
  String get _unitLabel => units == UnitSystem.imperial ? 'ft' : 'm';

  WaterRouteOptions _with({
    double? speedKn,
    double? draftM,
    double? underKeelM,
    double? Function()? preferDepthM,
    double? Function()? offLandNm,
    double? Function()? mastHeightM,
    bool? avoidTrafficLanes,
    bool? avoidSecurityZones,
    bool? avoidOpeningBridges,
  }) => WaterRouteOptions(
    speedKn: speedKn ?? options.speedKn,
    draftM: draftM ?? options.draftM,
    underKeelM: underKeelM ?? options.underKeelM,
    preferDepthM: preferDepthM == null ? options.preferDepthM : preferDepthM(),
    offLandNm: offLandNm == null ? options.offLandNm : offLandNm(),
    mastHeightM: mastHeightM == null ? options.mastHeightM : mastHeightM(),
    avoidTrafficLanes: avoidTrafficLanes ?? options.avoidTrafficLanes,
    avoidSecurityZones: avoidSecurityZones ?? options.avoidSecurityZones,
    avoidOpeningBridges: avoidOpeningBridges ?? options.avoidOpeningBridges,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    double? inUnits(double? m) =>
        m == null ? null : double.parse((m / _unit).toStringAsFixed(1));
    Widget label(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Text(text, style: theme.textTheme.labelLarge),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NumberRow(
          label: l10n.water_speed,
          value: options.speedKn,
          unit: 'kn',
          onChanged: (v) {
            if (v != null && v > 0) onChanged(_with(speedKn: v));
          },
        ),
        _NumberRow(
          label: l10n.water_draft,
          value: inUnits(options.draftM),
          unit: _unitLabel,
          onChanged: (v) {
            if (v != null && v > 0) onChanged(_with(draftM: v * _unit));
          },
        ),
        _NumberRow(
          label: l10n.water_underKeel,
          value: inUnits(options.underKeelM),
          unit: _unitLabel,
          onChanged: (v) {
            if (v != null && v >= 0) onChanged(_with(underKeelM: v * _unit));
          },
        ),
        _NumberRow(
          label: l10n.water_preferDepth,
          value: inUnits(options.preferDepthM),
          unit: _unitLabel,
          hint: l10n.water_none,
          onChanged: (v) => onChanged(
            _with(preferDepthM: () => v == null || v <= 0 ? null : v * _unit),
          ),
        ),
        _NumberRow(
          label: l10n.water_mastHeight,
          value: inUnits(options.mastHeightM),
          unit: _unitLabel,
          hint: l10n.water_none,
          onChanged: (v) => onChanged(
            _with(mastHeightM: () => v == null || v <= 0 ? null : v * _unit),
          ),
        ),
        label(l10n.water_offLand),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final nm in [null, ...ringsNm])
              ChoiceChip(
                label: Text(nm == null ? l10n.water_none : '${_number(nm)} nm'),
                selected: options.offLandNm == nm,
                onSelected: (_) => onChanged(_with(offLandNm: () => nm)),
              ),
          ],
        ),
        label(l10n.route_avoid),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            FilterChip(
              label: Text(l10n.water_avoidLanes),
              selected: options.avoidTrafficLanes,
              onSelected: (v) => onChanged(_with(avoidTrafficLanes: v)),
            ),
            FilterChip(
              label: Text(l10n.water_avoidSecurity),
              selected: options.avoidSecurityZones,
              onSelected: (v) => onChanged(_with(avoidSecurityZones: v)),
            ),
            FilterChip(
              label: Text(l10n.water_avoidOpening),
              selected: options.avoidOpeningBridges,
              onSelected: (v) => onChanged(_with(avoidOpeningBridges: v)),
            ),
          ],
        ),
      ],
    );
  }
}

/// A number with its unit, typed in; empty for [hint] where none is
/// allowed.
class _NumberRow extends StatefulWidget {
  final String label;
  final double? value;
  final String unit;
  final String? hint;
  final ValueChanged<double?> onChanged;

  const _NumberRow({
    required this.label,
    required this.value,
    required this.unit,
    this.hint,
    required this.onChanged,
  });

  @override
  State<_NumberRow> createState() => _NumberRowState();
}

class _NumberRowState extends State<_NumberRow> {
  late final _text = TextEditingController(text: _show(widget.value));

  static String _show(double? v) => v == null ? '' : _number(v);

  @override
  void didUpdateWidget(_NumberRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final typed = double.tryParse(_text.text.replaceAll(',', '.'));
    if (widget.value != typed) _text.text = _show(widget.value);
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _text.text.trim().replaceAll(',', '.');
    final v = text.isEmpty ? null : double.tryParse(text);
    if (text.isNotEmpty && v == null) {
      _text.text = _show(widget.value);
      return;
    }
    if (v != widget.value) widget.onChanged(v);
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        Expanded(child: Text(widget.label)),
        SizedBox(
          width: 112,
          child: Focus(
            onFocusChange: (focused) {
              if (!focused) _submit();
            },
            child: TextField(
              controller: _text,
              textAlign: TextAlign.end,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.hint,
                suffixText: widget.unit,
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ),
      ],
    ),
  );
}
