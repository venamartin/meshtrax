import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/chat_text_scale_service.dart';

/// Gesture wrapper that exposes two-finger pinch-to-zoom for chat scrollables.
/// Double-tap resets the scale. Only the wrapper itself listens to gestures;
/// child scrollables keep their normal touch handling.
class ChatZoomWrapper extends StatefulWidget {
  const ChatZoomWrapper({super.key, required this.child, this.onDoubleTap});

  final Widget child;
  final VoidCallback? onDoubleTap;

  @override
  State<ChatZoomWrapper> createState() => _ChatZoomWrapperState();
}

class _ChatZoomWrapperState extends State<ChatZoomWrapper> {
  double? _startScale;
  bool _isScaling = false;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<ChatTextScaleService>();
    final currentScale = service.scale;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onDoubleTap: () {
        service.reset();
        service.persist();
        widget.onDoubleTap?.call();
      },
      onScaleStart: (details) {
        if (details.pointerCount != 2) return;
        setState(() {
          _isScaling = true;
          _startScale = service.scale;
        });
      },
      onScaleUpdate: (details) {
        if (!_isScaling) return;
        final baseScale = _startScale ?? service.scale;
        service.setScale(baseScale * details.scale);
      },
      onScaleEnd: (_) {
        setState(() {
          _isScaling = false;
          _startScale = null;
        });
        service.persist();
      },
      child: Stack(
        children: [
          widget.child,
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Center(
                child: AnimatedOpacity(
                  opacity: _isScaling ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${currentScale.toStringAsFixed(2)}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
