import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';

/// [title] with an EXPERIMENTAL tag after it, on photos and TRAX mode in
/// the release that brings them. Owner, 2026-11-25: take it out in the
/// release after that one.
class ExperimentalTitle extends StatelessWidget {
  const ExperimentalTitle(this.title, {super.key});

  final Widget title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: title),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            context.l10n.common_experimental,
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }
}
