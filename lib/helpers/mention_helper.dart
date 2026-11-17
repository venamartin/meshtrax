import 'package:flutter/services.dart';

import '../connector/meshcore_protocol.dart';
import '../models/channel_message.dart';
import '../models/contact.dart';
import '../models/contact_note.dart';
import '../utils/emoji_utils.dart';

/// The @ list of the channel and room chats: the @ word being typed, who
/// it offers, and the text a pick leaves in the box.
class MentionHelper {
  MentionHelper._();

  /// A MeshCore name is at most 32 bytes, so no longer text after the @ can
  /// still be one.
  static const _maxQuery = 32;

  static final _notInName = RegExp(r'[\n\[\]]');

  /// The @ the cursor is typing after and the text between them, or null
  /// when the cursor isn't in a mention. The @ starts the text or follows a
  /// space or line break. The text may hold spaces, so a name like
  /// "Ridge Walker" can be typed out, but can't start with one.
  static ({int at, String query})? query(TextEditingValue value) {
    final selection = value.selection;
    if (!selection.isValid || !selection.isCollapsed) return null;
    final cursor = selection.baseOffset;
    if (cursor == 0) return null;
    final text = value.text;
    final at = text.lastIndexOf('@', cursor - 1);
    if (at == -1) return null;
    if (at > 0 && text[at - 1] != ' ' && text[at - 1] != '\n') return null;
    final query = text.substring(at + 1, cursor);
    if (query.length > _maxQuery ||
        query.startsWith(' ') ||
        query.contains(_notInName)) {
      return null;
    }
    return (at: at, query: query);
  }

  /// The [candidates] whose name, nickname or full name holds [query], in
  /// their order, with the names that start with it first.
  static List<Contact> filter(
    List<Contact> candidates,
    String query,
    ContactNote? Function(String publicKeyHex) noteOf,
  ) {
    final lower = query.toLowerCase();
    final starting = <Contact>[];
    final holding = <Contact>[];
    for (final contact in candidates) {
      final name = contact.name.toLowerCase();
      if (name.startsWith(lower)) {
        starting.add(contact);
      } else if (name.contains(lower) ||
          (noteOf(contact.publicKeyHex)?.namesContain(lower) ?? false)) {
        holding.add(contact);
      }
    }
    return [...starting, ...holding];
  }

  /// The box once [name] is picked for the mention at [at]: "@[name] " in
  /// place of what was typed, with the cursor after it.
  static TextEditingValue insert(TextEditingValue value, int at, String name) {
    final mention = '@[$name] ';
    return TextEditingValue(
      text: value.text.replaceRange(at, value.selection.baseOffset, mention),
      selection: TextSelection.collapsed(offset: at + mention.length),
    );
  }

  /// Who a channel's @ list offers. First the people who posted in
  /// [messages] (oldest first), the latest poster first. A channel post
  /// carries only a name, so a poster is the contact of that name when
  /// exactly one has it, else a stand-in that carries just the name. Then
  /// the other people in [contacts], emoji-led names first (they can't be
  /// typed), the rest A to Z. Repeaters, rooms and sensors aren't people.
  static List<Contact> channelCandidates(
    List<ChannelMessage> messages,
    List<Contact> contacts,
  ) {
    // By lower-case name. When two contacts share a name, a post can't tell
    // which one wrote it, so there is no [only] contact.
    final byName = <String, ({String name, Contact? only})>{};
    for (final contact in contacts) {
      if (contact.type != advTypeChat) continue;
      final key = contact.name.toLowerCase();
      final seen = byName[key];
      byName[key] = seen == null
          ? (name: contact.name, only: contact)
          : (name: seen.name, only: null);
    }

    final offered = <String>{};
    final posters = <Contact>[];
    for (final message in messages.reversed) {
      if (message.isOutgoing) continue;
      final name = message.senderName.trim();
      final key = name.toLowerCase();
      if (name.isEmpty || !offered.add(key)) continue;
      posters.add(byName[key]?.only ?? _standIn(name));
    }

    final others = [
      for (final MapEntry(:key, :value) in byName.entries)
        if (!offered.contains(key))
          (
            key: key,
            contact: value.only ?? _standIn(value.name),
            emoji: _startsWithEmoji(value.name),
          ),
    ]..sort((a, b) {
        if (a.emoji != b.emoji) return a.emoji ? -1 : 1;
        return a.key.compareTo(b.key);
      });
    return [...posters, for (final other in others) other.contact];
  }

  static bool _startsWithEmoji(String name) {
    final emoji = firstEmoji(name);
    return emoji != null && name.startsWith(emoji);
  }

  static Contact _standIn(String name) => Contact(
        publicKey: Uint8List(pubKeySize),
        name: name,
        type: advTypeChat,
        pathLength: -1,
        path: Uint8List(0),
        pathHashSize: 1,
        lastSeen: DateTime.now(),
      );
}
