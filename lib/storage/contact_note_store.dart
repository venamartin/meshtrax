import 'package:drift/drift.dart';

import '../models/contact_note.dart';
import 'app_database.dart';

/// The names and notes the user gives contacts, by public key. Not scoped
/// to a radio: a person keeps the names whichever radio is connected.
class ContactNoteStore {
  AppDatabase get _db => AppDatabase.instance;

  Stream<Map<String, ContactNote>> watchAll() =>
      _db.select(_db.contactNoteRows).watch().map(
            (rows) => {
              for (final row in rows)
                row.publicKeyHex: ContactNote(
                  nickname: row.nickname,
                  realName: row.realName,
                  note: row.note,
                ),
            },
          );

  /// Saves [note] for the contact; an empty one removes the row.
  Future<void> save(String publicKeyHex, ContactNote note) async {
    final key = publicKeyHex.toLowerCase();
    if (note.isEmpty) {
      await (_db.delete(_db.contactNoteRows)
            ..where((r) => r.publicKeyHex.equals(key)))
          .go();
      return;
    }
    await _db.into(_db.contactNoteRows).insertOnConflictUpdate(
          ContactNoteRowsCompanion.insert(
            publicKeyHex: key,
            nickname: Value(note.nickname),
            realName: Value(note.realName),
            note: Value(note.note),
          ),
        );
  }
}
