import 'package:material_ui/material_ui.dart';

import '../models/contact_note.dart';

/// The name the user gave a contact, in a soft pill beside its handle. It
/// holds no more than a nickname may, so a full name standing in for a
/// missing nickname is cut short with "…". A "?" marks a guess: more than
/// one contact uses the handle.
class NicknamePill extends StatelessWidget {
  final String name;
  final bool guess;

  const NicknamePill(this.name, {super.key, this.guess = false});

  /// [name] cut to fit: at most [ContactNote.nicknameMaxLength] characters,
  /// the last of them "…" when it was longer.
  static String fit(String name) {
    final characters = name.characters;
    const most = ContactNote.nicknameMaxLength;
    return characters.length <= most
        ? name
        : '${characters.take(most - 1)}…';
  }

  @override
  Widget build(BuildContext context) {
    final ink = Theme.of(context).colorScheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
      decoration: BoxDecoration(
        color: ink.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ink.withValues(alpha: 0.35), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (guess) ...[
            Icon(Icons.help_outline, size: 11, color: ink),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              fit(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: ink,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
