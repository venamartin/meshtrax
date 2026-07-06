import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:linkify/linkify.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/l10n.dart';
import 'package:provider/provider.dart';
import '../utils/platform_info.dart';
import '../helpers/snack_bar_builder.dart';
import '../connector/meshcore_connector.dart';
import '../models/channel.dart';
import '../screens/channel_chat_screen.dart';

class LinkHandler {
  static TextStyle defaultLinkStyle(BuildContext context, TextStyle base) {
    final brightness = Theme.of(context).brightness;
    final orange = brightness == Brightness.dark
        ? const Color(0xFFFFB74D)
        : const Color(0xFFE65100);
    return base.copyWith(color: orange, decoration: TextDecoration.underline);
  }

  /// Returns a [SelectableText.rich] on desktop or a [Text.rich] on mobile with custom styling for mentions.
  static Widget buildLinkifyText({
    required BuildContext context,
    required String text,
    required TextStyle style,
    TextStyle? linkStyle,
  }) {
    final effectiveLinkStyle = linkStyle ?? defaultLinkStyle(context, style);
    const options = LinkifyOptions(humanize: false, defaultToHttps: false);
    
    final elements = linkify(
      text,
      options: options,
      linkifiers: [
        const UrlLinkifier(), 
        const EmailLinkifier(),
        const MentionLinkifier(),
        const HashtagLinkifier(),
      ],
    );

    final spans = elements.map((element) {
      if (element is MentionElement) {
        return TextSpan(
          text: element.text,
          style: style.copyWith(
            backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.none,
          ),
        );
      } else if (element is HashtagElement) {
        return TextSpan(
          text: element.text,
          style: effectiveLinkStyle,
          recognizer: TapGestureRecognizer()..onTap = () => handleHashtagTap(context, element.text),
        );
      } else if (element is LinkableElement) {
        return TextSpan(
          text: element.text,
          style: effectiveLinkStyle,
          recognizer: TapGestureRecognizer()..onTap = () => handleLinkTap(context, element.url),
        );
      } else {
        return TextSpan(text: element.text, style: style);
      }
    }).toList();

    if (PlatformInfo.isDesktop) {
      return SelectableText.rich(
        TextSpan(children: spans),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
    );
  }

  static Future<void> handleHashtagTap(BuildContext context, String hashtag) async {
    final connector = context.read<MeshCoreConnector>();

    // Check if channel already exists
    final int existingIndex = connector.channels.indexWhere((c) => c.name == hashtag);
    if (existingIndex != -1) {
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ChannelChatScreen(
              channel: connector.channels[existingIndex],
            ),
          ),
        );
      }
      return;
    }

    // Show confirmation dialog
    final shouldAdd = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.channels_addChannel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.channels_addChannelConfirmation,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                hashtag,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.channels_addChannel),
          ),
        ],
      ),
    );

    if (shouldAdd != true) return;
    if (!context.mounted) return;

    int nextIndex = 1;
    for (int i = 1; i < connector.maxChannels; i++) {
      if (!connector.channels.any((c) => c.index == i)) {
        nextIndex = i;
        break;
      }
    }

    final psk = Channel.derivePskFromHashtag(hashtag.substring(1));
    connector.setChannel(nextIndex, hashtag, psk);

    showDismissibleSnackBar(
      context,
      content: Text(context.l10n.channels_channelAdded(hashtag)),
    );
  }

  static Future<void> handleLinkTap(BuildContext context, String url) async {
    // Show confirmation dialog
    final shouldOpen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.chat_openLink),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.chat_openLinkConfirmation,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                url,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.chat_open),
          ),
        ],
      ),
    );

    if (shouldOpen != true) return;

    // Launch URL
    try {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          showDismissibleSnackBar(
            context,
            content: Text(context.l10n.chat_couldNotOpenLink(url)),
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(context.l10n.chat_invalidLink),
          backgroundColor: Colors.red,
        );
      }
    }
  }
}

class MentionLinkifier extends Linkifier {
  const MentionLinkifier();

  @override
  List<LinkifyElement> parse(List<LinkifyElement> elements, LinkifyOptions options) {
    final list = <LinkifyElement>[];
    for (var element in elements) {
      if (element is TextElement) {
        final matches = RegExp(r'@\[([^\]]+)\]').allMatches(element.text);
        if (matches.isEmpty) {
          list.add(element);
          continue;
        }

        int lastIndex = 0;
        for (var match in matches) {
          if (match.start > lastIndex) {
            list.add(TextElement(element.text.substring(lastIndex, match.start)));
          }
          list.add(MentionElement(match.group(0)!));
          lastIndex = match.end;
        }

        if (lastIndex < element.text.length) {
          list.add(TextElement(element.text.substring(lastIndex)));
        }
      } else {
        list.add(element);
      }
    }
    return list;
  }
}

class MentionElement extends LinkableElement {
  MentionElement(String text) : super(text, text);
}

class HashtagLinkifier extends Linkifier {
  const HashtagLinkifier();

  @override
  List<LinkifyElement> parse(List<LinkifyElement> elements, LinkifyOptions options) {
    final list = <LinkifyElement>[];
    for (var element in elements) {
      if (element is TextElement) {
        final matches = RegExp(r'#[a-zA-Z0-9_-]+').allMatches(element.text);
        if (matches.isEmpty) {
          list.add(element);
          continue;
        }

        int lastIndex = 0;
        for (var match in matches) {
          if (match.start > lastIndex) {
            list.add(TextElement(element.text.substring(lastIndex, match.start)));
          }
          list.add(HashtagElement(match.group(0)!));
          lastIndex = match.end;
        }

        if (lastIndex < element.text.length) {
          list.add(TextElement(element.text.substring(lastIndex)));
        }
      } else {
        list.add(element);
      }
    }
    return list;
  }
}

class HashtagElement extends LinkableElement {
  HashtagElement(String text) : super(text, text);
}
