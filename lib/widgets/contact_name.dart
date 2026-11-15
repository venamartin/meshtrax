import 'package:material_ui/material_ui.dart';

/// A contact's radio name with the real name the user gave it beside it,
/// lighter, on one line. The radio name comes first.
class ContactName extends StatelessWidget {
  final String name;
  final String? realName;
  final TextStyle? style;

  const ContactName(this.name, {super.key, this.realName, this.style});

  @override
  Widget build(BuildContext context) {
    final real = realName;
    return Text.rich(
      TextSpan(
        text: name,
        style: style,
        children: [
          if (real != null && real.isNotEmpty)
            TextSpan(
              text: '  $real',
              style: TextStyle(
                fontWeight: FontWeight.normal,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}
