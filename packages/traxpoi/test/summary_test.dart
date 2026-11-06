import 'package:test/test.dart';
import 'package:traxpoi/traxpoi.dart';

void main() {
  String show(List<SummaryRun> runs) => [
    for (final r in runs)
      [
        if (r.bold) 'B',
        if (r.italic) 'I',
        if (r.link case final l?) '${l.feature ? 'f' : 'p'}${l.id}',
        r.text,
      ].join(':'),
  ].join('|');

  test('paragraphs, emphasis and links', () {
    expect(
      show(
        parseSummary(
          'The **Camp Bird Mine** lies between [Ouray](feature:12) and '
          '[Telluride](feature:40).\n\nSee *Father Struck It Rich*.',
        ),
      ),
      'The |B:Camp Bird Mine| lies between |f12:Ouray| and |f40:Telluride|'
      '.\n\nSee |I:Father Struck It Rich|.',
    );
  });

  test('emphasis nests', () {
    expect(show(parseSummary('**Camp Bird *Mine***')), 'B:Camp Bird |B:I:Mine');
  });

  test('links to places, and escapes', () {
    expect(
      show(parseSummary(r'Near [Box Cañon \[falls\]](place:7): 5 \* 3 \\ 2')),
      r'Near |p7:Box Cañon [falls]|: 5 * 3 \ 2',
    );
  });

  test('anything else stays text', () {
    const other = '[Hope Diamond](https://example.com) [x] ~~y~~ ||z|| #1 @a';
    expect(show(parseSummary(other)), other);
  });
}
