import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/helpers/repeater_identity.dart';
import 'package:meshtrax/models/contact.dart';

/// A 32-byte key beginning with [prefix], padded with [fill] so two keys that
/// share a prefix are still different keys.
Uint8List key(List<int> prefix, {int fill = 0x11}) {
  final bytes = Uint8List(pubKeySize)..fillRange(0, pubKeySize, fill);
  bytes.setRange(0, prefix.length, prefix);
  return bytes;
}

Contact repeater(String name, Uint8List publicKey, {int type = advTypeRepeater}) {
  return Contact(
    publicKey: publicKey,
    name: name,
    type: type,
    pathLength: 0,
    path: Uint8List(0),
    lastSeen: DateTime(2026, 1, 1),
  );
}

void main() {
  // The field report: a repeater ten feet away answered Discover, and the
  // dialog showed the name of one 100 miles away that happened to share the
  // leading hash byte.
  final farAway = repeater('MOUNTAIN-TOP-100MI', key([0xA2, 0x77], fill: 0xF0));
  final nextDoor = key([0xA2, 0x77], fill: 0x0C);

  group('a discovery response carries the full key', () {
    test('an unknown repeater is never named after a hash collision', () {
      final identity = RepeaterIdentityHelper.resolve(
        contacts: [farAway],
        publicKey: nextDoor,
        hashPrefix: [0xA2],
      );

      expect(identity.source, RepeaterIdentitySource.unknown);
      expect(identity.contact, isNull);
      expect(identity.displayName, isNot(contains('MOUNTAIN')));
      expect(identity.displayName, 'Repeater A277');
    });

    test('it stays addressable by the key we actually heard', () {
      final identity = RepeaterIdentityHelper.resolve(
        contacts: [farAway],
        publicKey: nextDoor,
        hashPrefix: [0xA2],
      );

      // Discovery exists to find repeaters you do not have yet, so logging in
      // must still work — with the real key, not the collider's.
      expect(identity.addressableKey, nextDoor);
      expect(identity.isUnknownContact, isTrue);
    });

    test('a full-key match still resolves to that contact', () {
      final identity = RepeaterIdentityHelper.resolve(
        contacts: [farAway, repeater('NEXT-DOOR', nextDoor)],
        publicKey: nextDoor,
        hashPrefix: [0xA2],
      );

      expect(identity.source, RepeaterIdentitySource.exactKey);
      expect(identity.displayName, 'NEXT-DOOR');
      expect(identity.addressableKey, nextDoor);
    });

    test('a two-byte collision is rejected just as a one-byte one is', () {
      final identity = RepeaterIdentityHelper.resolve(
        contacts: [farAway],
        publicKey: nextDoor,
        hashPrefix: [0xA2, 0x77],
      );

      expect(identity.contact, isNull);
      expect(identity.addressableKey, nextDoor);
    });
  });

  group('only a hash was heard', () {
    test('one match resolves and is addressable', () {
      final identity = RepeaterIdentityHelper.resolve(
        contacts: [farAway, repeater('ELSEWHERE', key([0x5B]))],
        hashPrefix: [0xA2],
      );

      expect(identity.source, RepeaterIdentitySource.uniquePrefix);
      expect(identity.displayName, 'MOUNTAIN-TOP-100MI');
      expect(identity.addressableKey, farAway.publicKey);
    });

    test('two matches identify nobody and stay unaddressable', () {
      final identity = RepeaterIdentityHelper.resolve(
        contacts: [farAway, repeater('NEXT-DOOR', nextDoor)],
        hashPrefix: [0xA2],
      );

      expect(identity.source, RepeaterIdentitySource.ambiguousPrefix);
      expect(identity.contact, isNull);
      // Nothing to log into: acting on either guess targets someone else's
      // repeater with this user's admin password.
      expect(identity.addressableKey, isNull);
      expect(identity.candidates, hasLength(2));
      expect(identity.displayName, 'MOUNTAIN-TOP-100MI | NEXT-DOOR');
    });

    test('a wider hash separates what a narrow one confused', () {
      final other = repeater('OTHER-A2', key([0xA2, 0x01]));
      final contacts = [farAway, other];

      expect(
        RepeaterIdentityHelper.resolve(contacts: contacts, hashPrefix: [0xA2]).source,
        RepeaterIdentitySource.ambiguousPrefix,
      );
      expect(
        RepeaterIdentityHelper.resolve(
          contacts: contacts,
          hashPrefix: [0xA2, 0x77],
        ).displayName,
        'MOUNTAIN-TOP-100MI',
      );
    });

    test('no match is labelled by its own hash', () {
      final identity = RepeaterIdentityHelper.resolve(
        contacts: [farAway],
        hashPrefix: [0x5B, 0x9E],
      );

      expect(identity.source, RepeaterIdentitySource.unknown);
      expect(identity.displayName, 'Repeater 5B9E');
      expect(identity.addressableKey, isNull);
      expect(identity.isUnknownContact, isFalse);
    });
  });

  group('contactsMatchingHash', () {
    test('compares at the width of the hash it was given', () {
      final contacts = [farAway, repeater('NEXT-DOOR', nextDoor)];

      expect(RepeaterIdentityHelper.contactsMatchingHash(contacts, [0xA2]), hasLength(2));
      expect(
        RepeaterIdentityHelper.contactsMatchingHash(contacts, [0xA2, 0x77]),
        hasLength(2),
      );
      expect(
        RepeaterIdentityHelper.contactsMatchingHash(contacts, [0xA2, 0x78]),
        isEmpty,
      );
    });

    test('only repeaters and rooms answer to a path hash', () {
      final contacts = [
        repeater('A-CHAT-NODE', key([0xA2]), type: advTypeChat),
        repeater('A-SENSOR', key([0xA2]), type: advTypeSensor),
        farAway,
      ];

      final matches = RepeaterIdentityHelper.contactsMatchingHash(contacts, [0xA2]);
      expect(matches, hasLength(1));
      expect(matches.single.name, 'MOUNTAIN-TOP-100MI');
    });

    test('a room is a legitimate hop', () {
      final room = repeater('LOBBY', key([0x33]), type: advTypeRoom);
      expect(
        RepeaterIdentityHelper.contactsMatchingHash([room], [0x33]),
        hasLength(1),
      );
    });

    test('an empty hash matches nothing', () {
      expect(RepeaterIdentityHelper.contactsMatchingHash([farAway], []), isEmpty);
    });
  });

  group('unnamedLabel', () {
    test('uses two bytes of the key', () {
      expect(RepeaterIdentityHelper.unnamedLabel(key([0xA2, 0x77])), 'Repeater A277');
    });

    test('falls back to whatever width it was given', () {
      expect(RepeaterIdentityHelper.unnamedLabel([0xA2]), 'Repeater A2');
    });

    test('handles a key with no bytes at all', () {
      expect(RepeaterIdentityHelper.unnamedLabel(const []), 'Unknown repeater');
    });

    test('a leading zero byte is not treated as padding', () {
      // PathHelper.formatPathHex trims at a 0x00 slot; the label must not.
      expect(RepeaterIdentityHelper.unnamedLabel(key([0x00, 0x9E])), 'Repeater 009E');
    });
  });

  test('a contact with an empty name falls back to its hash label', () {
    final unnamed = repeater('', nextDoor);
    final identity = RepeaterIdentityHelper.resolve(
      contacts: [unnamed],
      publicKey: nextDoor,
    );

    expect(identity.source, RepeaterIdentitySource.exactKey);
    expect(identity.displayName, 'Repeater A277');
  });
}
