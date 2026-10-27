import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/maps_link.dart';
import '../helpers/structured_message.dart';
import '../l10n/l10n.dart';
import '../screens/map_screen.dart';
import '../services/short_link_resolver.dart';

/// The dialogs behind the composer tray tiles. Each returns the wire text to
/// insert into the composer, or null when cancelled.
class StructuredMessageDialogs {
  /// [around]: the position to start from, pinned on the map.
  static Future<LatLng?> pickPositionOnMap(
    BuildContext context, {
    LatLng? around,
  }) {
    return Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MapScreen(pickPosition: true, highlightPosition: around),
      ),
    );
  }

  static LatLng? _radioPosition(MeshCoreConnector connector) {
    final lat = connector.selfLatitude;
    final lon = connector.selfLongitude;
    if (lat == null || lon == null || (lat == 0 && lon == 0)) return null;
    return LatLng(lat, lon);
  }

  /// A position as people paste it: `lat, lon` with any number of
  /// decimals, a maps link that carries coordinates, or a geo: URI.
  static LatLng? readPosition(String text) {
    final pair = _pair.firstMatch(text.trim());
    if (pair == null) return MapsLink.parse(text)?.position;
    final lat = double.parse(pair.group(1)!);
    final lon = double.parse(pair.group(2)!);
    // 0,0 is how a radio says it has no position.
    if (lat.abs() > 90 || lon.abs() > 180 || (lat == 0 && lon == 0)) {
      return null;
    }
    return LatLng(lat, lon);
  }

  static final _pair = RegExp(
    r'^(-?\d{1,2}(?:\.\d+)?)\s*[,\s]\s*(-?\d{1,3}(?:\.\d+)?)$',
  );

  /// "My location": the radio's position, which can be corrected, and a
  /// note. Titled "My location" on the air, so readers know whose it is.
  static Future<String?> myLocation(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final message = await showDialog<LocationMessage>(
      context: context,
      builder: (_) => _LocationDialog(
        mine: true,
        initialPosition: _radioPosition(connector),
      ),
    );
    return message?.toWire();
  }

  /// "Point on map": a position pasted or picked, a title and a note.
  static Future<String?> pointOnMap(BuildContext context) async =>
      (await location(context))?.toWire();

  /// A place to share, [position] filled in when there is one (the map's
  /// "Share marker here"). [action] names the button that finishes it.
  static Future<LocationMessage?> location(
    BuildContext context, {
    LatLng? position,
    String? action,
  }) {
    return showDialog<LocationMessage>(
      context: context,
      builder: (_) => _LocationDialog(
        mine: false,
        initialPosition: position,
        action: action,
      ),
    );
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

  /// [initial]: an event to edit, filled in.
  static Future<String?> event(BuildContext context, {EventMessage? initial}) {
    return showDialog<String>(
      context: context,
      builder: (_) => _EventDialog(initial: initial),
    );
  }

  /// [requireExpiry]: a room's notices must say when they stop applying.
  /// [initial]: a notice to edit, filled in.
  static Future<String?> notice(
    BuildContext context, {
    bool requireExpiry = false,
    NoticeMessage? initial,
  }) {
    return showDialog<String>(
      context: context,
      builder: (_) =>
          _NoticeDialog(requireExpiry: requireExpiry, initial: initial),
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

/// The tray dialogs, tighter than stock so more of each fits above the
/// keyboard (owner, 2026-10-27): smaller margins, dense fields and rows.
AlertDialog _trayDialog(
  BuildContext context, {
  required IconData icon,
  Color? iconColor,
  required String title,
  required List<Widget> children,
  required List<Widget> actions,
}) {
  return AlertDialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
    contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
    actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
    titleTextStyle: Theme.of(context).textTheme.titleLarge,
    title: Row(
      children: [
        Icon(icon, color: iconColor),
        const SizedBox(width: 8),
        Expanded(child: Text(title)),
      ],
    ),
    content: SingleChildScrollView(
      // Room for the first field's floating label, which was clipped.
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
    actions: actions,
  );
}

InputDecoration _field(
  String label, {
  String? hint,
  String? helper,
  String? error,
  Widget? suffix,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    helperText: helper,
    helperMaxLines: 2,
    errorText: error,
    isDense: true,
    border: const OutlineInputBorder(),
    suffixIcon: suffix,
  );
}

const _gap = SizedBox(height: 10);
const _rowDensity = VisualDensity(vertical: -3);

/// The Location dialog behind "My location", "Point on map" and the map's
/// "Share marker here": where, an optional title and an optional note.
/// [mine]: the radio's own position, titled "My location" on the air, so
/// it has no title field.
class _LocationDialog extends StatefulWidget {
  final bool mine;
  final LatLng? initialPosition;
  final String? action;

  const _LocationDialog({
    required this.mine,
    this.initialPosition,
    this.action,
  });

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  final _label = TextEditingController();
  final _note = TextEditingController();
  late LatLng? _position = widget.initialPosition;

  @override
  void dispose() {
    _label.dispose();
    _note.dispose();
    super.dispose();
  }

  LocationMessage _message() {
    final label = widget.mine
        ? LocationMessage.myLocationLabel
        : _label.text.trim();
    final note = _note.text.trim();
    // Without a title, readers take the first text for one, so a lone
    // note goes out as the title.
    return LocationMessage(
      position: _position!,
      label: label.isNotEmpty ? label : (note.isEmpty ? null : note),
      note: label.isNotEmpty && note.isNotEmpty ? note : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _trayDialog(
      context,
      icon: widget.mine ? Icons.my_location : Icons.place,
      iconColor: Theme.of(context).colorScheme.primary,
      title: widget.mine ? l10n.tray_myLocation : l10n.chat_location,
      children: [
        _PositionField(
          initial: widget.initialPosition,
          // Pasting a position is what this dialog is for.
          autofocus: !widget.mine && widget.initialPosition == null,
          emptyHelper: widget.mine ? l10n.tray_noRadioPosition : null,
          onChanged: (position, _) => setState(() => _position = position),
        ),
        if (!widget.mine) ...[
          _gap,
          TextField(
            controller: _label,
            textCapitalization: TextCapitalization.sentences,
            decoration: _field(l10n.map_label),
          ),
        ],
        _gap,
        TextField(
          controller: _note,
          textCapitalization: TextCapitalization.sentences,
          decoration: _field(l10n.dialog_note),
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _position == null
              ? null
              : () => Navigator.pop(context, _message()),
          child: Text(widget.action ?? l10n.dialog_insert),
        ),
      ],
    );
  }
}

/// A position typed or pasted as `lat, lon`, a maps link or a geo: URI,
/// or picked on the map with the button at its end. [onChanged] gets the
/// position, or null, and whether the field is settled: empty or read.
class _PositionField extends StatefulWidget {
  final LatLng? initial;
  final void Function(LatLng? position, bool settled) onChanged;
  final bool autofocus;

  /// Under the field while it is empty.
  final String? emptyHelper;

  const _PositionField({
    required this.initial,
    required this.onChanged,
    this.autofocus = false,
    this.emptyHelper,
  });

  @override
  State<_PositionField> createState() => _PositionFieldState();
}

class _PositionFieldState extends State<_PositionField> {
  late final _controller = TextEditingController(
    text: widget.initial == null
        ? ''
        : StructuredMessage.formatCoordinates(widget.initial!),
  );
  late LatLng? _position = widget.initial;
  bool _unreadable = false;
  bool _lookingUp = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _report(LatLng? position, {bool unreadable = false, bool lookingUp = false}) {
    setState(() {
      _position = position;
      _unreadable = unreadable;
      _lookingUp = lookingUp;
    });
    widget.onChanged(position, !unreadable && !lookingUp);
  }

  void _onText(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return _report(null);
    final position = StructuredMessageDialogs.readPosition(text);
    if (position != null) return _report(position);
    if (MapsLink.isShortLink(text)) {
      _lookUp(text);
      return;
    }
    _report(null, unreadable: true);
  }

  /// A Google short link carries no coordinates: ask where it leads.
  Future<void> _lookUp(String url) async {
    _report(null, lookingUp: true);
    final position = await ShortLinkResolver.instance.resolve(url);
    if (!mounted || _controller.text.trim() != url) return;
    _report(position, unreadable: position == null);
  }

  Future<void> _pick() async {
    final picked = await StructuredMessageDialogs.pickPositionOnMap(
      context,
      around: _position,
    );
    if (picked == null || !mounted) return;
    _controller.text = StructuredMessage.formatCoordinates(picked);
    _report(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = _controller.text.trim();
    final position = _position;
    // A link or a short pair: show the coordinates that will be sent.
    final sent = position == null
        ? null
        : StructuredMessage.formatCoordinates(position);
    final String? helper;
    if (_lookingUp) {
      helper = l10n.dialog_positionLookingUp;
    } else if (sent != null && sent != text) {
      helper = sent;
    } else if (text.isEmpty) {
      helper = widget.emptyHelper;
    } else {
      helper = null;
    }
    return TextField(
      controller: _controller,
      autofocus: widget.autofocus,
      autocorrect: false,
      enableSuggestions: false,
      decoration: _field(
        l10n.gps_position,
        hint: l10n.dialog_positionHint,
        helper: helper,
        error: _unreadable ? l10n.dialog_positionUnreadable : null,
        suffix: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear),
                tooltip: l10n.common_clear,
                onPressed: () {
                  _controller.clear();
                  _report(null);
                },
              ),
            IconButton(
              icon: const Icon(Icons.map_outlined),
              tooltip: l10n.dialog_pickOnMap,
              onPressed: _pick,
            ),
          ],
        ),
      ),
      onChanged: _onText,
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
  late LatLng? _position = widget.initialPosition;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return _trayDialog(
      context,
      icon: Icons.warning_rounded,
      iconColor: scheme.error,
      title: l10n.dialog_sosTitle,
      children: [
        TextField(
          controller: _text,
          autofocus: true,
          maxLines: 2,
          textCapitalization: TextCapitalization.sentences,
          decoration: _field(l10n.dialog_sosText),
          onChanged: (_) => setState(() {}),
        ),
        _gap,
        _PositionField(
          initial: widget.initialPosition,
          emptyHelper: l10n.tray_noRadioPosition,
          onChanged: (position, _) => setState(() => _position = position),
        ),
      ],
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
  final NoticeMessage? initial;
  const _NoticeDialog({required this.requireExpiry, this.initial});

  @override
  State<_NoticeDialog> createState() => _NoticeDialogState();
}

class _NoticeDialogState extends State<_NoticeDialog> {
  final _text = TextEditingController();
  DateTime? _expiryDay;

  /// Null = the end of [_expiryDay].
  TimeOfDay? _expiryTime;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;
    _text.text = initial.lines.join('\n');
    if (initial.expires != null) {
      _expiryDay = DateUtils.dateOnly(initial.expiryDay);
      if (!initial.expiresAtDayEnd) {
        _expiryTime = TimeOfDay.fromDateTime(initial.expires!);
      }
    }
  }

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
    return _trayDialog(
      context,
      icon: Icons.campaign,
      iconColor: Theme.of(context).colorScheme.primary,
      title: l10n.dialog_noticeTitle,
      children: [
        TextField(
          controller: _text,
          autofocus: true,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: _field(l10n.dialog_noticeText),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        ListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: _rowDensity,
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
            dense: true,
            visualDensity: _rowDensity,
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
  final EventMessage? initial;
  const _EventDialog({this.initial});

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

  /// The position field is empty or read; not while it holds text that is
  /// no position.
  bool _positionSettled = true;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day);
    final initial = widget.initial;
    if (initial == null) return;
    final when = initial.when;
    _title.text = initial.title;
    _place.text = initial.place ?? '';
    _position = initial.position;
    _date = DateUtils.dateOnly(when.start);
    _allDay = when.allDay;
    final end = when.end;
    if (when.allDay) {
      if (end != null && DateUtils.dateOnly(end).isAfter(_date)) {
        _endDate = DateUtils.dateOnly(end);
      }
      return;
    }
    _start = TimeOfDay.fromDateTime(when.start);
    if (end == null) return;
    _end = TimeOfDay.fromDateTime(end);
    // Overnight but under a day is still "same day": the end rolls over
    // midnight on its own.
    if (end.difference(when.start) >= const Duration(days: 1)) {
      _endDate = DateUtils.dateOnly(end);
    }
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

  ListTile _row({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: _rowDensity,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onClear == null
          ? null
          : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    return _trayDialog(
      context,
      icon: Icons.event,
      title: l10n.structured_event,
      children: [
        TextField(
          controller: _title,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: _field(l10n.dialog_eventTitle),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        _row(
          icon: Icons.calendar_today,
          title: l10n.dialog_eventDate,
          subtitle: DateFormat.yMMMEd(locale).format(_date),
          onTap: _pickDate,
        ),
        _row(
          icon: Icons.date_range,
          title: l10n.dialog_eventEndDate,
          subtitle: _endDate == null
              ? l10n.dialog_eventSameDay
              : DateFormat.yMMMEd(locale).format(_endDate!),
          onTap: _pickEndDate,
          onClear: _endDate == null
              ? null
              : () => setState(() => _endDate = null),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          visualDensity: _rowDensity,
          title: Text(l10n.structured_allDay),
          value: _allDay,
          onChanged: (v) => setState(() {
            _allDay = v;
            if (!v && _endDate != null) _end ??= _start;
          }),
        ),
        if (!_allDay) ...[
          _row(
            icon: Icons.schedule,
            title: l10n.dialog_eventStart,
            subtitle: _start.format(context),
            onTap: _pickStart,
          ),
          _row(
            icon: Icons.schedule_outlined,
            title: l10n.dialog_eventEnd,
            subtitle: _end?.format(context) ?? l10n.dialog_eventNoEnd,
            onTap: _pickEnd,
            // No end time means it ends the day it starts.
            onClear: _end == null
                ? null
                : () => setState(() {
                      _end = null;
                      _endDate = null;
                    }),
          ),
        ],
        const SizedBox(height: 4),
        TextField(
          controller: _place,
          textCapitalization: TextCapitalization.sentences,
          decoration: _field(l10n.dialog_eventPlace),
        ),
        _gap,
        _PositionField(
          initial: _position,
          onChanged: (position, settled) => setState(() {
            _position = position;
            _positionSettled = settled;
          }),
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: _title.text.trim().isEmpty || !_positionSettled
              ? null
              : () => Navigator.pop(context, _wire()),
          child: Text(l10n.dialog_insert),
        ),
      ],
    );
  }
}
