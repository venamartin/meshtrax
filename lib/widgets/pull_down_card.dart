import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

/// A card under a map that slides down to its [header], giving the map the
/// room, and back up to [openHeight]: dragged by its header (by the handle
/// on top), or with a tap on it. [child] fills the rest of the card.
class PullDownCard extends StatefulWidget {
  final Widget header;
  final Widget child;
  final double openHeight;

  const PullDownCard({
    super.key,
    required this.header,
    required this.child,
    required this.openHeight,
  });

  @override
  State<PullDownCard> createState() => _PullDownCardState();
}

class _PullDownCardState extends State<PullDownCard>
    with SingleTickerProviderStateMixin {
  /// How far open the card is: 1 at [PullDownCard.openHeight], 0 down to
  /// its header.
  late final _open = AnimationController(
    vsync: this,
    value: 1,
    duration: const Duration(milliseconds: 200),
  );
  final _headerKey = GlobalKey();

  /// The header's height, measured after each layout: it follows the text
  /// size.
  double _header = 56;

  @override
  void dispose() {
    _open.dispose();
    super.dispose();
  }

  void _measure() {
    final height = _headerKey.currentContext?.size?.height;
    if (mounted && height != null && height != _header) {
      setState(() => _header = height);
    }
  }

  /// What the card's margin (8) and the line under the header (1) leave
  /// for sliding.
  double get _travel => math.max(widget.openHeight - 9 - _header, 1);

  void _drag(DragUpdateDetails details) =>
      _open.value -= details.delta.dy / _travel;

  /// A flick goes its way; a slow drag goes to the nearer end.
  void _settle(DragEndDetails details) {
    final speed = details.velocity.pixelsPerSecond.dy;
    final up = speed.abs() > 300 ? speed < 0 : _open.value > 0.5;
    _open.animateTo(up ? 1 : 0, curve: Curves.easeOut);
  }

  void _toggle() =>
      _open.animateTo(_open.value > 0.5 ? 0 : 1, curve: Curves.easeOut);

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    final handle = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: AnimatedBuilder(
        animation: _open,
        builder: (context, card) =>
            SizedBox(height: 9 + _header + _travel * _open.value, child: card),
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _toggle,
                onVerticalDragUpdate: _drag,
                onVerticalDragEnd: _settle,
                child: KeyedSubtree(
                  key: _headerKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: handle.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      widget.header,
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: widget.child),
            ],
          ),
        ),
      ),
    );
  }
}
