import '../connector/meshcore_protocol.dart' show advTypeChat;
import '../models/channel.dart';
import 'meshcore_qr.dart';

/// What a pasted, typed or scanned text adds.
sealed class AddFound {
  const AddFound();
}

/// A contact: a link with `public_key=` (meshcore://contact/add,
/// letsmesh.net), the radio's `meshcore://` card, `<key:type:name>` text,
/// or a bare 64-character key.
class ContactFound extends AddFound {
  final ContactQrData data;

  const ContactFound(this.data);
}

/// A channel: a meshcore://channel/add link, a hashtag, or a 32-character
/// secret key with the text around it as its name.
class ChannelFound extends AddFound {
  /// Null when only a key was given: the name has to be typed.
  final String? name;
  final String pskHex;

  /// The link's `region_scope`, when it has a usable one.
  final String? region;

  /// A hashtag channel as typed, capitals and all, for Keep capitals;
  /// [name] and [pskHex] are its lowercase channel.
  final String? typedHashtag;

  /// Read from a bare secret key: [name] is only a guess from the text
  /// around it, to be checked and typed.
  final bool keyOnly;

  const ChannelFound({
    this.name,
    required this.pskHex,
    this.region,
    this.typedHashtag,
    this.keyOnly = false,
  });

  bool get isHashtag => typedHashtag != null;

  bool get isPublic => pskHex == Channel.publicChannelPsk;

  /// The hashtag channel as typed: capitals make it another channel.
  ChannelFound get withCapitals => ChannelFound(
        name: typedHashtag,
        pskHex: Channel.formatPskHex(Channel.derivePskFromHashtag(typedHashtag!)),
        typedHashtag: typedHashtag,
      );
}

/// Reads any contact or channel format from one box (owner, 2026-11-26:
/// "Paste a link and manually add should be combined and just take any
/// format you can think of"). Channels have no `<...>` form.
class AddInput {
  static const maxChannelName = 31;

  static final _channelLink =
      RegExp(r'meshcore://channel/add\S*', caseSensitive: false);
  static final _contactText = RegExp(r'<[0-9a-fA-F]{64}:[1-4]:[^<>\r\n]+>');
  static final _key = RegExp(r'^[0-9a-fA-F]{64}$');
  static final _secret =
      RegExp(r'(?<![0-9a-fA-F])[0-9a-fA-F]{32}(?![0-9a-fA-F])');
  static final _labels =
      RegExp(r'\b(name|secret|key|psk)\s*[:=]', caseSensitive: false);
  static final _separators = RegExp(r'[\s,;|=:]+');
  static final _hashtag =
      RegExp(r'^#?([\p{L}\p{N}_\-]{1,30})$', unicode: true);

  static AddFound? read(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;

    final link = _channelLink.firstMatch(t);
    if (link != null) {
      final data = MeshCoreQr.parseChannelQr(link.group(0)!);
      if (data != null) {
        return ChannelFound(
          name: data.name,
          pskHex: data.pskHex.toLowerCase(),
          region: data.region,
        );
      }
    }

    final contact =
        MeshCoreQr.parseContactParams(t) ?? MeshCoreQr.parseAdvertCard(t);
    if (contact != null) return ContactFound(contact);
    final card = _contactText.firstMatch(t);
    final fromText =
        card == null ? null : MeshCoreQr.parseContactText(card.group(0)!);
    if (fromText != null) return ContactFound(fromText);
    if (_key.hasMatch(t)) {
      return ContactFound(ContactQrData(
        name: '',
        pubKeyHex: t.toLowerCase(),
        type: advTypeChat,
      ));
    }

    final secret = _secret.firstMatch(t);
    if (secret != null) {
      final pskHex = secret.group(0)!.toLowerCase();
      final rest = '${t.substring(0, secret.start)} ${t.substring(secret.end)}'
          .replaceAll(_labels, ' ')
          .replaceAll(_separators, ' ')
          .trim();
      final name = pskHex == Channel.publicChannelPsk && rest.isEmpty
          ? 'Public'
          : rest;
      return ChannelFound(
        name: name.isEmpty || name.length > maxChannelName ? null : name,
        pskHex: pskHex,
        keyOnly: true,
      );
    }

    final tag = _hashtag.firstMatch(t);
    if (tag != null) {
      final typed = '#${tag.group(1)}';
      final lower = typed.toLowerCase();
      return ChannelFound(
        name: lower,
        pskHex: Channel.formatPskHex(Channel.derivePskFromHashtag(lower)),
        typedHashtag: typed,
      );
    }
    return null;
  }
}
