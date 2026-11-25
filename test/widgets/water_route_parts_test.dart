import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:traxwater/traxwater.dart';

import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/widgets/water_route_parts.dart';

import '../helpers/water_fakes.dart';

const LatLon _from = (lat: 38.06, lon: -122.23);
const LatLon _to = (lat: 38.04, lon: -122.12);

WaterArea _area(
  String id,
  String chartClass, {
  String? name,
  double? clearanceM,
}) => WaterArea.fromJson({
  'id': id,
  'class': chartClass,
  'name': name,
  'clearance_m': clearanceM,
});

AreaPassed _passed(WaterArea area, double metres, {BridgeNote? note}) =>
    AreaPassed(area: area, metres: metres, fromM: 0, note: note);

EndsShort _shallow({required double draftM}) => EndsShort(
  reason: EndsShortReason.depth,
  remainingM: 18520,
  lowObjects: const [],
  deepestWayM: 1.8,
  deepestWayToM: 3.6,
  deepestDraftM: draftM,
);

Future<void> _pumpPasses(WidgetTester tester, WaterTrip trip) =>
    tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: WaterTripPasses(
              trip: trip,
              boat: const WaterRouteOptions(),
              units: UnitSystem.imperial,
            ),
          ),
        ),
      ),
    );

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  test('distances on the water: feet close by, then miles', () {
    expect(waterDistanceText(60, UnitSystem.imperial), '197 ft');
    expect(waterDistanceText(60, UnitSystem.metric), '60 m');
    expect(waterDistanceText(400, UnitSystem.imperial), '0.2 nm');
    expect(waterDistanceText(2300676, UnitSystem.metric), '1,242 nm');
  });

  test('the boat in one line, from the starting values', () {
    expect(
      boatSummary(l10n, const WaterRouteOptions(), UnitSystem.imperial),
      '6 kn · 6 ft draft + 2 ft · 0.25 nm off land',
    );
    expect(
      boatSummary(
        l10n,
        const WaterRouteOptions(speedKn: 6.5, offLandNm: 0.5, mastHeightM: 12),
        UnitSystem.metric,
      ),
      '6.5 kn · 1.8 m draft + 0.6 m · 0.5 nm off land · 12 m mast',
    );
  });

  group('the notes over a trip', () {
    List<String> notes(
      WaterTrip trip, [
      UnitSystem units = UnitSystem.imperial,
    ]) => waterTripNotes(l10n, trip, 'Benicia', units);

    test('a start moved off the shore under 100 m goes without saying', () {
      expect(
        notes(
          waterTrip(
            _from,
            _to,
            startMovedM: 60,
            startMoved: EndMoved.notInWater,
          ),
        ),
        isEmpty,
      );
    });

    test('further off, it says how far', () {
      expect(
        notes(
          waterTrip(
            _from,
            _to,
            startMovedM: 400,
            startMoved: EndMoved.notInWater,
          ),
        ),
        [
          'Starts 0.2 nm from the point picked: '
              'that point is on land or off the charts.',
        ],
      );
    });

    test("the boat's limits always say", () {
      expect(
        notes(
          waterTrip(_from, _to, startMovedM: 60, startMoved: EndMoved.depth),
        ),
        ["Starts 197 ft from the point picked: it's too shallow there."],
      );
    });

    test('ending short on depth names the band and the drafts that pass', () {
      final trip = waterTrip(_from, _to, endsShort: _shallow(draftM: 1.24));
      expect(notes(trip), [
        'Ends 10.0 nm before Benicia: charted 6–12 ft. '
            'Drafts to 4 ft get through.',
      ]);
      expect(notes(trip, UnitSystem.metric), [
        'Ends 10.0 nm before Benicia: charted 1.8–3.6 m. '
            'Drafts to 1.2 m get through.',
      ]);
    });

    test('where no draft gets through, it says too shallow', () {
      expect(notes(waterTrip(_from, _to, endsShort: _shallow(draftM: 0))), [
        'Ends 10.0 nm before Benicia: charted 6–12 ft, '
            'too shallow to get through.',
      ]);
    });
  });

  group('what a trip passes', () {
    testWidgets('least depth as its charted band, lowest clearance by name', (
      tester,
    ) async {
      final bridge = _area('b1', 'BRIDGE', name: 'Benicia Bridge');
      await _pumpPasses(
        tester,
        waterTrip(
          _from,
          _to,
          lowestClearance: LowestClearance(
            clearanceM: 40.5,
            object: bridge,
            fromM: 2000,
            uncharted: 2,
          ),
        ),
      );

      expect(find.text('Least depth: charted 12–18 ft'), findsOneWidget);
      expect(
        find.text('Lowest clearance 133 ft, Benicia Bridge'),
        findsOneWidget,
      );
      expect(
        find.text('Under 2 spans with no charted clearance'),
        findsOneWidget,
      );
    });

    testWidgets('On the way: one row per bridge and area, miles added', (
      tester,
    ) async {
      final restricted = _area('r1', 'RESARE');
      await _pumpPasses(
        tester,
        waterTrip(
          _from,
          _to,
          passes: [
            // A bridge charted twice, and an area cut by a chart's edge.
            _passed(
              _area('b1', 'BRIDGE', name: 'Benicia Bridge', clearanceM: 40.5),
              30,
            ),
            _passed(
              _area('b2', 'BRIDGE', name: 'Benicia Bridge', clearanceM: 40.5),
              30,
            ),
            _passed(restricted, 926),
            _passed(_area('r2', 'RESARE'), 926),
            _passed(
              _area('b3', 'BRIDGE', name: 'Rail Bridge', clearanceM: 4),
              40,
              note: BridgeNote.needsOpening,
            ),
          ],
        ),
      );

      expect(find.text('On the way'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Benicia Bridge · 133 ft'), findsNothing);

      await tester.tap(find.text('On the way'));
      await tester.pump();

      expect(find.text('Benicia Bridge · 133 ft'), findsOneWidget);
      expect(find.text('Rail Bridge · 13 ft · needs opening'), findsOneWidget);
      expect(find.text('Restricted area'), findsOneWidget);
      expect(find.text('1.0 nm'), findsOneWidget);
    });

    testWidgets("where it couldn't keep off land: its miles, then where", (
      tester,
    ) async {
      await _pumpPasses(
        tester,
        waterTrip(
          _from,
          _to,
          offLand: const OffLand(
            distanceNm: 1,
            reachesDistance: true,
            insideInApproachesM: 0,
            insideElsewhereM: 3704,
            couldntKeep: [
              Stretch(fromM: 9260, metres: 3704, start: _from, end: _to),
            ],
          ),
        ),
      );

      expect(find.text('Closer than 1 nm to land'), findsOneWidget);
      expect(find.text('2.0 nm'), findsOneWidget);

      await tester.tap(find.text('Closer than 1 nm to land'));
      await tester.pump();

      expect(find.text('2.0 nm, from 5.0 nm along'), findsOneWidget);
    });
  });
}
