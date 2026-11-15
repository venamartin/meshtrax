import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../models/contact_note.dart';

/// The person behind a contact: their real name and a note, as the user
/// writes them. Emptying both removes them.
class ContactNoteDialog extends StatefulWidget {
  final Contact contact;

  const ContactNoteDialog({super.key, required this.contact});

  static Future<void> show(BuildContext context, Contact contact) =>
      showDialog<void>(
        context: context,
        builder: (_) => ContactNoteDialog(contact: contact),
      );

  @override
  State<ContactNoteDialog> createState() => _ContactNoteDialogState();
}

class _ContactNoteDialogState extends State<ContactNoteDialog> {
  late final TextEditingController _realName;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final saved = context
        .read<MeshCoreConnector>()
        .contactNote(widget.contact.publicKeyHex);
    _realName = TextEditingController(text: saved?.realName ?? '');
    _note = TextEditingController(text: saved?.note ?? '');
  }

  @override
  void dispose() {
    _realName.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final navigator = Navigator.of(context);
    await context.read<MeshCoreConnector>().setContactNote(
          widget.contact.publicKeyHex,
          ContactNote(
            realName: _realName.text.trim(),
            note: _note.text.trim(),
          ),
        );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(l10n.contact_nameAndNote),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.contact.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _realName,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l10n.contact_realName),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l10n.contact_note),
            ),
            const SizedBox(height: 12),
            Text(l10n.contact_nameAndNoteHint, style: theme.textTheme.bodySmall),
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
