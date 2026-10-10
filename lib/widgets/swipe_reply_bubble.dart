import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';

/// Wraps a message bubble with the swipe-to-reply gesture: swipe left to
/// reply, swipe right to mention (when [onMentionTriggered] is set).
class SwipeReplyBubble extends StatefulWidget {
  final double maxSwipeOffset;
  final double replySwipeThreshold;
  final VoidCallback onReplyTriggered;
  /// Optional swipe-right action; null keeps the bubble left-swipe only.
  final VoidCallback? onMentionTriggered;
  final Widget Function({required bool mention}) hintBuilder;
  final Widget child;

  const SwipeReplyBubble({
    super.key,
    required this.maxSwipeOffset,
    required this.replySwipeThreshold,
    required this.onReplyTriggered,
    this.onMentionTriggered,
    required this.hintBuilder,
    required this.child,
  });

  @override
  State<SwipeReplyBubble> createState() => _SwipeReplyBubbleState();
}

class _SwipeReplyBubbleState extends State<SwipeReplyBubble> {
  Offset? _swipeStartPosition;
  double _swipeOffset = 0;
  int? _swipePointerId;
  bool _swipeLockedToHorizontal = false;
  // A vertical-dominant start is a scroll: ignore this touch entirely.
  bool _swipeRejected = false;
  // Finger is past the trigger threshold RIGHT NOW (release would commit).
  bool _swipeArmed = false;
  // Which way this gesture is going: -1 left (reply), +1 right (mention).
  int _swipeDirection = 0;

  bool get _mentionEnabled => widget.onMentionTriggered != null;

  void _handleSwipeStart(Offset position) {
    _swipeStartPosition = position;
    if (_swipeOffset != 0) {
      setState(() => _swipeOffset = 0);
    }
  }

  void _handleSwipePointerDown(PointerDownEvent event) {
    _swipePointerId = event.pointer;
    _swipeLockedToHorizontal = false;
    _swipeRejected = false;
    _swipeArmed = false;
    _swipeDirection = 0;
    _handleSwipeStart(event.position);
  }

  void _handleSwipePointerMove(PointerMoveEvent event) {
    if (_swipePointerId != event.pointer ||
        _swipeStartPosition == null ||
        _swipeRejected) {
      return;
    }

    final dx = event.position.dx - _swipeStartPosition!.dx;
    final dy = event.position.dy - _swipeStartPosition!.dy;

    const axisLockThreshold = 12.0;
    if (!_swipeLockedToHorizontal) {
      // Native feel: the swipe only claims the touch when horizontal
      // movement clearly dominates. A vertical-dominant start is the list
      // scrolling — reject the touch for good so a mid-scroll thumb arc
      // can never turn into a reply.
      if (dy.abs() >= axisLockThreshold && dy.abs() >= dx.abs()) {
        _swipeRejected = true;
        return;
      }
      if (dx.abs() < axisLockThreshold || dx.abs() < dy.abs() * 1.5) {
        return;
      }
      if (dx < 0) {
        _swipeDirection = -1;
      } else if (_mentionEnabled) {
        _swipeDirection = 1;
      } else {
        _swipeRejected = true;
        return;
      }
      _swipeLockedToHorizontal = true;
    }

    _handleSwipeUpdate(event.position);
  }

  void _handleSwipeUpdate(Offset position) {
    if (_swipeStartPosition == null) return;

    // Progress along the locked direction; movement the other way resets to 0.
    final dx =
        (position.dx - _swipeStartPosition!.dx) * _swipeDirection;
    final travel = dx < 6 ? 0.0 : dx;

    // Armed = releasing now would commit. Crossing the line gives the
    // little haptic tick native apps use; sliding back disarms silently.
    final armed = travel >= widget.replySwipeThreshold;
    if (armed && !_swipeArmed) {
      HapticFeedback.lightImpact();
    }
    _swipeArmed = armed;

    final clamped = travel.clamp(0.0, widget.maxSwipeOffset);
    final adjusted =
        _applySwipeResistance(clamped, widget.maxSwipeOffset) *
        _swipeDirection;
    if (adjusted != _swipeOffset) {
      setState(() => _swipeOffset = adjusted);
    }
  }

  void _handleSwipePointerUp(Offset position) {
    // Commit on where the finger IS at release, never on how far it once
    // got: overshooting and pulling back means "never mind".
    if (_swipeLockedToHorizontal && _swipeStartPosition != null) {
      final dx =
          (position.dx - _swipeStartPosition!.dx) * _swipeDirection;
      if (dx >= widget.replySwipeThreshold) {
        if (_swipeDirection < 0) {
          widget.onReplyTriggered();
        } else {
          widget.onMentionTriggered?.call();
        }
        HapticFeedback.selectionClick();
      }
    }
    _resetSwipe();
  }

  void _resetSwipe() {
    if (_swipeOffset != 0) {
      setState(() => _swipeOffset = 0);
    }
    _swipeStartPosition = null;
    _swipePointerId = null;
    _swipeLockedToHorizontal = false;
    _swipeRejected = false;
    _swipeArmed = false;
    _swipeDirection = 0;
  }

  double _applySwipeResistance(double rawOffset, double maxOffset) {
    final abs = rawOffset.abs();
    if (abs <= 0) return 0;
    final norm = (abs / maxOffset).clamp(0.0, 1.0);
    const deadZone = 0.18;
    if (norm <= deadZone) {
      return rawOffset.sign * maxOffset * (norm * 0.08);
    }
    final t = ((norm - deadZone) / (1 - deadZone)).clamp(0.0, 1.0);
    final curved = t < 0.5
        ? 16 * math.pow(t, 5)
        : 1 - math.pow(-2 * t + 2, 5) / 2;
    const deadZoneEnd = 0.0144;
    return rawOffset.sign *
        maxOffset *
        (deadZoneEnd + curved * (1 - deadZoneEnd));
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _handleSwipePointerDown,
      onPointerMove: _handleSwipePointerMove,
      onPointerUp: (event) => _handleSwipePointerUp(event.position),
      onPointerCancel: (_) => _resetSwipe(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: _swipeOffset.abs() / widget.maxSwipeOffset,
                child: widget.hintBuilder(mention: _swipeDirection > 0),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              transform: Matrix4.translationValues(_swipeOffset, 0, 0),
              curve: Curves.easeOut,
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}

/// Hint behind a swiped bubble: reply rides the left swipe (label at the
/// trailing edge, icon outermost), mention rides the right swipe (mirrored).
class SwipeHint extends StatelessWidget {
  final bool mention;

  const SwipeHint({super.key, required this.mention});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final icon = Icon(
      mention ? Icons.alternate_email : Icons.reply,
      color: colorScheme.primary,
    );
    final label = Text(
      mention ? context.l10n.chat_mention : context.l10n.chat_reply,
      style: TextStyle(
        color: colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );

    return Container(
      alignment: mention ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: colorScheme.primary.withValues(alpha: 0.08),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: mention
            ? [icon, const SizedBox(width: 6), label]
            : [label, const SizedBox(width: 6), icon],
      ),
    );
  }
}
