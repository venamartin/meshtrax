import 'dart:isolate';
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

Contact repeater(
    int prefix,
    int fill,
    String name,
    double? latitude,
    double? longitude
  ) {
  return Contact(
    publicKey: key([prefix], fill),
    name: name,
    type: advTypeRepeater,
    pathLength: 0,
    path: Uint8List(0),
    latitude: latitude,
    longitude: longitude,
    lastSeen: DateTime(2026, 1, 1),
  );
}

void main() {
  group('buildPathHops, ()', () {
    final repeatersBoth = [
      repeater(0xc5, 0x00, "Solar Heltec v4 Test", null, null),
      repeater(0xbe, 0x00, "Pythia", 37.77276, -122.44410),
      repeater(0x10, 0x00, "1000 G2 1W V1.16", 37.10981, -121.84390)
    ];
    final repeatersNorth = [
      repeater(0x69, 0x00, "AE6BS Home Repeater", 37.34218, -121.97765),
      repeater(0xbb, 0x00, "KO6JOT Observer", 38.32209, -122.48170),
      repeater(0x3c, 0x00, "San Benito Repeater", 36.80525, -121.36684),
      repeater(0x68, 0x00, "N9DK Room Server", 37.38650, -122.09057)
    ];
    final repeatersSouth = [
      repeater(0x69, 0x01, "PL@W Williams Hill", 35.95170, -121.00160),
      repeater(0xbb, 0x01, "SLOCORE", 35.45429, -120.50680),
      repeater(0x3c, 0x01, "SLOLOWE", 35.31951, -120.60110),
      repeater(0x68, 0x01, "wspr-trees", 35.28275, -120.68045)
    ];
    final myLocation = LatLng(35.283342, -120.660648);

    // The path I saw, from the Bay to the Central Coast
    final pathBytes = [0xc5, 0xbe, 0x10, 0x69, 0xbb, 0x3c, 0x68];

    test('average length algorithm picks better path than greedy algorithm with all repeaters', () {
      expect(
          PathResolver.buildPathHops(
              Uint8List.fromList(pathBytes),
              repeatersBoth + repeatersNorth + repeatersSouth
          )
              .map((hop) => hop.contact!.name),
          [
            'Solar Heltec v4 Test',
            'Pythia',
            '1000 G2 1W V1.16',
            'PL@W Williams Hill',
            'SLOCORE',
            'SLOLOWE',
            'wspr-trees'
          ]
      );
    });

    test('average length algorithm considers end location', () {
      expect(
          PathResolver.buildPathHops(
              Uint8List.fromList([0xc5, 0xbe, 0x10, 0x69]),
              repeatersBoth + repeatersNorth + repeatersSouth,
              endLocation: myLocation
          )
              .map((hop) => hop.contact!.name),
          [
            'Solar Heltec v4 Test',
            'Pythia',
            '1000 G2 1W V1.16',
            'PL@W Williams Hill'
          ]
      );
    });

    test('average length algorithm considers start location', () {
      expect(
          PathResolver.buildPathHops(
              Uint8List.fromList([0x69, 0x10, 0xbe, 0xc5]),
              repeatersBoth + repeatersNorth + repeatersSouth,
              startLocation: myLocation
          )
              .map((hop) => hop.contact!.name),
          [
            'PL@W Williams Hill',
            '1000 G2 1W V1.16',
            'Pythia',
            'Solar Heltec v4 Test',
          ]
      );
    });

    test('average length algorithm gives up early on massively clashing network', () async {
      final pathBytes = List.generate(32, (i) => 0xaa);
      final repeaters = List.generate(256, (i) => repeater(0xaa, i, "Repeater $i", 31.0 + i, -120.0 + i));

      await Isolate.run(
        () => PathResolver.buildPathHops(
          Uint8List.fromList(pathBytes),
          repeaters
        )
      ).timeout(Duration(seconds: 2));
    });

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
          startLocation: myLocation
        )
          .map((hop) => hop.contact!.name),
        [
          'Repeater A',
          'Repeater B1',
          'Repeater B2',
          'Repeater B3',
          'Repeater C',
        ]
      );
    });

    test('empty path returned when no repeaters match the path', () {
      final pathBytes = [0x01, 0x02, 0x03];
      final repeaters = [
        repeater(0xaa, 0x00, "Repeater A", 30.0, -120.0),
        repeater(0xbb, 0x00, "Repeater B", 31.0, -120.0),
        repeater(0xcc, 0x00, "Repeater C", 34.0, -120.0),
      ];

      expect(
          PathResolver.buildPathHops(
              Uint8List.fromList(pathBytes),
              repeaters,
              startLocation: myLocation
          )
              .map((hop) => hop.contact!.name),
          []
      );
    });
  });
}
