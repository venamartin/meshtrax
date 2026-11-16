import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/contact_note.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/contact_note_store.dart';

void main() {
  setUp(AppDatabase.useInMemoryForTesting);

  final key = 'ab' * 32;

  test('saves, replaces and removes what the user wrote about a contact',
      () async {
    final store = ContactNoteStore();
    await store.save(
      key,
      const ContactNote(
        nickname: 'Annie',
        realName: 'Ann Smith',
        note: 'Lives up the hill',
      ),
    );
    var all = await store.watchAll().first;
    expect(all.keys, [key]);
    expect(all[key]!.nickname, 'Annie');
    expect(all[key]!.realName, 'Ann Smith');
    expect(all[key]!.note, 'Lives up the hill');

    await store.save(key, const ContactNote(realName: 'Ann Jones'));
    all = await store.watchAll().first;
    expect(all[key]!.realName, 'Ann Jones');
    expect(all[key]!.nickname, '', reason: 'a save replaces every field');
    expect(all[key]!.note, '');

    await store.save(key, const ContactNote());
    expect(await store.watchAll().first, isEmpty);
  });

  test('a key in capitals is the same contact', () async {
    final store = ContactNoteStore();
    await store.save(key.toUpperCase(), const ContactNote(realName: 'Ann'));
    await store.save(key, const ContactNote(realName: 'Ann Smith'));
    final all = await store.watchAll().first;
    expect(all.keys, [key]);
    expect(all[key]!.realName, 'Ann Smith');
  });
}
