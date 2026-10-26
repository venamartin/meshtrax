import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/structured_message.dart';
import '../l10n/l10n.dart';
import '../screens/map_screen.dart';

/// The dialogs behind the composer tray tiles. Each returns the wire text to
/// insert into the composer, or null when cancelled.
class StructuredMessageDialogs {
  static Future<LatLng?> pickPositionOnMap(BuildContext context) {
    return Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const MapScreen(pickPosition: true)),
    );
  }

  static LatLng? _radioPosition(MeshCoreConnector connector) {
    final lat = connector.selfLatitude;
    final lon = connector.selfLongitude;
    if (lat == null || lon == null || (lat == 0 && lon == 0)) return null;
    return LatLng(lat, lon);
  }

  /// "My location": the radio's position, else a pick on the map.
  static Future<String?> myLocation(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    var position = _radioPosition(connector);
    if (position == null) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.tray_noRadioPosition),
      );
      position = await pickPositionOnMap(context);
      if (position == null) return null;
    }
    return LocationMessage(position: position).toWire();
  }

  /// "Point on map": pick, then label and note.
  static Future<String?> pointOnMap(BuildContext context) async {
    final position = await pickPositionOnMap(context);
    if (position == null || !context.mounted) return null;
    final result = await showDialog<_LabelResult>(
      context: context,
      builder: (_) => const _LabelDialog(),
    );
    if (result == null) return null;
    return LocationMessage(
      position: position,
      label: result.label.isEmpty ? null : result.label,
      note: result.note.isEmpty ? null : result.note,
    ).toWire();
  }

  static Future<String?> sos(
    BuildContext context,
    MeshCoreConnector connector,
  ) {
    return showDialog<String>(
      context: context,
      builder: (_) => _SosDialog(initialPosition: _radioPosition(connector)),
    );
  }

  static Future<String?> event(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (_) => const _EventDialog(),
    );
  }

  /// [requireExpiry]: a room's notices must say when they stop applying.
  static Future<String?> notice(
    BuildContext context, {
    bool requireExpiry = false,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) => _NoticeDialog(requireExpiry: requireExpiry),
    );
  }
}

Future<DateTime?> _pickDay(
  BuildContext context, {
  required DateTime initial,
  required DateTime first,
}) {
  return showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: first,
    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
  );
}

class _LabelResult {
  final String label;
  final String note;
  const _LabelResult(this.label, this.note);
}

class _LabelDialog extends StatefulWidget {
  const _LabelDialog();

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  final _label = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _label.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.dialog_labelTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _label,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.map_label,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.dialog_note,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _LabelResult(_label.text.trim(), _note.text.trim()),
          ),
          child: Text(l10n.dialog_insert),
        ),
      ],
    );
  }
}

class _SosDialog extends StatefulWidget {
  final LatLng? initialPosition;
  const _SosDialog({this.initialPosition});

  @override
  State<_SosDialog> createState() => _SosDialogState();
}

class _SosDialogState extends State<_SosDialog> {
  final _text = TextEditingController();
  LatLng? _position;

  @override
  void initState() {
    super.initState();
    _position = widget.initialPosition;
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: scheme.error),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.dialog_sosTitle)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _text,
            autofocus: true,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.dialog_sosText,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _PositionRow(
            position: _position,
            onPick: () async {
              final picked =
                  await StructuredMessageDialogs.pickPositionOnMap(context);
              if (picked != null && mounted) setState(() => _position = picked);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: _position == null
              ? null
              : () => Navigator.pop(
                    context,
                    SosMessage(position: _position!, text: _text.text.trim())
                        .toWire(),
                  ),
          child: Text(l10n.dialog_insert),
        ),
      ],
    );
  }
}

class _NoticeDialog extends StatefulWidget {
  final bool requireExpiry;
  const _NoticeDialog({required this.requireExpiry});

  @override
  State<_NoticeDialog> createState() => _NoticeDialogState();
}

class _NoticeDialogState extends State<_NoticeDialog> {
  final _text = TextEditingController();
  DateTime? _expiryDay;

  /// Null = the end of [_expiryDay].
  TimeOfDay? _expiryTime;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  DateTime? get _expires {
    final d = _expiryDay;
    if (d == null) return null;
    final t = _expiryTime;
    return t == null
        ? DateTime(d.year, d.month, d.day + 1)
        : DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  List<String> get _lines => _text.text
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  bool get _ready {
    if (_lines.isEmpty) return false;
    final expires = _expires;
    if (expires == null) return !widget.requireExpiry;
    return expires.isAfter(DateTime.now());
  }

  Future<void> _pickExpiryDay() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await _pickDay(
      context,
      initial: _expiryDay ?? today,
      first: today,
    );
    if (picked != null) setState(() => _expiryDay = picked);
  }

  Future<void> _pickExpiryTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _expiryTime ?? const TimeOfDay(hour: 18, minute: 0),
    );
    if (picked != null) setState(() => _expiryTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final day = _expiryDay;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.campaign, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.dialog_noticeTitle)),
        ],
      ),
      content: SingleChildScrollView(
        // Room for the field's floating label.
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _text,
              autofocus: true,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.dialog_noticeText,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_busy),
              title: Text(l10n.dialog_noticeExpires),
              subtitle: Text(
                day != null
                    ? DateFormat.yMMMEd(locale).format(day)
                    : widget.requireExpiry
                        ? l10n.dialog_noticeExpiryRequired
                        : l10n.dialog_noticeNoExpiry,
              ),
              trailing: day == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() {
                        _expiryDay = null;
                        _expiryTime = null;
                      }),
                    ),
              onTap: _pickExpiryDay,
            ),
            if (day != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(l10n.dialog_noticeExpiryTime),
                subtitle: Text(
                  _expiryTime?.format(context) ?? l10n.dialog_noticeEndOfDay,
                ),
                trailing: _expiryTime == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _expiryTime = null),
                      ),
                onTap: _pickExpiryTime,
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: !_ready
              ? null
              : () => Navigator.pop(
                    context,
                    NoticeMessage(lines: _lines, expires: _expires).toWire(),
                  ),
          child: Text(l10n.dialog_insert),
        ),
      ],
    );
  }
}

class _EventDialog extends StatefulWidget {
  const _EventDialog();

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _title = TextEditingController();
  final _place = TextEditingController();
  DateTime _date = DateTime.now();

  /// Last day of a multi-day event; null = same day as [_date].
  DateTime? _endDate;
  bool _allDay = false;
  TimeOfDay _start = const TimeOfDay(hour: 18, minute: 0);
  TimeOfDay? _end;
  LatLng? _position;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
  }

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await _pickDay(
      context,
      initial: _date,
      first: DateTime.now().subtract(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _date = picked;
      if (_endDate != null && !_endDate!.isAfter(picked)) _endDate = null;
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await _pickDay(
      context,
      initial: _endDate ?? DateTime(_date.year, _date.month, _date.day + 1),
      first: _date,
    );
    if (picked == null) return;
    setState(() {
      _endDate = picked.isAfter(_date) ? picked : null;
      // A timed event that ends on another day needs an end time.
      if (_endDate != null) _end ??= _start;
    });
  }

  Future<void> _pickStart() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEnd() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _end ?? _start.replacing(hour: (_start.hour + 1) % 24),
    );
    if (picked != null) setState(() => _end = picked);
  }

  String _wire() {
    final start = _allDay
        ? _date
        : DateTime(_date.year, _date.month, _date.day, _start.hour, _start.minute);
    final endDay = _endDate ?? _date;
    DateTime? end;
    if (_allDay) {
      end = _endDate;
    } else if (_end != null) {
      end = DateTime(endDay.year, endDay.month, endDay.day, _end!.hour, _end!.minute);
      if (!end.isAfter(start)) end = end.add(const Duration(days: 1));
    }
    return EventMessage(
      title: _title.text.trim(),
      when: EventWhen(start: start, end: end, allDay: _allDay),
      place: _place.text.trim().isEmpty ? null : _place.text.trim(),
      position: _position,
    ).toWire();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.event),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.structured_event)),
        ],
      ),
      content: SingleChildScrollView(
        // Room for the title field's floating label, which was clipped.
        padding: const EdgeInsets.only(top: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _title,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.dialog_eventTitle,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(l10n.dialog_eventDate),
              subtitle: Text(DateFormat.yMMMEd(locale).format(_date)),
              onTap: _pickDate,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.date_range),
              title: Text(l10n.dialog_eventEndDate),
              subtitle: Text(_endDate == null
                  ? l10n.dialog_eventSameDay
                  : DateFormat.yMMMEd(locale).format(_endDate!)),
              trailing: _endDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endDate = null),
                    ),
              onTap: _pickEndDate,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.structured_allDay),
              value: _allDay,
              onChanged: (v) => setState(() {
                _allDay = v;
                if (!v && _endDate != null) _end ??= _start;
              }),
            ),
            if (!_allDay) ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule),
                title: Text(l10n.dialog_eventStart),
                subtitle: Text(_start.format(context)),
                onTap: _pickStart,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_outlined),
                title: Text(l10n.dialog_eventEnd),
                subtitle: Text(_end?.format(context) ?? l10n.dialog_eventNoEnd),
                trailing: _end == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        // No end time means it ends the day it starts.
                        onPressed: () => setState(() {
                          _end = null;
                          _endDate = null;
                        }),
                      ),
                onTap: _pickEnd,
              ),
            ],
            const SizedBox(height: 8),
            TextField(
              controller: _place,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.dialog_eventPlace,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            _PositionRow(
              position: _position,
              onPick: () async {
                final picked =
                    await StructuredMessageDialogs.pickPositionOnMap(context);
                if (picked != null && mounted) {
                  setState(() => _position = picked);
                }
              },
              onClear: _position == null
                  ? null
                  : () => setState(() => _position = null),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _title.text.trim().isEmpty
              ? null
              : () => Navigator.pop(context, _wire()),
          child: Text(l10n.dialog_insert),
        ),
      ],
    );
  }
}

class _PositionRow extends StatelessWidget {
  final LatLng? position;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _PositionRow({required this.position, required this.onPick, this.onClear});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Row(
      children: [
        Icon(
          position == null ? Icons.location_off : Icons.location_on,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            position == null
                ? l10n.dialog_pickOnMap
                : StructuredMessage.formatCoordinates(position!),
            style: const TextStyle(fontSize: 13),
          ),
        ),
        if (onClear != null)
          IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: onClear),
        TextButton(
          onPressed: onPick,
          child: Text(position == null ? l10n.dialog_pickOnMap : l10n.common_edit),
        ),
      ],
    );
  }
}
