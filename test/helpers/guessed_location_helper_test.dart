import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/guessed_location_helper.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime(2026, 10, 31, 12);
final _staleBefore = _now.subtract(GuessedLocationHelper.staleAfter);

Uint8List _key(int first, [int fill = 0x11]) =>
    Uint8List.fromList([first, ...List.filled(31, fill)]);

Contact _repeater(
  int code,
  double lat,
  double lon, {
  int fill = 0x11,
  int type = advTypeRepeater,
}) => Contact(
  publicKey: _key(code, fill),
  name: 'R${code.toRadixString(16)}',
  type: type,
  pathLength: -1,
  path: Uint8List(0),
  pathHashSize: 1,
  latitude: lat,
  longitude: lon,
  lastSeen: _now,
);

Contact _target({
  List<int> inbound = const [],
  List<int> route = const [],
  DateTime? lastSeen,
  int keyByte = 0xC0,
  int routeWidth = 1,
  int? inboundWidth = 1,
}) => Contact(
  publicKey: _key(keyByte, 0x22),
  name: 'Target',
  type: advTypeChat,
  pathLength: route.isEmpty ? -1 : route.length,
  path: Uint8List.fromList(route),
  pathHashSize: routeWidth,
  lastSeen: lastSeen ?? _now,
  inboundPath: Uint8List.fromList(inbound),
  inboundHopCount: inbound.isEmpty ? null : inbound.length,
  inboundPathHashSize: inbound.isEmpty ? null : inboundWidth,
);

List<GuessedLocation> _compute(
  List<Contact> targets,
  List<Contact> located, {
  double? maxRangeKm,
}) => GuessedLocationHelper.compute(
  targets: targets,
  located: located,
  maxRangeKm: maxRangeKm,
  staleBefore: _staleBefore,
);

String _keyFor(
  Contact target, {
  List<Contact> located = const [],
  double? maxRangeKm = 785.7,
}) => GuessedLocationHelper.cacheKey(
  targets: [target],
  located: located,
  maxRangeKm: maxRangeKm,
  staleBefore: _staleBefore,
);

// firmware MyMesh.cpp: `uint32_t freq = _prefs.freq * 1000`, freq in MHz.
Uint8List _selfInfo({required int freq, required int bw}) {
  final w = BytesBuilder();
  w.add([respCodeSelfInfo, advTypeChat, 22, 22]);
  w.add(_key(0x77));
  w.add(Uint8List(8));
  w.add([0, 0, 0, 1]);
  w.add(
    (ByteData(8)
          ..setUint32(0, freq, Endian.little)
          ..setUint32(4, bw, Endian.little))
        .buffer
        .asUint8List(),
  );
  w.add([7, 5]);
  w.add(utf8.encode('GWQ'));
  return w.toBytes();
}

void main() {
  const distance = Distance();

  group('estimateRangeKm', () {
    test('takes kHz, the value the radio really reports', () {
      final km = GuessedLocationHelper.estimateRangeKm(
        freqKHz: 910525,
        bwHz: 62500,
        sf: 7,
        txPowerDbm: 22,
      );
      expect(km, closeTo(785.7, 0.1));
    });

    test('is the same value when read from a real SELF_INFO frame', () async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
      AppDatabase.useInMemoryForTesting();
      final c = MeshCoreConnector();
      c.handleFrameForTest(_selfInfo(freq: 910525, bw: 62500));

      final km = GuessedLocationHelper.estimateRangeKm(
        freqKHz: c.currentFreqHz,
        bwHz: c.currentBwHz,
        sf: c.currentSf,
        txPowerDbm: c.currentTxPower,
      );
      expect(km, closeTo(785.7, 0.1));
    });

    test('is null when a radio parameter is unknown', () {
      expect(
        GuessedLocationHelper.estimateRangeKm(
          freqKHz: null,
          bwHz: 62500,
          sf: 7,
          txPowerDbm: 22,
        ),
        isNull,
      );
    });
  });

  group('midpoint', () {
    test('lies halfway between two anchors', () {
      final m = GuessedLocationHelper.midpoint(
        const LatLng(37.3, -122.0),
        const LatLng(37.5, -122.2),
      );
      expect(m.latitude, closeTo(37.4, 1e-9));
      expect(m.longitude, closeTo(-122.1, 1e-9));
    });

    test('goes the short way across the 180 degree meridian', () {
      final m = GuessedLocationHelper.midpoint(
        const LatLng(-17.0, 179.0),
        const LatLng(-16.7, -179.0),
      );
      expect(m.latitude, closeTo(-16.85, 1e-9));
      expect(m.longitude.abs(), closeTo(180.0, 1e-9));
    });

    test('stays in range when the halfway point is past the meridian', () {
      final m = GuessedLocationHelper.midpoint(
        const LatLng(-17.0, 179.5),
        const LatLng(-16.7, -178.5),
      );
      expect(m.longitude, closeTo(-179.5, 1e-9));
    });
  });

  group('withinRange', () {
    const a = LatLng(37.3, -122.0);

    test('keeps a pair inside twice the range', () {
      expect(
        GuessedLocationHelper.withinRange(a, const LatLng(45.5, -122.7), 785.7),
        isTrue,
      );
    });

    test('rejects a pair past twice the range', () {
      expect(
        GuessedLocationHelper.withinRange(a, const LatLng(40.7, -74.0), 785.7),
        isFalse,
      );
    });

    test('near-antipodal points count as too far and do not throw', () {
      expect(
        GuessedLocationHelper.withinRange(
          const LatLng(37.77, -122.42),
          const LatLng(-37.77, 57.58),
          785.7,
        ),
        isFalse,
      );
    });
  });

  group('compute', () {
    final near = _repeater(0xA1, 37.3, -122.0);
    final alsoNear = _repeater(0xB2, 37.5, -122.2);
    final far = _repeater(0xD3, 40.7, -74.0);

    test('one anchor gives a dim guess 330 m from the repeater', () {
      final guesses = _compute(
        [
          _target(inbound: [0xA1]),
        ],
        [near],
        maxRangeKm: 785.7,
      );
      expect(guesses, hasLength(1));
      expect(guesses.single.highConfidence, isFalse);
      expect(
        distance(guesses.single.position, const LatLng(37.3, -122.0)),
        closeTo(330, 2),
      );
    });

    test('both paths naming one repeater still count as one anchor', () {
      final guesses = _compute(
        [
          _target(inbound: [0xA1], route: [0xA1]),
        ],
        [near],
      );
      expect(guesses.single.highConfidence, isFalse);
    });

    test('two nearby anchors give a guess between them', () {
      final guesses = _compute(
        [
          _target(inbound: [0xA1], route: [0xB2]),
        ],
        [near, alsoNear],
        maxRangeKm: 785.7,
      );
      expect(guesses.single.highConfidence, isTrue);
      expect(
        distance(guesses.single.position, const LatLng(37.4, -122.1)),
        closeTo(120, 2),
      );
    });

    test('the route anchor is the last hop, the advert anchor the first', () {
      final guesses = _compute(
        [
          _target(inbound: [0xA1, 0xEE], route: [0xEE, 0xB2]),
        ],
        [near, alsoNear, _repeater(0xEE, 40.7, -74.0)],
      );
      expect(guesses.single.highConfidence, isTrue);
      expect(
        distance(guesses.single.position, const LatLng(37.4, -122.1)),
        closeTo(120, 2),
      );
    });

    group('hash widths', () {
      final a1b2 = _repeater(0xA1, 37.3, -122.0, fill: 0xB2);
      final a1cc = _repeater(0xA1, 40.0, -100.0, fill: 0xCC);

      test('the advert path resolves at its own width', () {
        final guesses = _compute(
          [
            _target(inbound: [0xA1, 0xB2], inboundWidth: 2),
          ],
          [a1b2, a1cc],
        );
        expect(
          distance(guesses.single.position, const LatLng(37.3, -122.0)),
          closeTo(330, 2),
        );
      });

      test('the route resolves at its own width', () {
        final guesses = _compute(
          [
            _target(route: [0xA1, 0xB2], routeWidth: 2),
          ],
          [a1b2, a1cc],
        );
        expect(
          distance(guesses.single.position, const LatLng(37.3, -122.0)),
          closeTo(330, 2),
        );
      });

      test('the route keeps its width beside an advert path of another', () {
        final guesses = _compute(
          [
            _target(inbound: [0x55], route: [0xA1, 0xB2], routeWidth: 2),
          ],
          [a1b2, a1cc],
        );
        expect(
          distance(guesses.single.position, const LatLng(37.3, -122.0)),
          closeTo(330, 2),
        );
      });

      test('an advert path of unknown width takes the route width', () {
        final guesses = _compute(
          [
            _target(inbound: [0xA1, 0xB2], inboundWidth: null, routeWidth: 2),
          ],
          [a1b2, a1cc],
        );
        expect(guesses, hasLength(1));
      });
    });

    group('at the 180 degree meridian', () {
      test('two anchors across it give a guess on the map', () {
        final guesses = _compute(
          [
            _target(inbound: [0xA1], route: [0xB2]),
          ],
          [_repeater(0xA1, -17.0, 179.5), _repeater(0xB2, -16.7, -178.5)],
          maxRangeKm: 785.7,
        );
        expect(guesses.single.highConfidence, isTrue);
        expect(guesses.single.position.longitude, closeTo(-179.5, 0.01));
      });

      test('the display offset can carry a guess across it', () {
        final guesses = _compute(
          [
            _target(inbound: [0xA1]),
          ],
          [_repeater(0xA1, -17.0, 179.9999)],
        );
        expect(guesses.single.position.longitude, lessThan(-179.99));
      });
    });

    test('two anchors too far apart give no guess', () {
      expect(
        _compute(
          [
            _target(inbound: [0xA1], route: [0xD3]),
          ],
          [near, far],
          maxRangeKm: 785.7,
        ),
        isEmpty,
      );
    });

    test('with no radio parameters there is no limit to apply', () {
      expect(
        _compute(
          [
            _target(inbound: [0xA1], route: [0xD3]),
          ],
          [near, far],
        ),
        hasLength(1),
      );
    });

    test('two different repeaters with one code give no anchor', () {
      expect(
        _compute(
          [
            _target(inbound: [0xA1]),
          ],
          [near, _repeater(0xA1, 40.0, -100.0, fill: 0x33)],
        ),
        isEmpty,
      );
    });

    test('a repeater listed twice mid-sync does not collide with itself', () {
      final guesses = _compute(
        [
          _target(inbound: [0xA1]),
        ],
        [near, _repeater(0xA1, 37.3, -122.0)],
      );
      expect(guesses, hasLength(1));
    });

    test('a contact listed twice mid-sync gets one guess', () {
      final target = _target(inbound: [0xA1]);
      expect(_compute([target, target], [near]), hasLength(1));
    });

    test('a first copy that gives no guess does not block a later copy', () {
      final stale = _target(
        inbound: [0xA1],
        lastSeen: _staleBefore.subtract(const Duration(minutes: 1)),
      );
      expect(
        _compute(
          [
            stale,
            _target(inbound: [0xA1]),
          ],
          [near],
        ),
        hasLength(1),
      );
      expect(
        _compute(
          [
            _target(),
            _target(inbound: [0xA1]),
          ],
          [near],
        ),
        hasLength(1),
      );
    });

    test(
      'a contact with a real position gets no guess from its other copy',
      () {
        final located = Contact(
          publicKey: _key(0xC0, 0x22),
          name: 'Target',
          type: advTypeChat,
          pathLength: -1,
          path: Uint8List(0),
          pathHashSize: 1,
          latitude: 37.0,
          longitude: -121.0,
          lastSeen: _now,
        );
        expect(
          _compute(
            [
              located,
              _target(inbound: [0xA1]),
            ],
            [near],
          ),
          isEmpty,
        );
      },
    );

    test('a contact not heard for 24 hours gets no guess', () {
      expect(
        _compute(
          [
            _target(
              inbound: [0xA1],
              lastSeen: _staleBefore.subtract(const Duration(minutes: 1)),
            ),
          ],
          [near],
        ),
        isEmpty,
      );
    });
  });

  group('what a route proves', () {
    final located = [_repeater(0xA1, 37.3, -122.0)];

    test('a typed route anchors nothing', () {
      final typed = _target(route: [0xA1]).copyWith(
        pathOverride: 1,
        pathOverrideBytes: Uint8List.fromList([0xA1]),
      );
      expect(_compute([typed], located), isEmpty);
    });

    test('forced direct anchors nothing', () {
      final direct = _target(route: [0xA1]).copyWith(pathOverride: 0);
      expect(_compute([direct], located), isEmpty);
    });

    test("always-flood keeps the radio's learned route as an anchor", () {
      final flood = _target(route: [0xA1]).copyWith(pathOverride: -1);
      expect(_compute([flood], located), hasLength(1));
    });

    test('a typed route leaves a real advert path anchoring', () {
      final typed = _target(inbound: [0xA1], route: [0xB2]).copyWith(
        pathOverride: 1,
        pathOverrideBytes: Uint8List.fromList([0xB2]),
      );
      final guesses = _compute([
        typed,
      ], [...located, _repeater(0xB2, 37.5, -122.2)]);
      expect(guesses.single.highConfidence, isFalse);
    });

    test('after a zero-hop advert an old route anchors nothing', () {
      final heardDirect = _target(route: [0xA1]).copyWith(inboundHopCount: 0);
      expect(_compute([heardDirect], located), isEmpty);
    });

    test('a route the app wrote anchors nothing, whatever the choice now', () {
      final route = _target(route: [0xA1]);
      expect(
        GuessedLocationHelper.compute(
          targets: [route],
          located: located,
          maxRangeKm: 785.7,
          staleBefore: _staleBefore,
          routeWrittenByApp: (_) => true,
        ),
        isEmpty,
      );
    });

    test('with no advert yet a learned route anchors', () {
      expect(_compute([_target(route: [0xA1])], located), hasLength(1));
    });
  });

  group('withCurrentContacts', () {
    GuessedLocation guessFor(Contact c) => GuessedLocation(
      contact: c,
      position: const LatLng(1, 2),
      highConfidence: true,
    );

    test('swaps in the current copy and keeps the guess', () {
      final old = _target();
      final renamed = old.copyWith(name: 'New name');

      final result = GuessedLocationHelper.withCurrentContacts(
        [guessFor(old)],
        [renamed],
      ).single;

      expect(result.contact.name, 'New name');
      expect(result.position, const LatLng(1, 2));
      expect(result.highConfidence, isTrue);
    });

    test('keeps a low-confidence guess low', () {
      final low = GuessedLocation(
        contact: _target(),
        position: const LatLng(1, 2),
        highConfidence: false,
      );
      expect(
        GuessedLocationHelper.withCurrentContacts(
          [low],
          [_target()],
        ).single.highConfidence,
        isFalse,
      );
    });

    test('prefers the first copy, the saved contact over its row', () {
      final saved = _target().copyWith(name: 'Saved');
      final row = _target().copyWith(name: 'Row', isActive: false);

      final result = GuessedLocationHelper.withCurrentContacts(
        [guessFor(row)],
        [saved, row],
      ).single;

      expect(result.contact.name, 'Saved');
    });

    test('keeps the cached copy if the contact has gone', () {
      final old = _target();
      expect(
        GuessedLocationHelper.withCurrentContacts([guessFor(old)], const [])
            .single
            .contact,
        same(old),
      );
    });
  });

  group('cacheKey', () {
    final base = _target(inbound: [0xA1, 0x10]);

    test('changes when the app writes the route', () {
      String keyWith(bool written) => GuessedLocationHelper.cacheKey(
        targets: [base],
        located: const [],
        maxRangeKm: 785.7,
        staleBefore: _staleBefore,
        routeWrittenByApp: (_) => written,
      );
      expect(keyWith(false), isNot(keyWith(true)));
    });

    test('changes when the route override changes', () {
      expect(_keyFor(base), isNot(_keyFor(base.copyWith(pathOverride: 2))));
    });

    test('stays the same for the same inputs', () {
      expect(_keyFor(base), _keyFor(_target(inbound: [0xA1, 0x10])));
    });

    test('changes when the range changes, which covers frequency', () {
      expect(_keyFor(base), isNot(_keyFor(base, maxRangeKm: 800.0)));
    });

    test('changes when the first hop changes at the same length', () {
      expect(_keyFor(base), isNot(_keyFor(_target(inbound: [0xB2, 0x10]))));
    });

    test('changes when the hop count changes behind the same first hop', () {
      expect(
        _keyFor(base),
        isNot(_keyFor(_target(inbound: [0xA1, 0x10, 0x20]))),
      );
    });

    test('changes when a contact crosses the 24 hour line', () {
      expect(
        _keyFor(base),
        isNot(
          _keyFor(
            _target(
              inbound: [0xA1, 0x10],
              lastSeen: _staleBefore.subtract(const Duration(minutes: 1)),
            ),
          ),
        ),
      );
    });

    test('does not change when an advert only refreshes the time', () {
      expect(
        _keyFor(base),
        _keyFor(
          _target(
            inbound: [0xA1, 0x10],
            lastSeen: _now.subtract(const Duration(hours: 1)),
          ),
        ),
      );
    });

    test('changes when the same advert bytes are read at another width', () {
      expect(
        _keyFor(_target(inbound: [0xA1, 0xB2])),
        isNot(_keyFor(_target(inbound: [0xA1, 0xB2], inboundWidth: 2))),
      );
    });

    test('changes when the route changes', () {
      expect(
        _keyFor(_target(route: [0xA1])),
        isNot(_keyFor(_target(route: [0xB2]))),
      );
    });

    test('changes when a located repeater moves', () {
      final at = _repeater(0xA1, 37.3, -122.0);
      expect(
        _keyFor(base, located: [at]),
        isNot(_keyFor(base, located: [_repeater(0xA1, 37.4, -122.0)])),
      );
      expect(
        _keyFor(base, located: [at]),
        isNot(_keyFor(base, located: [_repeater(0xA1, 37.3, -122.1)])),
      );
    });

    test('changes when a located contact changes type', () {
      expect(
        _keyFor(base, located: [_repeater(0xA1, 37.3, -122.0)]),
        isNot(
          _keyFor(
            base,
            located: [_repeater(0xA1, 37.3, -122.0, type: advTypeRoom)],
          ),
        ),
      );
    });
  });
}
