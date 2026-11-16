/// What the user wrote down about a contact: a nickname, the person's full
/// name and a note. Kept on this device and in radio backups; never sent.
class ContactNote {
  /// A nickname shows in a pill beside the handle, so it is kept short.
  static const nicknameMaxLength = 12;

  final String nickname;

  /// The person's full name.
  final String realName;
  final String note;

  const ContactNote({this.nickname = '', this.realName = '', this.note = ''});

  bool get isEmpty => nickname.isEmpty && realName.isEmpty && note.isEmpty;

  /// Beside the radio name in lists: the full name, else the nickname.
  String? get listName => _either(realName, nickname);

  /// In the pill beside a channel sender's handle: the nickname, else the
  /// full name.
  String? get pillName => _either(nickname, realName);

  /// Whether either name contains [lowerQuery], already lower-cased.
  bool namesContain(String lowerQuery) =>
      nickname.toLowerCase().contains(lowerQuery) ||
      realName.toLowerCase().contains(lowerQuery);

  static String? _either(String first, String second) =>
      first.isNotEmpty ? first : (second.isNotEmpty ? second : null);
}
