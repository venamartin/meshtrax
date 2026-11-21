// Firmware facts for regions (flood scopes), read from MeshCore dev
// (src/helpers/RegionMap.cpp, TransportKeyStore.cpp, CommonCLI.cpp,
// examples/simple_repeater/MyMesh.cpp, examples/companion_radio/MyMesh.cpp).
// Vectors were made with Python's hashlib/hmac, not with the app's code.
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/region_helper.dart';
import 'package:meshtrax/models/channel.dart';

String _hex(List<int> b) =>
    b.map((x) => x.toRadixString(16).padLeft(2, '0')).join();

Uint8List _regionKey(String name) => RegionHelper.keyFor(name);

int _transportCode(Uint8List key, int payloadType, Uint8List payload) =>
    RegionHelper.transportCode(key, payloadType, payload);

bool _validRegionName(String name) => RegionHelper.check(name) == null;

// Repeater reply to ANON_REQ_TYPE_REGIONS: [tag u32][repeater clock u32]
// then the names that allow flood, comma separated, '*' when un-scoped
// floods are allowed, '#' stripped.
List<String> _parseRegionsReply(Uint8List data) {
  if (data.length <= 8) return const [];
  return utf8
      .decode(data.sublist(8), allowMalformed: true)
      .split(',')
      .where((s) => s.isNotEmpty)
      .toList();
}

void main() {
  group('region key', () {
    test('is SHA256 of #name, first 16 bytes', () {
      expect(_hex(_regionKey('sf')), 'a32c1fcfda0def959c305e4cd803def1');
      expect(_hex(_regionKey('bayarea')), '7f9a5fd3070ad14e337ba100ca53a89b');
      expect(_hex(_regionKey('au-nsw')), '856eebe261a19ded371a5fc677cc9194');
    });

    test('a leading # is not doubled', () {
      expect(_regionKey('#sf'), _regionKey('sf'));
    });

    test('is case-sensitive: SF and sf are different regions', () {
      expect(_hex(_regionKey('SF')), 'e514a799c298e496cf2d1729cbed124f');
      expect(_regionKey('SF'), isNot(_regionKey('sf')));
    });

    test('non-ASCII names hash their UTF-8 bytes', () {
      expect(_hex(_regionKey('zürich')), '9baece5522e0b687d8658971d1e671b8');
    });

    test('equals the hashtag channel key of the same name', () {
      expect(_regionKey('sf'), Channel.derivePskFromHashtag('#sf'));
    });
  });

  group('transport code', () {
    final payload = Uint8List.fromList(List.generate(32, (i) => 0x10 + i));

    test('matches the firmware math (little-endian)', () {
      expect(_transportCode(_regionKey('sf'), 5, payload), 8098);
      expect(_transportCode(_regionKey('sf'), 4, payload), 9773);
      expect(_transportCode(_regionKey('bayarea'), 5, payload), 9157);
      expect(_transportCode(_regionKey('bayarea'), 4, payload), 40932);
    });

    test('depends on the payload type, so one key gives many codes', () {
      final k = _regionKey('sf');
      expect(_transportCode(k, 5, payload),
          isNot(_transportCode(k, 4, payload)));
    });
  });

  group('region name rules', () {
    test('accepts what the firmware accepts', () {
      for (final ok in ['sf', 'SF', 'au-nsw', 'bay_area', 'zürich', '#sf',
          'a' * 30, '#${'a' * 30}']) {
        expect(_validRegionName(ok), isTrue, reason: ok);
      }
    });

    test('refuses private \$ regions, which need a key store the firmware '
        "hasn't built", () {
      expect(_validRegionName('\$private'), isFalse);
    });


    test('refuses spaces, dots, commas and over 30 bytes', () {
      for (final bad in ['', 'bay area', 'sf.ca', 'a,b', 'a/b', '*',
          'a' * 31, 'ü' * 16]) {
        expect(_validRegionName(bad), isFalse, reason: bad);
      }
    });
  });

  group('repeater regions reply', () {
    test('skips tag and clock, splits on commas', () {
      final reply = Uint8List.fromList([
        1, 2, 3, 4, 5, 6, 7, 8,
        ...utf8.encode('*,sf,bayarea'),
      ]);
      expect(_parseRegionsReply(reply), ['*', 'sf', 'bayarea']);
    });

    test('a repeater that refuses all floods sends no names', () {
      expect(_parseRegionsReply(Uint8List(8)), isEmpty);
    });
  });

  group('default region frame (CMD_SET_DEFAULT_FLOOD_SCOPE)', () {
    test('is [63][name x31][key x16]', () {
      final frame = buildSetDefaultFloodScopeFrame('sf', _regionKey('sf'));
      expect(frame.length, 1 + 31 + 16);
      expect(frame[0], 63);
      expect(utf8.decode(frame.sublist(1, 3)), 'sf');
      expect(frame.sublist(3, 32).every((b) => b == 0), isTrue);
      expect(frame.sublist(32), _regionKey('sf'));
    });

    test('a 30-byte name keeps its terminator (firmware needs < 31)', () {
      final name = 'a' * 30;
      final frame = buildSetDefaultFloodScopeFrame(name, _regionKey(name));
      expect(utf8.decode(frame.sublist(1, 31)), name);
      expect(frame[31], 0);
    });

    test('the radio reply reads back the same name and key', () {
      final set = buildSetDefaultFloodScopeFrame('sf', _regionKey('sf'));
      final reply = Uint8List.fromList([28, ...set.sublist(1)]);
      final parsed = parseDefaultFloodScopeFrame(reply)!;
      expect(parsed.name, 'sf');
      expect(parsed.key, _regionKey('sf'));
    });

    test('a bare command clears the default', () {
      expect(buildSetDefaultFloodScopeFrame(null, null), [63]);
      expect(parseDefaultFloodScopeFrame(Uint8List.fromList([28])), isNull);
    });
  });
}
