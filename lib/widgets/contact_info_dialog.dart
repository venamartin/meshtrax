import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/contact_note.dart';

/// A contact: the nickname, full name and note the user writes, kept on
/// this device only, above what the radio knows of it. Emptying all three
/// removes them.
class ContactInfoDialog extends StatefulWidget {
  final Contact contact;

  const ContactInfoDialog({super.key, required this.contact});

  static Future<void> show(BuildContext context, Contact contact) =>
      showDialog<void>(
        context: context,
        builder: (_) => ContactInfoDialog(contact: contact),
      );

  @override
  State<ContactInfoDialog> createState() => _ContactInfoDialogState();
}

class _ContactInfoDialogState extends State<ContactInfoDialog> {
  late final TextEditingController _nickname;
  late final TextEditingController _realName;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final saved = context
        .read<MeshCoreConnector>()
        .contactNote(widget.contact.publicKeyHex);
    _nickname = TextEditingController(text: saved?.nickname ?? '');
    _realName = TextEditingController(text: saved?.realName ?? '');
    _note = TextEditingController(text: saved?.note ?? '');
  }

  @override
  void dispose() {
    _nickname.dispose();
    _realName.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    await context.read<MeshCoreConnector>().setContactNote(
          widget.contact.publicKeyHex,
          ContactNote(
            nickname: _nickname.text.trim(),
            realName: _realName.text.trim(),
            note: _note.text.trim(),
          ),
        );
    navigator.pop();
  }

  /// When this radio last heard from the contact: an advert it heard (else
  /// the time the contact's own clock gave), or a message, if later.
  DateTime _lastSeen(MeshCoreConnector connector) {
    final contact = widget.contact;
    final advert = connector.getLocalDiscoveredTime(contact.publicKeyHex) ??
        (contact.lastSeen.year > 2000 ? contact.lastSeen : null);
    if (advert == null || contact.lastMessageAt.isAfter(advert)) {
      return contact.lastMessageAt;
    }
    return advert;
  }

  String _ago(DateTime time) {
    final l10n = context.l10n;
    final diff = DateTime.now().difference(time);
    if (diff.isNegative || diff.inMinutes < 5) return l10n.contacts_lastSeenNow;
    if (diff.inMinutes < 60) return l10n.contacts_lastSeenMinsAgo(diff.inMinutes);
    if (diff.inHours < 24) {
      return diff.inHours == 1
          ? l10n.contacts_lastSeenHourAgo
          : l10n.contacts_lastSeenHoursAgo(diff.inHours);
    }
    return diff.inDays == 1
        ? l10n.contacts_lastSeenDayAgo
        : l10n.contacts_lastSeenDaysAgo(diff.inDays);
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: TextStyle(color: Colors.grey[600])),
            ),
            Expanded(child: SelectableText(value)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final contact = widget.contact;
    final connector = context.read<MeshCoreConnector>();
    return AlertDialog(
      title: SelectableText(contact.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nickname,
              maxLength: ContactNote.nicknameMaxLength,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.contact_nickname),
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _realName,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.contact_fullName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.contact_note),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.contact_nameAndNoteHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 24),
            _row(l10n.chat_type, contact.typeLabel),
            _row(l10n.chat_path, contact.pathLabel),
            _row(l10n.contact_lastSeen, _ago(_lastSeen(connector))),
            if (contact.hasLocation)
              _row(
                l10n.chat_location,
                '${contact.latitude?.toStringAsFixed(4)}, '
                    '${contact.longitude?.toStringAsFixed(4)}',
              ),
            _row(l10n.chat_publicKey, contact.publicKeyHex),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        TextButton(onPressed: _save, child: Text(l10n.common_save)),
      ],
    );
  }
}
