import 'package:material_ui/material_ui.dart';

import '../helpers/calendar_share.dart';
import '../helpers/maps_link.dart';
import '../helpers/structured_message.dart';
import '../l10n/l10n.dart';

enum _Kind { none, maps, shortLink, calendar }

/// Sits above the composer. When the text looks like a Google Maps or
/// Google Calendar share, offers one tap to turn it into a Location or
/// Event line, so the mesh carries the compact form and the receiver needs
/// no internet. A Google short link has no position to read, so for one it
/// only says so.
class PasteConversionBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onReplace;

  const PasteConversionBar({
    super.key,
    required this.controller,
    required this.onReplace,
  });

  @override
  State<PasteConversionBar> createState() => _PasteConversionBarState();
}

class _PasteConversionBarState extends State<PasteConversionBar> {
  _Kind _kind = _Kind.none;
  String? _failedFor;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onText);
    _onText();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onText);
    super.dispose();
  }

  void _onText() {
    final text = widget.controller.text;
    final kind = _detect(text);
    if (kind != _kind) {
      setState(() {
        _kind = kind;
        if (_failedFor != text) _failedFor = null;
      });
    }
  }

  static _Kind _detect(String text) {
    if (text.trim().isEmpty || StructuredMessage.hasPrefix(text)) {
      return _Kind.none;
    }
    if (CalendarShare.looksLike(text)) return _Kind.calendar;
    final links = MapsLink.findAll(text);
    if (links.isEmpty) return _Kind.none;
    return MapsLink.isShortLink(links.first) ? _Kind.shortLink : _Kind.maps;
  }

  void _convert() {
    final text = widget.controller.text;
    String? wire;
    if (_kind == _Kind.calendar) {
      final share = CalendarShare.parse(text);
      if (share != null) {
        wire = EventMessage(
          title: share.title,
          when: EventWhen(
            start: share.start,
            end: share.end,
            allDay: share.allDay,
          ),
          link: share.link,
        ).toWire();
      }
    } else if (_kind == _Kind.maps) {
      wire = _convertMaps(text);
    }
    if (wire == null) {
      setState(() => _failedFor = text);
      return;
    }
    widget.onReplace(wire);
  }

  static String? _convertMaps(String text) {
    final url = MapsLink.findAll(text).first;
    final parsed = MapsLink.parse(url);
    if (parsed == null) return null;
    final free = text
        .replaceAll(url, '')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final label = free.isNotEmpty ? free.first : parsed.name;
    return LocationMessage(
      position: parsed.position,
      label: label,
      note: free.length > 1 ? free[1] : null,
      extraText: free.skip(2).toList(),
    ).toWire();
  }

  @override
  Widget build(BuildContext context) {
    if (_kind == _Kind.none) return const SizedBox.shrink();
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final failed = _failedFor == widget.controller.text;
    final message = failed
        ? l10n.paste_resolveFailed
        : switch (_kind) {
            _Kind.calendar => l10n.paste_convertEvent,
            _Kind.shortLink => l10n.paste_shortLinkNoPosition,
            _ => l10n.paste_convertLocation,
          };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: scheme.secondaryContainer,
      child: Row(
        children: [
          Icon(
            _kind == _Kind.calendar ? Icons.event : Icons.location_on,
            size: 18,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: scheme.onSecondaryContainer),
            ),
          ),
          if (!failed && _kind != _Kind.shortLink)
            TextButton(
              onPressed: _convert,
              child: Text(l10n.paste_convert),
            ),
        ],
      ),
    );
  }
}
