import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/path_resolver.dart';
import 'package:meshtrax/models/contact.dart';

Uint8List key(List<int> prefix, int fill) {
  final bytes = Uint8List(pubKeySize)..fillRange(0, pubKeySize, fill);
  bytes.setRange(0, prefix.length, prefix);
  return bytes;
}

Contact node(
  List<int> prefix,
  int fill,
  String name,
  double? latitude,
  double? longitude,
) {
  return Contact(
    publicKey: key(prefix, fill),
    name: name,
    type: advTypeRepeater,
    pathLength: 0,
    path: Uint8List(0),
    latitude: latitude,
    longitude: longitude,
    lastSeen: DateTime(2026, 1, 1),
  );
}

Contact repeater(
  int prefix,
  int fill,
  String name,
  double? latitude,
  double? longitude,
) => node([prefix], fill, name, latitude, longitude);

void main() {
  group('buildPathHops', () {
    final repeatersBoth = [
      repeater(0xc5, 0x00, "Solar Heltec v4 Test", null, null),
      repeater(0xbe, 0x00, "Pythia", 37.77276, -122.44410),
      repeater(0x10, 0x00, "1000 G2 1W V1.16", 37.10981, -121.84390),
    ];
    final repeatersNorth = [
      repeater(0x69, 0x00, "AE6BS Home Repeater", 37.34218, -121.97765),
      repeater(0xbb, 0x00, "KO6JOT Observer", 38.32209, -122.48170),
      repeater(0x3c, 0x00, "San Benito Repeater", 36.80525, -121.36684),
      repeater(0x68, 0x00, "N9DK Room Server", 37.38650, -122.09057),
    ];
    final repeatersSouth = [
      repeater(0x69, 0x01, "PL@W Williams Hill", 35.95170, -121.00160),
      repeater(0xbb, 0x01, "SLOCORE", 35.45429, -120.50680),
      repeater(0x3c, 0x01, "SLOLOWE", 35.31951, -120.60110),
      repeater(0x68, 0x01, "wspr-trees", 35.28275, -120.68045),
    ];
    final myLocation = LatLng(35.283342, -120.660648);

    // The path I saw, from the Bay to the Central Coast
    final pathBytes = [0xc5, 0xbe, 0x10, 0x69, 0xbb, 0x3c, 0x68];

    test(
      'average length algorithm picks better path than greedy algorithm with all repeaters',
      () {
        expect(
          PathResolver.buildPathHops(
            Uint8List.fromList(pathBytes),
            repeatersBoth + repeatersNorth + repeatersSouth,
          ).map((hop) => hop.contact!.name),
          [
            'Solar Heltec v4 Test',
            'Pythia',
            '1000 G2 1W V1.16',
            'PL@W Williams Hill',
            'SLOCORE',
            'SLOLOWE',
            'wspr-trees',
          ],
        );
      },
    );

    test('average length algorithm considers end location', () {
      expect(
        PathResolver.buildPathHops(
          Uint8List.fromList([0xc5, 0xbe, 0x10, 0x69]),
          repeatersBoth + repeatersNorth + repeatersSouth,
          endLocation: myLocation,
        ).map((hop) => hop.contact!.name),
        [
          'Solar Heltec v4 Test',
          'Pythia',
          '1000 G2 1W V1.16',
          'PL@W Williams Hill',
        ],
      );
    });

    test('average length algorithm considers start location', () {
      expect(
        PathResolver.buildPathHops(
          Uint8List.fromList([0x69, 0x10, 0xbe, 0xc5]),
          repeatersBoth + repeatersNorth + repeatersSouth,
          startLocation: myLocation,
        ).map((hop) => hop.contact!.name),
        [
          'PL@W Williams Hill',
          '1000 G2 1W V1.16',
          'Pythia',
          'Solar Heltec v4 Test',
        ],
      );
    });

    test('hop indices start at 1', () {
      expect(
        PathResolver.buildPathHops(
          Uint8List.fromList(pathBytes),
          repeatersBoth + repeatersNorth + repeatersSouth,
        ).map((hop) => hop.index),
        [1, 2, 3, 4, 5, 6, 7],
      );
    });

    test(
      'search budget still returns a complete path on a massively clashing network',
      () {
        final pathBytes = List.generate(32, (i) => 0xaa);
        final repeaters = List.generate(
          256,
          (i) => repeater(0xaa, i, "Repeater $i", 31.0 + i, -120.0 + i),
        );

        final hops = PathResolver.buildPathHops(
          Uint8List.fromList(pathBytes),
          repeaters,
        );

        expect(hops.length, 32);
        expect(hops.map((hop) => hop.contact).toSet().length, 32);
      },
    );

    test('path cannot reuse repeaters in massively clashing network', () {
      final pathBytes = [0xaa, 0xbb, 0xbb, 0xbb, 0xcc];
      final repeaters = [
        repeater(0xaa, 0x00, "Repeater A", 30.0, -120.0),
        repeater(0xbb, 0x01, "Repeater B1", 31.0, -120.0),
        repeater(0xbb, 0x02, "Repeater B2", 32.0, -120.0),
        repeater(0xbb, 0x03, "Repeater B3", 33.0, -120.0),
        repeater(0xcc, 0x00, "Repeater C", 34.0, -120.0),
      ];

      expect(
        PathResolver.buildPathHops(
          Uint8List.fromList(pathBytes),
          repeaters,
          startLocation: LatLng(29.0, -120.0),
        ).map((hop) => hop.contact!.name),
        [
          'Repeater A',
          'Repeater B1',
          'Repeater B2',
          'Repeater B3',
          'Repeater C',
        ],
      );
    });

    test('unknown repeaters are kept as placeholders with their prefix label', () {
      final pathBytes = [0x01, 0x02, 0x03];
      final repeaters = [
        repeater(0xaa, 0x00, "Repeater A", 30.0, -120.0),
        repeater(0xbb, 0x00, "Repeater B", 31.0, -120.0),
        repeater(0xcc, 0x00, "Repeater C", 34.0, -120.0),
      ];

      final hops = PathResolver.buildPathHops(
        Uint8List.fromList(pathBytes),
        repeaters,
        startLocation: myLocation,
      );

      expect(hops.map((hop) => hop.contact), [null, null, null]);
      expect(hops.map((hop) => hop.fullPrefixLabel), ['01', '02', '03']);
      expect(hops.map((hop) => hop.index), [1, 2, 3]);
    });

    test('an unknown repeater mid-path keeps the known hops around it', () {
      final pathBytes = [0xaa, 0x55, 0xcc];
      final repeaters = [
        repeater(0xaa, 0x00, "Repeater A", 30.0, -120.0),
        repeater(0xcc, 0x00, "Repeater C", 31.0, -120.0),
      ];

      final hops = PathResolver.buildPathHops(
        Uint8List.fromList(pathBytes),
        repeaters,
      );

      expect(
        hops.map((hop) => hop.contact?.name),
        ['Repeater A', null, 'Repeater C'],
      );
      expect(hops.map((hop) => hop.fullPrefixLabel), ['AA', '55', 'CC']);
    });

    test('a candidate implausibly far from the previous hop is treated as unknown', () {
      final pathBytes = [0xaa, 0xbb];
      final repeaters = [
        repeater(0xaa, 0x00, "Repeater A", 35.0, -120.0),
        repeater(0xbb, 0x00, "Far away", 55.0, -100.0),
      ];

      final hops = PathResolver.buildPathHops(
        Uint8List.fromList(pathBytes),
        repeaters,
      );

      expect(hops.map((hop) => hop.contact?.name), ['Repeater A', null]);
    });

    test('2-byte hashes resolve without clashing on a shared first byte', () {
      final repeaters = [
        node([0xaa, 0x11], 0x00, "A1", 35.0, -120.0),
        node([0xaa, 0x22], 0x00, "A2", 35.1, -120.1),
        node([0xbb, 0x33], 0x00, "B3", 35.2, -120.2),
        node([0xbb, 0x44], 0x00, "B4", 35.3, -120.3),
      ];

      final hops = PathResolver.buildPathHops(
        Uint8List.fromList([0xaa, 0x11, 0xaa, 0x22, 0xbb, 0x33]),
        repeaters,
        stride: 2,
      );

      expect(hops.map((hop) => hop.contact?.name), ['A1', 'A2', 'B3']);
      expect(hops.map((hop) => hop.fullPrefixLabel), ['AA11', 'AA22', 'BB33']);
      expect(hops.map((hop) => hop.index), [1, 2, 3]);
    });

    test('2-byte path with a trailing odd byte yields an unknown last hop', () {
      final repeaters = [
        node([0xaa, 0x11], 0x00, "A1", 35.0, -120.0),
        node([0xbb, 0x33], 0x00, "B3", 35.2, -120.2),
      ];

      final hops = PathResolver.buildPathHops(
        Uint8List.fromList([0xaa, 0x11, 0xbb]),
        repeaters,
        stride: 2,
      );

      expect(hops.map((hop) => hop.contact?.name), ['A1', null]);
      expect(hops.map((hop) => hop.fullPrefixLabel), ['AA11', 'BB']);
    });
  });
}
