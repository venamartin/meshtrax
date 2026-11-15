/// What the user wrote down about a contact: the person's real name and a
/// note. Kept on this device and in radio backups; never sent.
class ContactNote {
  final String realName;
  final String note;

  const ContactNote({this.realName = '', this.note = ''});

  bool get isEmpty => realName.isEmpty && note.isEmpty;
}
