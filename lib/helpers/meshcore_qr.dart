class ChannelQrData {
  final String name;
  final String pskHex;

  ChannelQrData({required this.name, required this.pskHex});
}

class ContactQrData {
  final String name;
  final String pubKeyHex;
  final int type;

  ContactQrData({
    required this.name,
    required this.pubKeyHex,
    required this.type,
  });
}

class MeshCoreQr {
  static const String _channelPrefix = 'meshcore://channel/add';
  static const String _contactPrefix = 'meshcore://contact/add';

  /// Encode a channel to meshcore format
  static String encodeChannel(String name, String pskHex) {
    final encodedName = Uri.encodeComponent(name);
    return '$_channelPrefix?name=$encodedName&secret=$pskHex';
  }

  /// Encode a contact to meshcore format
  static String encodeContact(String name, String pubKeyHex, int type) {
    final encodedName = Uri.encodeComponent(name);
    return '$_contactPrefix?name=$encodedName&public_key=$pubKeyHex&type=$type';
  }

  /// Check if data is a valid channel QR
  static bool isChannelQr(String data) {
    if (!data.startsWith(_channelPrefix)) return false;
    final uri = Uri.tryParse(data);
    if (uri == null) return false;
    
    final name = uri.queryParameters['name'];
    final secret = uri.queryParameters['secret'];
    
    return name != null && secret != null && secret.length == 32;
  }

  /// Parse a channel QR
  static ChannelQrData? parseChannelQr(String data) {
    if (!isChannelQr(data)) return null;
    
    final uri = Uri.parse(data);
    return ChannelQrData(
      name: uri.queryParameters['name']!,
      pskHex: uri.queryParameters['secret']!,
    );
  }

  /// Check if data is a valid contact QR
  static bool isContactQr(String data) {
    if (!data.startsWith(_contactPrefix)) return false;
    final uri = Uri.tryParse(data);
    if (uri == null) return false;
    
    final pubKey = uri.queryParameters['public_key'];
    return pubKey != null && pubKey.length == 64;
  }

  /// Parse a contact QR
  static ContactQrData? parseContactQr(String data) {
    if (!data.startsWith(_contactPrefix)) return null;
    return parseContactParams(data);
  }

  /// Name, key and type from any link carrying `public_key=`
  /// (meshcore://contact/add, letsmesh.net). Read with regexes, not
  /// Uri.queryParameters, which throws on some emoji names.
  static ContactQrData? parseContactParams(String data) {
    final key = RegExp(r'[?&]public_key=([0-9a-fA-F]{64})').firstMatch(data);
    if (key == null) return null;
    var name = '';
    try {
      final match = RegExp(r'[?&]name=([^&]+)').firstMatch(data);
      if (match != null) name = Uri.decodeComponent(match.group(1)!);
    } catch (_) {
      // Undecodable name: keep the contact, without a name.
    }
    final type = RegExp(r'[?&]type=(\d+)').firstMatch(data);
    return ContactQrData(
      name: name,
      pubKeyHex: key.group(1)!,
      type: int.tryParse(type?.group(1) ?? '') ?? 1,
    );
  }
}
