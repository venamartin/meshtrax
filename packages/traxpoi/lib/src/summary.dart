/// Where a summary link goes: a place or a feature in the same file.
typedef SummaryLink = ({bool feature, int id});

/// One piece of an article summary and how it's drawn. Paragraph breaks
/// stay in [text] as `\n\n`.
class SummaryRun {
  final String text;
  final bool bold;
  final bool italic;
  final SummaryLink? link;

  const SummaryRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.link,
  });
}

final _link = RegExp(r'\[((?:\\.|[^\]\\])*)\]\((place|feature):(\d+)\)');
final _escape = RegExp(r'\\(.)');

/// Splits a `wiki.summary` (README: wiki, a small Markdown subset) into
/// runs. Unbalanced markers are forgiven: they only switch the style.
List<SummaryRun> parseSummary(String summary) {
  final runs = <SummaryRun>[];
  final text = StringBuffer();
  var bold = false, italic = false;

  void flush() {
    if (text.isEmpty) return;
    runs.add(SummaryRun(text.toString(), bold: bold, italic: italic));
    text.clear();
  }

  var i = 0;
  while (i < summary.length) {
    final c = summary[i];
    if (c == r'\' && i + 1 < summary.length) {
      text.write(summary[i + 1]);
      i += 2;
    } else if (summary.startsWith('**', i)) {
      flush();
      bold = !bold;
      i += 2;
    } else if (c == '*') {
      flush();
      italic = !italic;
      i++;
    } else if (_link.matchAsPrefix(summary, i) case final m?) {
      flush();
      runs.add(
        SummaryRun(
          m[1]!.replaceAllMapped(_escape, (e) => e[1]!),
          bold: bold,
          italic: italic,
          link: (feature: m[2] == 'feature', id: int.parse(m[3]!)),
        ),
      );
      i = m.end;
    } else {
      text.write(c);
      i++;
    }
  }
  flush();
  return runs;
}
