import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/app_settings.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';

// Builds a valid contact frame with the given pathLen and optional overrides.
// Frame layout: [respCode(1)][pubKey(32)][type(1)][flags(1)][pathLen(1)][path(64)][name(32)][timestamp(4)][lat(4)][lon(4)]
Uint8List _buildContactFrame({
  int pathLen = 0,
  Uint8List? pubKey,
  String name = 'TestNode',
}) {
  final writer = BytesBuilder();
  writer.addByte(respCodeContact); // 3
  writer.add(
    pubKey ?? Uint8List.fromList(List.generate(32, (i) => i + 1)),
  ); // valid pubkey
  writer.addByte(1); // type
  writer.addByte(0); // flags
  writer.addByte(pathLen);
  writer.add(Uint8List(64)); // path bytes (zeros)
  // name (32 bytes, null-padded)
  final nameBytes = Uint8List(32);
  final encoded = name.codeUnits;
  for (var i = 0; i < encoded.length && i < 31; i++) {
    nameBytes[i] = encoded[i];
  }
  writer.add(nameBytes);
  // timestamp (4 bytes LE) - some nonzero value
  writer.add(Uint8List.fromList([0x01, 0x00, 0x00, 0x00]));
  // lat, lon (4 bytes each)
  writer.add(Uint8List(4)); // lat
  writer.add(Uint8List(4)); // lon
  return Uint8List.fromList(writer.toBytes());
}

void main() {
  group('Contact.fromFrame — pathLen mapping', () {
    test('pathLen == 0 → pathLength == 0 (direct, NOT flood)', () {
      final frame = _buildContactFrame(pathLen: 0);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.pathLength, equals(0));
    });

    test('pathLen == 1 → pathLength == 1', () {
      final frame = _buildContactFrame(pathLen: 1);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.pathLength, equals(1));
    });

    test('pathLen == 63 (max hops) → pathLength == 63', () {
      final frame = _buildContactFrame(pathLen: 63);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.pathLength, equals(63));
    });

    test('pathLen == 0xFF → pathLength == -1 (flood)', () {
      final frame = _buildContactFrame(pathLen: 0xFF);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.pathLength, equals(-1));
    });

    test('pathLen == 65 (hash size 2, hop count 1) → pathLength == 1', () {
      final frame = _buildContactFrame(pathLen: 65);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.pathLength, equals(1));
    });
  });

  group('Contact.fromFrame — corrupt contact guards', () {
    test('all-zero public key → returns null', () {
      final zeroPubKey = Uint8List(32); // all zeros
      final frame = _buildContactFrame(pubKey: zeroPubKey);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNull);
    });

    test('mostly-zero public key (>16 zeros out of 32) → returns null', () {
      // 17 zeros out of 32 bytes exceeds pubKeySize ~/ 2 == 16
      final pubKey = Uint8List(32);
      pubKey[0] = 0xAB;
      pubKey[1] = 0xCD;
      pubKey[2] = 0xEF;
      pubKey[3] = 0x12;
      pubKey[4] = 0x34;
      pubKey[5] = 0x56;
      pubKey[6] = 0x78;
      pubKey[7] = 0x9A;
      pubKey[8] = 0xBC;
      pubKey[9] = 0xDE;
      pubKey[10] = 0xF0;
      pubKey[11] = 0x11;
      pubKey[12] = 0x22;
      pubKey[13] = 0x33;
      pubKey[14] = 0x44;
      // bytes 15–31 are zero: that is 17 zeros (indices 15..31 inclusive)
      final frame = _buildContactFrame(pubKey: pubKey);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNull);
    });

    test('valid public key (few zeros) → returns Contact', () {
      // Only 1 zero → well below the threshold
      final pubKey = Uint8List.fromList(List.generate(32, (i) => i + 1));
      pubKey[5] = 0; // one zero byte
      final frame = _buildContactFrame(pubKey: pubKey);
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
    });

    test('name with all non-printable characters → returns null', () {
      // Build frame with a name composed entirely of control characters (< 0x20)
      final nameBytes = Uint8List(32);
      nameBytes[0] = 0x01;
      nameBytes[1] = 0x02;
      nameBytes[2] = 0x03;
      // remaining are 0x00 (null terminator ends the string after index 2,
      // so readCStringGreedy returns a 3-char string of non-printables)
      final writer = BytesBuilder();
      writer.addByte(respCodeContact);
      writer.add(Uint8List.fromList(List.generate(32, (i) => i + 1)));
      writer.addByte(1); // type
      writer.addByte(0); // flags
      writer.addByte(0); // pathLen
      writer.add(Uint8List(64)); // path
      writer.add(nameBytes);
      writer.add(Uint8List.fromList([0x01, 0x00, 0x00, 0x00])); // timestamp
      writer.add(Uint8List(4)); // lat
      writer.add(Uint8List(4)); // lon
      final frame = Uint8List.fromList(writer.toBytes());
      final contact = Contact.fromFrame(frame);
      expect(contact, isNull);
    });

    test('name with valid printable characters → returns Contact', () {
      final frame = _buildContactFrame(name: 'Alice');
      final contact = Contact.fromFrame(frame);
      expect(contact, isNotNull);
      expect(contact!.name, equals('Alice'));
    });

    test(
      'name with mix of printable and replacement chars → returns Contact (not all bad)',
      () {
        // Build a name with mostly printable chars and one replacement char (0xFFFD in codeUnits).
        // utf8 allowMalformed: true maps invalid sequences to U+FFFD.
        // We embed one invalid UTF-8 byte (0x80) among valid ASCII bytes.
        // The decoded string will be "Hi\uFFFDThere" — not ALL bad, so should be accepted.
        final nameBytes = Uint8List(32);
        nameBytes[0] = 0x48; // 'H'
        nameBytes[1] = 0x69; // 'i'
        nameBytes[2] = 0x80; // invalid UTF-8 → decoded as U+FFFD
        nameBytes[3] = 0x54; // 'T'
        nameBytes[4] = 0x68; // 'h'
        nameBytes[5] = 0x65; // 'e'
        nameBytes[6] = 0x72; // 'r'
        nameBytes[7] = 0x65; // 'e'
        // rest are 0x00 (null terminator)
        final writer = BytesBuilder();
        writer.addByte(respCodeContact);
        writer.add(Uint8List.fromList(List.generate(32, (i) => i + 1)));
        writer.addByte(1); // type
        writer.addByte(0); // flags
        writer.addByte(0); // pathLen
        writer.add(Uint8List(64)); // path
        writer.add(nameBytes);
        writer.add(Uint8List.fromList([0x01, 0x00, 0x00, 0x00])); // timestamp
        writer.add(Uint8List(4)); // lat
        writer.add(Uint8List(4)); // lon
        final frame = Uint8List.fromList(writer.toBytes());
        final contact = Contact.fromFrame(frame);
        expect(contact, isNotNull);
      },
    );
  });

  group('AppSettings — maxMessageRetries', () {
    test('defaults to 3', () {
      expect(AppSettings().maxMessageRetries, equals(3));
    });

    test('round-trips through JSON', () {
      final json = AppSettings().copyWith(maxMessageRetries: 5).toJson();
      expect(json['max_message_retries'], equals(5));
      expect(AppSettings.fromJson(json).maxMessageRetries, equals(5));
    });

    test('fromJson without the key uses the default', () {
      expect(AppSettings.fromJson({}).maxMessageRetries, equals(3));
    });
  });
}
