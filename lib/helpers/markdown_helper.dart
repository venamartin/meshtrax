import 'package:linkify/linkify.dart';

import 'linkifiers.dart';

/// One piece of message text and the formatting it is drawn with.
class MdRun {
  const MdRun(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.code = false,
    this.spoiler,
    this.header = 0,
    this.link,
  });

  final String text;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool code;

  /// Every run of one `||…||` shares this id, so a tap reveals all of it.
  final int? spoiler;

  /// 1–3 for `#`, `##`, `###` lines, 4 for `-#` subtext, 0 otherwise.
  final int header;

  /// Set for a tappable piece: URL, email, mention, hashtag, coordinate,
  /// meshcore:// link or `[text](url)` link.
  final LinkableElement? link;
}

/// Markdown for chat messages: `**bold**`, `*italic*` / `_italic_`,
/// `__underline__`, `~~strike~~`, `||spoiler||`, `` `code` ``,
/// ```` ```blocks``` ````, `#` / `##` / `###` / `-#` lines, `[text](url)`
/// and `\` escapes.
///
/// Display only: the stored and sent text is never rewritten, so reaction
/// hashes and reply snippets keep working on the raw text.
class MarkdownHelper {
  static const _options = LinkifyOptions(humanize: false, defaultToHttps: false);
  static const _placeholder = '￼';
  static const _escapable = r'\`*_~|[]()#-@';
  static final _mention = RegExp(r'@\[[^\]]+\]');
  static final _maskedLink = RegExp(
    r'\[([^\]\n]+)\]\((https?://[^\s)]+)\)',
    caseSensitive: false,
  );
  // Link text that reads like an address would hide where the link goes.
  static final _looksLikeUrl = RegExp(r'://|[\w-]+\.[a-z]{2,}', caseSensitive: false);
  static final _header = RegExp(r'^(#{1,3}|-#) +(\S[\s\S]*)$');
  static const _codeLanguages = {
    'bash', 'c', 'cpp', 'cs', 'css', 'dart', 'diff', 'go', 'html', 'ini',
    'java', 'javascript', 'js', 'json', 'kotlin', 'kt', 'lua', 'md',
    'markdown', 'php', 'py', 'python', 'rb', 'ruby', 'rs', 'rust', 'sh',
    'shell', 'sql', 'swift', 'text', 'toml', 'ts', 'txt', 'typescript',
    'xml', 'yaml', 'yml',
  };

  /// Splits [text] into runs. With [formatting] off only the tappable
  /// pieces are found and every markdown character stays as typed.
  static List<MdRun> parse(String text, {bool formatting = true}) {
    if (!formatting) {
      return [
        for (final e in linkify(text, options: _options, linkifiers: messageLinkifiers))
          MdRun(e.text, link: e is LinkableElement ? e : null),
      ];
    }
    final atoms = <MdRun>[];
    final working = _protect(text.replaceAll(_placeholder, ''), atoms);
    final inline = _Inline(atoms);
    final lines = working.split('\n');
    for (var n = 0; n < lines.length; n++) {
      if (n > 0) inline.runs.add(const MdRun('\n'));
      final h = _header.firstMatch(lines[n]);
      if (h == null) {
        inline.parseLine(lines[n], 0);
      } else {
        inline.parseLine(h.group(2)!, h.group(1) == '-#' ? 4 : h.group(1)!.length);
      }
    }
    return inline.runs;
  }

  /// [text] as it reads with the markers removed, for previews, quotes and
  /// notifications. A spoiler becomes `▮▮▮` so it never leaks.
  static String toPlainText(String text, {bool formatting = true}) {
    if (!formatting) return text;
    final out = StringBuffer();
    int? spoiler;
    for (final run in parse(text)) {
      if (run.spoiler == null) {
        out.write(run.text);
      } else if (run.spoiler != spoiler) {
        out.write('▮▮▮');
      }
      spoiler = run.spoiler;
    }
    return out.toString();
  }

  /// Pulls out everything that must not be formatted inside — escapes,
  /// code, `[text](url)` links, then URLs, mentions and the other tappable
  /// pieces — into [atoms], leaving one placeholder character for each.
  static String _protect(String text, List<MdRun> atoms) {
    final out = StringBuffer();
    final plain = StringBuffer();

    void flushPlain() {
      if (plain.isEmpty) return;
      for (final e in linkify(plain.toString(), options: _options, linkifiers: messageLinkifiers)) {
        if (e is LinkableElement) {
          atoms.add(MdRun(e.text, link: e));
          out.write(_placeholder);
        } else {
          out.write(e.text);
        }
      }
      plain.clear();
    }

    void atom(MdRun run) {
      flushPlain();
      atoms.add(run);
      out.write(_placeholder);
    }

    var i = 0;
    while (i < text.length) {
      final c = text[i];
      if (c == '\\' && i + 1 < text.length && _escapable.contains(text[i + 1])) {
        atom(MdRun(text[i + 1]));
        i += 2;
        continue;
      }
      if (text.startsWith('```', i)) {
        final end = text.indexOf('```', i + 3);
        if (end > i + 3) {
          atom(MdRun(_codeBlockBody(text.substring(i + 3, end)), code: true));
          i = end + 3;
          continue;
        }
      } else if (c == '`') {
        final end = text.indexOf('`', i + 1);
        if (end > i + 1 && !text.substring(i + 1, end).contains('\n')) {
          atom(MdRun(text.substring(i + 1, end), code: true));
          i = end + 1;
          continue;
        }
      } else if (c == '@') {
        // Names may hold markdown characters; keep the mention whole.
        final m = _mention.matchAsPrefix(text, i);
        if (m != null) {
          plain.write(m.group(0));
          i = m.end;
          continue;
        }
      } else if (c == '[') {
        final m = _maskedLink.matchAsPrefix(text, i);
        if (m != null && !_looksLikeUrl.hasMatch(m.group(1)!)) {
          atom(MdRun(m.group(1)!, link: MaskedLinkElement(m.group(1)!, m.group(2)!)));
          i = m.end;
          continue;
        }
      }
      plain.write(c);
      i++;
    }
    flushPlain();
    return out.toString();
  }

  static String _codeBlockBody(String body) {
    final nl = body.indexOf('\n');
    if (nl > 0 && _codeLanguages.contains(body.substring(0, nl).trim().toLowerCase())) {
      body = body.substring(nl + 1);
    }
    return body.replaceAll(RegExp(r'^\n+|\n+$'), '');
  }
}

class _Style {
  const _Style({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    this.spoiler,
  });

  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final int? spoiler;

  _Style add(String marker, int Function() newSpoiler) => _Style(
        bold: bold || marker == '***' || marker == '**',
        italic: italic || marker == '***' || marker == '*' || marker == '_',
        underline: underline || marker == '__',
        strike: strike || marker == '~~',
        spoiler: marker == '||' ? newSpoiler() : spoiler,
      );
}

/// Emphasis within one line. Close-marker lookups are memoised per line so a
/// run of unmatched markers can't make parsing blow up.
class _Inline {
  _Inline(this._atoms);

  static const _markers = ['***', '**', '__', '~~', '||', '*', '_'];
  static final _wordChar = RegExp(r'[\p{L}\p{N}]', unicode: true);

  final List<MdRun> _atoms;
  final runs = <MdRun>[];
  final _closeMemo = <int, int>{};
  var _nextAtom = 0;
  var _nextSpoiler = 0;
  var _s = '';
  var _header = 0;

  void parseLine(String line, int header) {
    _s = line;
    _header = header;
    _closeMemo.clear();
    _parse(0, line.length, const _Style());
  }

  void _parse(int start, int end, _Style style) {
    final buf = StringBuffer();
    var i = start;
    outer:
    while (i < end) {
      for (var mi = 0; mi < _markers.length; mi++) {
        final m = _markers[mi];
        if (!_s.startsWith(m, i) || !_canOpen(i, m)) continue;
        final close = _findClose(i + m.length, mi);
        if (close == -1 || close + m.length > end) continue;
        _emit(buf, style);
        _parse(i + m.length, close, style.add(m, () => _nextSpoiler++));
        i = close + m.length;
        continue outer;
      }
      buf.write(_s[i]);
      i++;
    }
    _emit(buf, style);
  }

  int _findClose(int from, int mi) =>
      _closeMemo[from * _markers.length + mi] ??= _scanClose(from, mi);

  int _scanClose(int from, int mi) {
    final m = _markers[mi];
    var j = from;
    scan:
    while (j < _s.length) {
      if (j > from && _s.startsWith(m, j) && _canClose(from, j, m)) return j;
      for (var ni = 0; ni < _markers.length; ni++) {
        final n = _markers[ni];
        if (!_s.startsWith(n, j) || !_canOpen(j, n)) continue;
        final nested = _findClose(j + n.length, ni);
        if (nested == -1) continue;
        j = nested + n.length;
        continue scan;
      }
      j++;
    }
    return -1;
  }

  bool _canOpen(int i, String m) {
    final after = i + m.length;
    if (after >= _s.length) return false;
    if (m == '||') return true;
    if (_isSpace(_s[after])) return false;
    if (m[0] == '_' && i > 0 && _wordChar.hasMatch(_s[i - 1])) return false;
    return true;
  }

  bool _canClose(int from, int j, String m) {
    if (m == '||') return _s.substring(from, j).trim().isNotEmpty;
    if (_isSpace(_s[j - 1])) return false;
    final after = j + m.length;
    if (m[0] == '_' && after < _s.length && _wordChar.hasMatch(_s[after])) {
      return false;
    }
    return true;
  }

  static bool _isSpace(String c) => c.trim().isEmpty;

  /// Adds [buf]'s text in [style], swapping each placeholder for its atom.
  void _emit(StringBuffer buf, _Style style) {
    if (buf.isEmpty) return;
    final parts = buf.toString().split(MarkdownHelper._placeholder);
    buf.clear();
    for (var p = 0; p < parts.length; p++) {
      if (p > 0) {
        final atom = _atoms[_nextAtom++];
        runs.add(_styled(atom.text, style, code: atom.code, link: atom.link));
      }
      if (parts[p].isNotEmpty) runs.add(_styled(parts[p], style));
    }
  }

  MdRun _styled(String text, _Style s, {bool code = false, LinkableElement? link}) =>
      MdRun(
        text,
        bold: s.bold,
        italic: s.italic,
        underline: s.underline,
        strike: s.strike,
        code: code,
        spoiler: s.spoiler,
        header: _header,
        link: link,
      );
}
