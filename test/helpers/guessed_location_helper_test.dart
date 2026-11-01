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

Contact _repeater(int code, double lat, double lon, {int fill = 0x11}) =>
    Contact(
      publicKey: _key(code, fill),
      name: 'R${code.toRadixString(16)}',
      type: advTypeRepeater,
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
}) => Contact(
  publicKey: _key(keyByte, 0x22),
  name: 'Target',
  type: advTypeChat,
  pathLength: route.isEmpty ? -1 : route.length,
  path: Uint8List.fromList(route),
  pathHashSize: 1,
  lastSeen: lastSeen ?? _now,
  inboundPath: Uint8List.fromList(inbound),
  inboundHopCount: inbound.isEmpty ? null : inbound.length,
  inboundPathHashSize: inbound.isEmpty ? null : 1,
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
        [near, alsoNear],
      );
      expect(guesses.single.highConfidence, isTrue);
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

  group('cacheKey', () {
    final base = _target(inbound: [0xA1, 0x10]);

    test('stays the same for the same inputs', () {
      expect(_keyFor(base), _keyFor(_target(inbound: [0xA1, 0x10])));
    });

    test('changes when the range changes, which covers frequency', () {
      expect(_keyFor(base), isNot(_keyFor(base, maxRangeKm: 800.0)));
    });

    test('changes when the first hop changes at the same length', () {
      expect(_keyFor(base), isNot(_keyFor(_target(inbound: [0xB2, 0x10]))));
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

    test('changes when a located repeater moves', () {
      expect(
        _keyFor(base, located: [_repeater(0xA1, 37.3, -122.0)]),
        isNot(_keyFor(base, located: [_repeater(0xA1, 37.4, -122.0)])),
      );
    });
  });
}
