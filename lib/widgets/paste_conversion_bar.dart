import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../helpers/calendar_share.dart';
import '../helpers/maps_link.dart';
import '../helpers/structured_message.dart';
import '../l10n/l10n.dart';
import '../services/short_link_resolver.dart';

enum _Kind { none, maps, calendar }

/// Sits above the composer. When the text looks like a Google Maps or
/// Google Calendar share, offers one tap to turn it into a Location or
/// Event line, so the mesh carries the compact form and the receiver needs
/// no internet.
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
  bool _resolving = false;
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
    if (MapsLink.findAll(text).isNotEmpty) return _Kind.maps;
    return _Kind.none;
  }

  Future<void> _convert() async {
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
      wire = await _convertMaps(text);
    }
    if (!mounted) return;
    if (wire == null) {
      setState(() => _failedFor = text);
      return;
    }
    widget.onReplace(wire);
  }

  Future<String?> _convertMaps(String text) async {
    final url = MapsLink.findAll(text).first;
    LatLng? position;
    String? name;
    final parsed = MapsLink.parse(url);
    if (parsed != null) {
      position = parsed.position;
      name = parsed.name;
    } else if (MapsLink.isShortLink(url)) {
      setState(() => _resolving = true);
      position = await ShortLinkResolver.instance.resolve(url);
      if (mounted) setState(() => _resolving = false);
    }
    if (position == null) return null;
    final free = text
        .replaceAll(url, '')
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final label = free.isNotEmpty ? free.first : name;
    return LocationMessage(
      position: position,
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
    final message = _resolving
        ? l10n.paste_resolving
        : failed
            ? l10n.paste_resolveFailed
            : _kind == _Kind.calendar
                ? l10n.paste_convertEvent
                : l10n.paste_convertLocation;
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
          if (_resolving)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (!failed)
            TextButton(
              onPressed: _convert,
              child: Text(l10n.paste_convert),
            ),
        ],
      ),
    );
  }
}
