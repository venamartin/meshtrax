import 'package:flutter/services.dart';

/// Shows a hashtag channel's name in lowercase as it is typed. Its key
/// comes from the name exactly as written, so #Test and #test are two
/// channels and a stray capital lands in the wrong one.
///
/// [typed] keeps the text as typed, so turning [keepCapitals] on can put
/// the capitals back.
class HashtagCaseFormatter extends TextInputFormatter {
  bool keepCapitals = false;

  /// Set at the first capital typed; [onCapital] is called then.
  bool sawCapital = false;
  VoidCallback? onCapital;

  /// The text as typed, capitals and all.
  String typed = '';

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    typed = _typedAfter(oldValue.text, newValue);
    final lower = newValue.text.toLowerCase();
    if (keepCapitals || lower == newValue.text) return newValue;
    if (!sawCapital) {
      sawCapital = true;
      onCapital?.call();
    }
    // Not under a word the keyboard is still composing: changing it there
    // can make the keyboard type it again. It is lowercased once done.
    final composing = newValue.composing;
    if (composing.isValid && !composing.isCollapsed) return newValue;
    if (lower.length != newValue.text.length) {
      return TextEditingValue(
        text: lower,
        selection: TextSelection.collapsed(offset: lower.length),
      );
    }
    return newValue.copyWith(text: lower);
  }

  /// [typed] with the same edit that turned [before] into [after]. The
  /// shown text and [typed] differ only in case, so the edit is the span
  /// that differs, placed by the cursor where letters repeat.
  String _typedAfter(String before, TextEditingValue after) {
    final text = after.text;
    if (typed.length != before.length) return text;
    final cursor = after.selection.isValid ? after.selection.end : text.length;
    var end = 0;
    while (end < before.length &&
        end < text.length - cursor &&
        before[before.length - 1 - end] == text[text.length - 1 - end]) {
      end++;
    }
    var start = 0;
    while (start < before.length - end &&
        start < text.length - end &&
        before[start] == text[start]) {
      start++;
    }
    return typed.substring(0, start) +
        text.substring(start, text.length - end) +
        typed.substring(typed.length - end);
  }
}
