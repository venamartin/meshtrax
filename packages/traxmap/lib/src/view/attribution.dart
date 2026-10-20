import 'package:flutter/widgets.dart';

/// Small credits chip; one line until tapped, then the full text.
class AttributionChip extends StatefulWidget {
  final List<String> credits;
  final bool dark;

  const AttributionChip({super.key, required this.credits, this.dark = false});

  @override
  State<AttributionChip> createState() => _AttributionChipState();
}

class _AttributionChipState extends State<AttributionChip> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final fg = widget.dark ? const Color(0xFFD0D4DA) : const Color(0xFF3A3A3A);
    final bg = widget.dark ? const Color(0xB3202428) : const Color(0xB3FFFFFF);
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              widget.credits.join(' · '),
              maxLines: _expanded ? null : 1,
              overflow: _expanded ? null : TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: 10),
            ),
          ),
        ),
      ),
    );
  }
}
