import 'dart:typed_data';

import '../connector/meshcore_protocol.dart';
import '../models/contact.dart';
import 'path_helper.dart';

/// How a heard repeater was matched to an entry in the contact book.
enum RepeaterIdentitySource {
  /// The full 32-byte public key matched a contact. The only certain match.
  exactKey,

  /// Only the on-air hash was heard, and exactly one contact carries it.
  uniquePrefix,

  /// Only the on-air hash was heard, and several contacts carry it. We do not
  /// know which node this is.
  ambiguousPrefix,

  /// Nothing in the contact book matches.
  unknown,
}

/// The result of asking "which node did we just hear?".
///
/// [contact] is populated only when the answer is certain enough to borrow the
/// contact's name, location and public key from. On [ambiguousPrefix] it stays
/// null however many candidates were found — a 1–2 byte hash shared by two
/// contacts identifies neither.
class RepeaterIdentity {
  final Contact? contact;

  /// Every contact that shares the heard hash. Only interesting when the match
  /// was ambiguous; empty otherwise.
  final List<Contact> candidates;

  final RepeaterIdentitySource source;

  /// What to show on screen. Never a guess presented as fact: an ambiguous
  /// match lists all the candidates, and an unknown node is labelled by its own
  /// hash rather than borrowing a name.
  final String displayName;

  /// The 32-byte key this node can be addressed by — sent a message, logged
  /// into, given a path override. Null when we only ever heard a hash we could
  /// not pin to exactly one contact, because acting on a guess would target
  /// somebody else's repeater.
  final Uint8List? addressableKey;

  const RepeaterIdentity({
    required this.source,
    required this.displayName,
    this.contact,
    this.candidates = const [],
    this.addressableKey,
  });

  bool get isAmbiguous => source == RepeaterIdentitySource.ambiguousPrefix;

  /// True when the node is addressable but not in the contact book — the case
  /// discovery exists to surface.
  bool get isUnknownContact =>
      source == RepeaterIdentitySource.unknown && addressableKey != null;
}

class RepeaterIdentityHelper {
  /// Hash width used for the fallback label. Two bytes reads as an identifier
  /// ("Repeater A277") where one byte does not.
  static const int labelPrefixBytes = 2;

  /// Resolves the node behind a discovery response or an advert's last hop.
  ///
  /// Pass [publicKey] whenever the full 32 bytes were received — a repeater's
  /// NODE_DISCOVER_RESP always carries them (simple_repeater/MyMesh.cpp) and
  /// they settle the question outright. Pass [hashPrefix] alone only when the
  /// full key genuinely was not heard, e.g. a hop hash lifted from a path.
  ///
  /// A full key never falls back to hash matching. That fallback is what put a
  /// repeater 100 miles away on the tile for one ten feet away: the hash is 1–2
  /// bytes wide, so in a book of a few hundred contacts a collision is likely,
  /// and the colliding contact's name, location and key were all adopted.
  static RepeaterIdentity resolve({
    required List<Contact> contacts,
    List<int>? publicKey,
    List<int> hashPrefix = const [],
  }) {
    if (publicKey != null && publicKey.length >= pubKeySize) {
      final key = Uint8List.fromList(publicKey.sublist(0, pubKeySize));
      final hex = pubKeyToHex(key);
      for (final contact in contacts) {
        if (contact.publicKeyHex == hex) {
          return RepeaterIdentity(
            source: RepeaterIdentitySource.exactKey,
            displayName: _nameOf(contact, key),
            contact: contact,
            addressableKey: key,
          );
        }
      }
      // Addressable, just not known. The response carries no name field, so
      // there is nothing to show but its own identity.
      return RepeaterIdentity(
        source: RepeaterIdentitySource.unknown,
        displayName: unnamedLabel(key),
        addressableKey: key,
      );
    }

    final candidates = contactsMatchingHash(contacts, hashPrefix);
    if (candidates.isEmpty) {
      return RepeaterIdentity(
        source: RepeaterIdentitySource.unknown,
        displayName: unnamedLabel(hashPrefix),
      );
    }
    if (candidates.length == 1) {
      final contact = candidates.first;
      return RepeaterIdentity(
        source: RepeaterIdentitySource.uniquePrefix,
        displayName: _nameOf(contact, contact.publicKey),
        contact: contact,
        addressableKey: contact.publicKey.isEmpty
            ? null
            : Uint8List.fromList(contact.publicKey),
      );
    }
    return RepeaterIdentity(
      source: RepeaterIdentitySource.ambiguousPrefix,
      displayName: ambiguousLabel(candidates),
      candidates: List.unmodifiable(candidates),
    );
  }

  /// Every repeater or room contact whose own hash equals [hashPrefix].
  ///
  /// The comparison width is the width of [hashPrefix] itself, so a caller that
  /// heard a 2-byte hash is not silently narrowed to one byte.
  static List<Contact> contactsMatchingHash(
    List<Contact> contacts,
    List<int> hashPrefix,
  ) {
    if (hashPrefix.isEmpty) return const [];
    final wanted = PathHelper.hopHex(hashPrefix);
    final width = hashPrefix.length;
    return contacts
        .where(
          (c) =>
              c.publicKey.length >= width &&
              (c.type == advTypeRepeater || c.type == advTypeRoom) &&
              PathHelper.hopHex(
                    PathHelper.pubKeyPrefix(c.publicKey, stride: width),
                  ) ==
                  wanted,
        )
        .toList();
  }

  /// Label for a node we can identify but cannot name.
  static String unnamedLabel(List<int> publicKeyOrHash) {
    if (publicKeyOrHash.isEmpty) return 'Unknown repeater';
    final prefix = PathHelper.pubKeyPrefix(
      publicKeyOrHash,
      stride: labelPrefixBytes,
    );
    return 'Repeater ${PathHelper.hopHex(prefix)}';
  }

  /// Label for a hash several contacts answer to. Matches the convention
  /// [PathHelper.resolvePathNames] uses for ambiguous hops: show them all
  /// rather than pick one.
  static String ambiguousLabel(List<Contact> candidates) =>
      candidates.map((c) => c.name).join(' | ');

  static String _nameOf(Contact contact, List<int> key) =>
      contact.name.isNotEmpty ? contact.name : unnamedLabel(key);
}
