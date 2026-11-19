import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:linkify/linkify.dart';
import 'package:provider/provider.dart';

import '../helpers/link_handler.dart';
import '../helpers/linkifiers.dart';
import '../helpers/markdown_helper.dart';
import '../services/app_settings_service.dart';
import '../utils/platform_info.dart';

/// Message body text: markdown, tappable links, mentions and hashtags, and
/// spoilers that reveal on tap. Selectable on desktop.
class MessageText extends StatefulWidget {
  const MessageText({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<MessageText> createState() => _MessageTextState();
}

class _MessageTextState extends State<MessageText> {
  static const _headerScale = [1.0, 1.5, 1.3, 1.15, 0.8];

  final _revealed = <int>{};
  final _recognizers = <TapGestureRecognizer>[];

  static String get _monospaceFamily {
    if (PlatformInfo.isWindows) return 'Consolas';
    if (PlatformInfo.isMacOS || PlatformInfo.isIOS) return 'Menlo';
    return 'monospace';
  }

  @override
  void didUpdateWidget(MessageText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _revealed.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  TapGestureRecognizer _onTap(VoidCallback onTap) {
    final r = TapGestureRecognizer()..onTap = onTap;
    _recognizers.add(r);
    return r;
  }

  // Parsed runs by text and setting, shared by every row: a row is built
  // again each time it scrolls into view, and a parse is markdown plus six
  // linkifiers (owner, 2026-10-26: glitches scrolling through messages).
  static final _runs = <(String, bool), List<MdRun>>{};
  static const _runsCap = 800;

  static List<MdRun> _parsed(String text, bool formatting) {
    final key = (text, formatting);
    final hit = _runs[key];
    if (hit != null) return hit;
    final runs = MarkdownHelper.parse(text, formatting: formatting);
    _runs[key] = runs;
    if (_runs.length > _runsCap) _runs.remove(_runs.keys.first);
    return runs;
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final formatting = context.select<AppSettingsService, bool>(
      (s) => s.settings.showTextFormatting,
    );
    final runs = _parsed(widget.text, formatting);
    if (runs.any((r) => r.bullet)) return _withList(context, runs);
    final spans = [for (final run in runs) _span(context, run)];
    if (PlatformInfo.isDesktop) {
      // No Copy / Select all menu of its own: a right-click opens the
      // message's menu (ContextMenuRegion). Ctrl+C still copies a selection.
      return SelectableText.rich(
        TextSpan(children: spans),
        contextMenuBuilder: null,
      );
    }
    return Text.rich(TextSpan(children: spans));
  }

  /// A message with a list, line by line: a bullet's wrapped lines line up
  /// under its text, not under the bullet.
  Widget _withList(BuildContext context, List<MdRun> runs) {
    final style = widget.style;
    final em = MediaQuery.textScalerOf(context).scale(
      style.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14,
    );
    final children = <Widget>[];
    // The plain lines since the last bullet, each its own list of spans.
    var paragraph = <List<InlineSpan>>[];
    var line = <InlineSpan>[];
    var bullet = false;
    InlineSpan? newline;

    void endParagraph() {
      if (paragraph.isEmpty) return;
      children.add(
        Text.rich(
          TextSpan(
            children: [
              for (var i = 0; i < paragraph.length; i++) ...[
                if (i > 0) newline!,
                ...paragraph[i],
              ],
            ],
          ),
        ),
      );
      paragraph = [];
    }

    void endLine() {
      if (bullet) {
        endParagraph();
        children.add(
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              SizedBox(
                width: em * 1.25,
                child: Text('•', style: style, textAlign: TextAlign.center),
              ),
              Flexible(child: Text.rich(TextSpan(children: line))),
            ],
          ),
        );
      } else {
        paragraph.add(line);
      }
      line = [];
      bullet = false;
    }

    for (final run in runs) {
      if (run.bullet) {
        bullet = true;
      } else if (run.text == '\n' && !run.code) {
        newline ??= _span(context, run);
        endLine();
      } else {
        line.add(_span(context, run));
      }
    }
    endLine();
    endParagraph();
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
    // As SelectableText above: no menu of its own, so a right-click opens
    // the message's.
    return PlatformInfo.isDesktop
        ? SelectionArea(contextMenuBuilder: null, child: column)
        : column;
  }

  TextSpan _span(BuildContext context, MdRun run) {
    final base = widget.style;
    final color = base.color ?? DefaultTextStyle.of(context).style.color;
    final link = run.link;
    final isMention = link is MentionElement;
    final isLink = link != null && !isMention;
    final isHeader = run.header >= 1 && run.header <= 3;
    var style = base.copyWith(
      fontSize: (base.fontSize ?? 14) * _headerScale[run.header],
      fontWeight: run.bold || isHeader || isMention
          ? FontWeight.bold
          : isLink
              ? FontWeight.w600
              : null,
      fontStyle: run.italic ? FontStyle.italic : null,
      decoration: TextDecoration.combine([
        if (run.underline || isLink) TextDecoration.underline,
        if (run.strike) TextDecoration.lineThrough,
      ]),
      decorationColor: color,
      decorationThickness: run.strike ? 2.0 : null,
      color: run.header == 4 || run.code ? color?.withValues(alpha: 0.75) : null,
      backgroundColor: isMention
          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
          : null,
      fontFamily: run.code ? _monospaceFamily : null,
      fontFamilyFallback: run.code
          ? const ['Courier New', 'Courier', 'Roboto Mono', 'Monaco']
          : null,
    );

    final spoiler = run.spoiler;
    if (spoiler != null && !_revealed.contains(spoiler)) {
      return TextSpan(
        text: run.text,
        style: style.copyWith(
          color: color,
          backgroundColor: color,
          decoration: TextDecoration.none,
        ),
        recognizer: _onTap(() => setState(() => _revealed.add(spoiler))),
      );
    }
    if (spoiler != null) {
      style = style.copyWith(backgroundColor: color?.withValues(alpha: 0.12));
    }

    final recognizer = switch (link) {
      null || MentionElement() => null,
      HashtagElement(:final text) =>
        _onTap(() => LinkHandler.handleHashtagTap(context, text)),
      MeshCoreLinkElement(:final url) =>
        _onTap(() => LinkHandler.handleMeshCoreLink(context, url)),
      CoordinateElement(:final position) =>
        _onTap(() => LinkHandler.openMapAt(context, position)),
      LinkableElement(:final url) =>
        _onTap(() => LinkHandler.handleLinkTap(context, url)),
    };
    return TextSpan(text: run.text, style: style, recognizer: recognizer);
  }
}
