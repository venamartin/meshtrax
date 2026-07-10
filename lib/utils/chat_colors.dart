import 'package:flutter/material.dart';

/// Warm, WhatsApp-style palette used by the chat screens in **light mode only**.
///
/// In light mode this reads much softer than the seeded Material blue: a warm
/// background, white incoming bubbles, and soft green own bubbles. In dark mode
/// the chat screens keep their existing Material [ColorScheme] roles, so dark
/// mode is unchanged — call [isLight] to branch.
class ChatColors {
  const ChatColors._();

  /// Chat scaffold background.
  static const Color background = Color(0xFFECE5DD);

  /// Bubble colour for messages from others.
  static const Color incomingBubble = Color(0xFFFFFFFF);

  /// Bubble colour for the user's own messages.
  static const Color outgoingBubble = Color(0xFFD9FDD3);

  /// Text colour inside bubbles (near-black, for both sides).
  static const Color bubbleText = Color(0xFF111B21);

  /// Background of the reply-quote box shown inside a bubble.
  static const Color quoteBackground = Color(0xFFF0F0E8);

  /// Accent bar on the reply-quote box.
  static const Color quoteBorder = Color(0xFF6FB07A);

  /// Whether the warm palette applies (i.e. the app is in light mode).
  static bool isLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.light;
}
