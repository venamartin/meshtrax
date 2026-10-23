import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../services/app_settings_service.dart';
import '../services/map_packs_service.dart';
import 'app_map.dart';
import 'charts_notice_dialog.dart';

/// What the legend's Mesh part counts on the map.
typedef MeshLegendCounts = ({
  int located,
  int unlocated,
  int pins,
  int guessed,
});

/// Opens the map legend: the Mesh symbols and counts, then, while the map
/// draws charts, the chart symbols by section. It opens at half height and
/// drags up to full.
Future<void> showMapLegend(
  BuildContext context, {
  required MeshLegendCounts counts,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.5,
    minChildSize: 0.25,
    maxChildSize: 1,
    builder: (_, controller) =>
        MapLegendSheet(counts: counts, controller: controller),
  ),
);

class MapLegendSheet extends StatelessWidget {
  final MeshLegendCounts counts;
  final ScrollController? controller;

  const MapLegendSheet({super.key, required this.counts, this.controller});

  static final _chartNo1 = Uri.parse(
    'https://nauticalcharts.noaa.gov/publications/us-chart-1.html',
  );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maps = context.watch<MapPacksService>();
    final settings = context.watch<AppSettingsService>().settings;
    final charts =
        !mapIsOnline(settings, maps) &&
        MapType.parse(settings.mapType) == MapType.charts;
    final chartsStyle = charts
        ? maps.styleId(MapType.charts, dark: settings.mapTheme == 'dark')
        : null;
    final heading = Theme.of(context).textTheme.titleSmall;

    return ListView(
      controller: controller,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Text(l10n.map_legendMesh, style: heading),
        ),
        _MeshLegend(
          counts: counts,
          showGuessed: settings.mapShowGuessedLocations,
        ),
        if (chartsStyle != null) ...[
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Text(l10n.chartLegend_title, style: heading),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.warning_amber_outlined),
            title: Text(l10n.offlineMaps_chartsNotice),
            onTap: () => showChartsNotice(context),
          ),
          FutureBuilder(
            future: LegendStyle.load(maps.styles, chartsStyle),
            builder: (context, snapshot) {
              final style = snapshot.data;
              if (style == null) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return Column(
                children: [
                  for (final section in ChartLegendSection.values)
                    _ChartSection(
                      section: section,
                      style: style,
                      units: settings.unitSystem,
                    ),
                ],
              );
            },
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.menu_book_outlined),
            title: Text(l10n.chartLegend_chartNo1),
            trailing: const Icon(Icons.open_in_new, size: 18),
            onTap: () =>
                launchUrl(_chartNo1, mode: LaunchMode.externalApplication),
          ),
        ],
      ],
    );
  }
}

class _MeshLegend extends StatelessWidget {
  final MeshLegendCounts counts;
  final bool showGuessed;

  const _MeshLegend({required this.counts, required this.showGuessed});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    const bold = TextStyle(fontWeight: FontWeight.bold, fontSize: 14);
    Widget count(IconData icon, int n) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        Text(': $n', style: bold),
      ],
    );
    Widget item(IconData icon, String label, Color color) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.map_nodesCount(
              counts.located + (showGuessed ? counts.guessed : 0),
            ),
            style: bold,
          ),
          Wrap(
            spacing: 16,
            children: [
              count(Icons.location_on, counts.located),
              count(Icons.wrong_location, counts.unlocated),
              count(Icons.add_outlined, counts.located + counts.unlocated),
              Text(l10n.map_pinsCount(counts.pins)),
            ],
          ),
          const SizedBox(height: 8),
          item(Icons.person, l10n.map_chat, Colors.blue),
          item(Icons.router, l10n.map_repeater, Colors.green),
          item(Icons.meeting_room, l10n.map_room, Colors.purple),
          item(Icons.sensors, l10n.map_sensor, Colors.orange),
          item(Icons.flag, l10n.map_pinDm, Colors.blue),
          item(Icons.flag, l10n.map_pinPrivate, Colors.purple),
          item(Icons.flag, l10n.map_pinPublic, Colors.orange),
          if (showGuessed && counts.guessed > 0)
            item(
              Icons.not_listed_location,
              l10n.map_guessedLocation,
              Colors.grey,
            ),
        ],
      ),
    );
  }
}

class _ChartSection extends StatelessWidget {
  final ChartLegendSection section;
  final LegendStyle style;
  final UnitSystem units;

  const _ChartSection({
    required this.section,
    required this.style,
    required this.units,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ExpansionTile(
      title: Text(_sectionTitle(l10n, section)),
      shape: const Border(),
      childrenPadding: const EdgeInsets.only(bottom: 8),
      children: [
        for (final item in ChartLegendItem.of(section))
          _row(context, l10n, item),
      ],
    );
  }

  Widget _row(
    BuildContext context,
    AppLocalizations l10n,
    ChartLegendItem item,
  ) {
    final (title, hint) = _itemText(l10n, item, units);
    return ListTile(
      dense: true,
      leading: LegendSymbol(
        style: style,
        samples: item.samples,
        ground: chartLegendGround,
      ),
      title: Text(title),
      subtitle: hint == null ? null : Text(hint),
    );
  }
}

String _sectionTitle(AppLocalizations l10n, ChartLegendSection section) =>
    switch (section) {
      ChartLegendSection.buoys => l10n.chartLegend_sectionBuoys,
      ChartLegendSection.lights => l10n.chartLegend_sectionLights,
      ChartLegendSection.hazards => l10n.chartLegend_sectionHazards,
      ChartLegendSection.tides => l10n.chartLegend_sectionTides,
      ChartLegendSection.depths => l10n.chartLegend_sectionDepths,
      ChartLegendSection.areas => l10n.chartLegend_sectionAreas,
      ChartLegendSection.landmarks => l10n.chartLegend_sectionLandmarks,
      ChartLegendSection.abbreviations => l10n.chartLegend_sectionAbbreviations,
    };

/// A depth area's limit in the user's units: the number, then with its unit.
int _depthNumber(double metres, UnitSystem units) =>
    (units == UnitSystem.imperial ? metres * 3.28084 : metres).round();

String _depth(double metres, UnitSystem units) =>
    '${_depthNumber(metres, units)} ${units == UnitSystem.imperial ? 'ft' : 'm'}';

String _depthRange(
  AppLocalizations l10n,
  (double, double?) depth,
  UnitSystem units,
) => switch (depth) {
  (final from, null) => l10n.chartLegend_depthOver(_depth(from, units)),
  (final from, final double to) => l10n.chartLegend_depthRange(
    '${_depthNumber(from, units)}',
    _depth(to, units),
  ),
};

(String, String?) _itemText(
  AppLocalizations l10n,
  ChartLegendItem item,
  UnitSystem units,
) {
  return switch (item) {
    ChartLegendItem.portBuoy => (
      l10n.chartLegend_portBuoy,
      l10n.chartLegend_portBuoyHint,
    ),
    ChartLegendItem.starboardBuoy => (
      l10n.chartLegend_starboardBuoy,
      l10n.chartLegend_starboardBuoyHint,
    ),
    ChartLegendItem.junctionBuoy => (
      l10n.chartLegend_junctionBuoy,
      l10n.chartLegend_junctionBuoyHint,
    ),
    ChartLegendItem.safeWaterBuoy => (
      l10n.chartLegend_safeWaterBuoy,
      l10n.chartLegend_safeWaterBuoyHint,
    ),
    ChartLegendItem.isolatedDangerBuoy => (
      l10n.chartLegend_isolatedDangerBuoy,
      l10n.chartLegend_isolatedDangerBuoyHint,
    ),
    ChartLegendItem.specialBuoy => (
      l10n.chartLegend_specialBuoy,
      l10n.chartLegend_specialBuoyHint,
    ),
    ChartLegendItem.cardinalBuoy => (
      l10n.chartLegend_cardinalBuoy,
      l10n.chartLegend_cardinalBuoyHint,
    ),
    ChartLegendItem.mooringBuoy => (l10n.chartLegend_mooringBuoy, null),
    ChartLegendItem.portBeacon => (
      l10n.chartLegend_portBeacon,
      l10n.chartLegend_portBeaconHint,
    ),
    ChartLegendItem.starboardBeacon => (
      l10n.chartLegend_starboardBeacon,
      l10n.chartLegend_starboardBeaconHint,
    ),
    ChartLegendItem.otherBeacon => (
      l10n.chartLegend_otherBeacon,
      l10n.chartLegend_otherBeaconHint,
    ),
    ChartLegendItem.beaconTower => (l10n.chartLegend_beaconTower, null),
    ChartLegendItem.topmark => (
      l10n.chartLegend_topmark,
      l10n.chartLegend_topmarkHint,
    ),
    ChartLegendItem.light => (
      l10n.chartLegend_light,
      l10n.chartLegend_lightHint,
    ),
    ChartLegendItem.lightExample => (
      l10n.chartLegend_lightExample,
      l10n.chartLegend_lightExampleHint,
    ),
    ChartLegendItem.lightFixed => (
      l10n.chartLegend_lightFixed,
      l10n.chartLegend_lightFixedHint,
    ),
    ChartLegendItem.lightFlashing => (
      l10n.chartLegend_lightFlashing,
      l10n.chartLegend_lightFlashingHint,
    ),
    ChartLegendItem.lightGroup => (
      l10n.chartLegend_lightGroup,
      l10n.chartLegend_lightGroupHint,
    ),
    ChartLegendItem.lightComposite => (
      l10n.chartLegend_lightComposite,
      l10n.chartLegend_lightCompositeHint,
    ),
    ChartLegendItem.lightQuick => (
      l10n.chartLegend_lightQuick,
      l10n.chartLegend_lightQuickHint,
    ),
    ChartLegendItem.lightIsophase => (
      l10n.chartLegend_lightIsophase,
      l10n.chartLegend_lightIsophaseHint,
    ),
    ChartLegendItem.lightOcculting => (
      l10n.chartLegend_lightOcculting,
      l10n.chartLegend_lightOccultingHint,
    ),
    ChartLegendItem.lightMorse => (
      l10n.chartLegend_lightMorse,
      l10n.chartLegend_lightMorseHint,
    ),
    ChartLegendItem.lightAlternating => (
      l10n.chartLegend_lightAlternating,
      l10n.chartLegend_lightAlternatingHint,
    ),
    ChartLegendItem.lightColours => (l10n.chartLegend_lightColours, null),
    ChartLegendItem.lightPeriod => (
      l10n.chartLegend_lightPeriod,
      l10n.chartLegend_lightPeriodHint,
    ),
    ChartLegendItem.rock => (l10n.chartLegend_rock, l10n.chartLegend_rockHint),
    ChartLegendItem.rockAwash => (
      l10n.chartLegend_rockAwash,
      l10n.chartLegend_rockAwashHint,
    ),
    ChartLegendItem.rockCovers => (
      l10n.chartLegend_rockCovers,
      l10n.chartLegend_rockCoversHint,
    ),
    ChartLegendItem.wreckDangerous => (
      l10n.chartLegend_wreckDangerous,
      l10n.chartLegend_wreckDangerousHint,
    ),
    ChartLegendItem.wreck => (
      l10n.chartLegend_wreck,
      l10n.chartLegend_wreckHint,
    ),
    ChartLegendItem.wreckShowing => (
      l10n.chartLegend_wreckShowing,
      l10n.chartLegend_wreckShowingHint,
    ),
    ChartLegendItem.obstruction => (
      l10n.chartLegend_obstruction,
      l10n.chartLegend_obstructionHint,
    ),
    ChartLegendItem.foulGround => (
      l10n.chartLegend_foulGround,
      l10n.chartLegend_foulGroundHint,
    ),
    ChartLegendItem.hazardArea => (
      l10n.chartLegend_hazardArea,
      l10n.chartLegend_hazardAreaHint,
    ),
    ChartLegendItem.pile => (l10n.chartLegend_pile, null),
    ChartLegendItem.floodStream => (
      l10n.chartLegend_floodStream,
      l10n.chartLegend_floodStreamHint,
    ),
    ChartLegendItem.ebbStream => (
      l10n.chartLegend_ebbStream,
      l10n.chartLegend_ebbStreamHint,
    ),
    ChartLegendItem.current => (
      l10n.chartLegend_current,
      l10n.chartLegend_currentHint,
    ),
    ChartLegendItem.rips => (l10n.chartLegend_rips, l10n.chartLegend_ripsHint),
    ChartLegendItem.breakers => (
      l10n.chartLegend_breakers,
      l10n.chartLegend_breakersHint,
    ),
    ChartLegendItem.sounding => (
      l10n.chartLegend_sounding,
      l10n.chartLegend_soundingHint,
    ),
    ChartLegendItem.depthContour => (
      l10n.chartLegend_depthContour,
      l10n.chartLegend_depthContourHint,
    ),
    ChartLegendItem.drying => (l10n.chartLegend_drying, null),
    ChartLegendItem.depthShallow ||
    ChartLegendItem.depthMedium ||
    ChartLegendItem.depthDeep ||
    ChartLegendItem.depthDeepest => (
      _depthRange(l10n, item.depth!, units),
      null,
    ),
    ChartLegendItem.dredged => (
      l10n.chartLegend_dredged,
      l10n.chartLegend_dredgedHint,
    ),
    ChartLegendItem.swept => (
      l10n.chartLegend_swept,
      l10n.chartLegend_sweptHint,
    ),
    ChartLegendItem.unsurveyed => (
      l10n.chartLegend_unsurveyed,
      l10n.chartLegend_unsurveyedHint,
    ),
    ChartLegendItem.weed => (l10n.chartLegend_weed, null),
    ChartLegendItem.restricted => (
      l10n.chartLegend_restricted,
      l10n.chartLegend_restrictedHint,
    ),
    ChartLegendItem.regulatedLimit => (
      l10n.chartLegend_regulatedLimit,
      l10n.chartLegend_regulatedLimitHint,
    ),
    ChartLegendItem.greyLimit => (l10n.chartLegend_greyLimit, null),
    ChartLegendItem.anchorage => (l10n.chartLegend_anchorage, null),
    ChartLegendItem.anchorBerth => (l10n.chartLegend_anchorBerth, null),
    ChartLegendItem.noAnchoring => (l10n.chartLegend_noAnchoring, null),
    ChartLegendItem.caution => (
      l10n.chartLegend_caution,
      l10n.chartLegend_cautionHint,
    ),
    ChartLegendItem.trafficLane => (
      l10n.chartLegend_trafficLane,
      l10n.chartLegend_trafficLaneHint,
    ),
    ChartLegendItem.separationZone => (
      l10n.chartLegend_separationZone,
      l10n.chartLegend_separationZoneHint,
    ),
    ChartLegendItem.precautionary => (
      l10n.chartLegend_precautionary,
      l10n.chartLegend_precautionaryHint,
    ),
    ChartLegendItem.fairway => (
      l10n.chartLegend_fairway,
      l10n.chartLegend_fairwayHint,
    ),
    ChartLegendItem.track => (l10n.chartLegend_track, null),
    ChartLegendItem.ferry => (l10n.chartLegend_ferry, null),
    ChartLegendItem.leadingLine => (
      l10n.chartLegend_leadingLine,
      l10n.chartLegend_leadingLineHint,
    ),
    ChartLegendItem.cable => (
      l10n.chartLegend_cable,
      l10n.chartLegend_cableHint,
    ),
    ChartLegendItem.pipeline => (
      l10n.chartLegend_pipeline,
      l10n.chartLegend_pipelineHint,
    ),
    ChartLegendItem.overhead => (
      l10n.chartLegend_overhead,
      l10n.chartLegend_overheadHint,
    ),
    ChartLegendItem.tower => (l10n.chartLegend_tower, null),
    ChartLegendItem.windTurbine => (l10n.chartLegend_windTurbine, null),
    ChartLegendItem.chimney => (l10n.chartLegend_chimney, null),
    ChartLegendItem.mast => (l10n.chartLegend_mast, null),
    ChartLegendItem.church => (l10n.chartLegend_church, null),
    ChartLegendItem.flagstaff => (l10n.chartLegend_flagstaff, null),
    ChartLegendItem.dome => (l10n.chartLegend_dome, null),
    ChartLegendItem.landmark => (l10n.chartLegend_landmark, null),
    ChartLegendItem.abbrAnch => (l10n.chartLegend_abbrAnch, null),
    ChartLegendItem.abbrWk => (l10n.chartLegend_abbrWk, null),
    ChartLegendItem.abbrBr => (l10n.chartLegend_abbrBr, null),
    ChartLegendItem.abbrWd => (l10n.chartLegend_abbrWd, null),
    ChartLegendItem.abbrVar => (l10n.chartLegend_abbrVar, null),
    ChartLegendItem.abbrVc => (l10n.chartLegend_abbrVc, null),
    ChartLegendItem.abbrTr => (l10n.chartLegend_abbrTr, null),
    ChartLegendItem.abbrCh => (l10n.chartLegend_abbrCh, null),
    ChartLegendItem.abbrChy => (l10n.chartLegend_abbrChy, null),
    ChartLegendItem.abbrFs => (l10n.chartLegend_abbrFs, null),
    ChartLegendItem.abbrTk => (l10n.chartLegend_abbrTk, null),
    ChartLegendItem.abbrRBn => (l10n.chartLegend_abbrRBn, null),
    ChartLegendItem.abbrCg => (l10n.chartLegend_abbrCg, null),
    ChartLegendItem.abbrRacon => (l10n.chartLegend_abbrRacon, null),
    ChartLegendItem.abbrFog => (l10n.chartLegend_abbrFog, null),
    ChartLegendItem.abbrVAis => (l10n.chartLegend_abbrVAis, null),
  };
}
