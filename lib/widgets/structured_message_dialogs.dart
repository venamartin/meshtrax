import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/date_time_helper.dart';
import '../helpers/maps_link.dart';
import '../helpers/snack_bar_builder.dart';
import '../helpers/structured_message.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../screens/map_screen.dart';
import '../services/app_settings_service.dart';
import '../services/sos_service.dart';
import 'drawing_canvas.dart';
import 'drawing_map_view.dart';

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
        builder: (_) => MapScreen(pickPosition: true, pickAround: around),
      ),
    );
  }

  static LatLng? _radioPosition(MeshCoreConnector connector) {
    final lat = connector.selfLatitude;
    final lon = connector.selfLongitude;
    if (lat == null || lon == null || (lat == 0 && lon == 0)) return null;
    return LatLng(lat, lon);
  }

  /// Under the radio's position when it may be old: the dialog still takes
  /// it, but says so.
  static String? _mayBeOld(BuildContext context, MeshCoreConnector connector) {
    if (!connector.selfPositionMayBeOld) return null;
    final at = connector.selfGpsChangedAt;
    return at == null
        ? context.l10n.gps_lastKnown
        : context.l10n.gps_lastKnownAt(DateTimeHelper.time(context, at));
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
    final note = _mayBeOld(context, connector);
    final message = await showDialog<LocationMessage>(
      context: context,
      builder: (_) => _LocationDialog(
        mine: true,
        initialPosition: _radioPosition(connector),
        initialNote: note,
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
    String? title,
    String? action,
  }) {
    return showDialog<LocationMessage>(
      context: context,
      builder: (_) => _LocationDialog(
        mine: false,
        initialPosition: position,
        initialTitle: title,
        action: action,
      ),
    );
  }

  /// SOS in a direct message or a room: the wire text to insert, sent once
  /// like any message there.
  static Future<String?> sos(
    BuildContext context,
    MeshCoreConnector connector,
  ) async {
    final request = await showDialog<SosRequest>(
      context: context,
      builder: (_) => _SosDialog(connector: connector),
    );
    return request?.message.toWire();
  }

  /// SOS in a channel, sent from the dialog and repeated until cancelled;
  /// with [repeats] off (Public), sent once.
  /// [offerPublic]: the radio has Public and this chat is another one.
  /// [replaces]: the chat the user's SOS is active in now, which this one
  /// cancels.
  static Future<SosRequest?> sosInChannel(
    BuildContext context,
    MeshCoreConnector connector, {
    required bool offerPublic,
    String? replaces,
    bool repeats = true,
    bool traxOnly = false,
  }) {
    return showDialog<SosRequest>(
      context: context,
      builder: (_) => _SosDialog(
        connector: connector,
        inChannel: true,
        offerPublic: offerPublic,
        replaces: replaces,
        repeats: repeats,
        traxOnly: traxOnly,
      ),
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

  /// A drawing from a message, larger, with its code to read and copy.
  static Future<void> drawingViewer(BuildContext context, SvgMessage message) {
    return showDialog<void>(
      context: context,
      builder: (_) => _DrawingViewer(message: message),
    );
  }
}

class _DrawingViewer extends StatelessWidget {
  final SvgMessage message;

  const _DrawingViewer({required this.message});

  /// The drawing as an SVG file that opens in a browser looking as it does
  /// here: lines, not the black fill SVG gives a bare path.
  static String svgFile(SvgMessage message, Color pen) {
    var minX = double.infinity, minY = double.infinity;
    var maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final line in message.drawing.polylines() ?? const []) {
      for (final p in line) {
        minX = math.min(minX, p.x);
        maxX = math.max(maxX, p.x);
        minY = math.min(minY, p.y);
        maxY = math.max(maxY, p.y);
      }
    }
    String n(double v) {
      final r = (v * 10).round() / 10;
      return r == r.roundToDouble() ? r.round().toString() : r.toString();
    }

    // Over a map the numbers are places on its frame: keep the frame.
    final viewBox = message.drawing.map != null
        ? '0 0 100 75'
        : '${n(minX - 3)} ${n(minY - 3)} '
            '${n(maxX - minX + 6)} ${n(maxY - minY + 6)}';
    final hex = (pen.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$viewBox">'
        '<path d="${message.drawing.pathData}" fill="none" stroke="#$hex" '
        'stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>'
        '</svg>';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final look = context.select<AppSettingsService, DrawingLook>(
      (s) => DrawingLook.of(s.settings),
    );
    // An explicit size: an AlertDialog asks its content for an intrinsic
    // width, which a LayoutBuilder can't answer.
    final width = math.min(MediaQuery.sizeOf(context).width - 80, 480.0);
    final drawing = message.drawing;
    final caption = drawing.caption;
    return _trayDialog(
      context,
      icon: Icons.draw,
      title: l10n.tray_drawing,
      children: [
        if (drawing.map != null && DrawingMapView.available(context))
          SizedBox(
            width: width,
            child: DrawingMapView(drawing: drawing, look: look, width: width),
          )
        else
          DrawingCanvas(
            drawing: drawing,
            look: look,
            size: Size(width, width * 0.75),
          ),
        if (caption.isNotEmpty) ...[_gap, Text(caption)],
        _gap,
        SelectableText(
          [drawing.pathData, ?drawing.map?.toLine()].join('\n'),
          style: drawingCodeStyle.copyWith(fontSize: 13),
        ),
      ],
      actions: [
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: svgFile(message, look.pen)));
            showDismissibleSnackBar(
              context,
              content: Text(l10n.common_copiedToClipboard),
            );
            Navigator.pop(context);
          },
          child: Text(l10n.drawing_copySvg),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_close),
        ),
      ],
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
    errorMaxLines: 3,
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

  /// Under [initialPosition] while the field holds it.
  final String? initialNote;
  final String? initialTitle;
  final String? action;

  const _LocationDialog({
    required this.mine,
    this.initialPosition,
    this.initialNote,
    this.initialTitle,
    this.action,
  });

  @override
  State<_LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<_LocationDialog> {
  late final _label = TextEditingController(text: widget.initialTitle);
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
          initialHelper: widget.initialNote,
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

  /// Under the field while it holds [initial].
  final String? initialHelper;

  const _PositionField({
    super.key,
    required this.initial,
    required this.onChanged,
    this.autofocus = false,
    this.emptyHelper,
    this.initialHelper,
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _report(LatLng? position, {bool unreadable = false}) {
    setState(() {
      _position = position;
      _unreadable = unreadable;
    });
    widget.onChanged(position, !unreadable);
  }

  void _onText(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return _report(null);
    final position = StructuredMessageDialogs.readPosition(text);
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
    if (sent != null && sent != text) {
      helper = sent;
    } else if (text.isEmpty) {
      helper = widget.emptyHelper;
    } else if (position != null && position == widget.initial) {
      helper = widget.initialHelper;
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
        error: !_unreadable
            ? null
            : MapsLink.isShortLink(text)
            ? l10n.paste_shortLinkNoPosition
            : l10n.dialog_positionUnreadable,
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

/// [inChannel]: sent from here, and repeated unless [repeats] is off
/// (Public), with the Public copy on offer; otherwise inserted into the
/// composer. [traxOnly]: the radio is in TRAX mode, so only the radios
/// there hear it.
class _SosDialog extends StatefulWidget {
  final MeshCoreConnector connector;
  final bool inChannel;
  final bool offerPublic;
  final String? replaces;
  final bool repeats;
  final bool traxOnly;

  const _SosDialog({
    required this.connector,
    this.inChannel = false,
    this.offerPublic = false,
    this.replaces,
    this.repeats = true,
    this.traxOnly = false,
  });

  @override
  State<_SosDialog> createState() => _SosDialogState();
}

class _SosDialogState extends State<_SosDialog> {
  /// How long the dialog waits for the radio's answer before it says it
  /// gave none. Sending never waits for it.
  static const _askFor = Duration(seconds: 5);

  final _text = TextEditingController();
  final _opened = DateTime.now();
  late LatLng? _position = StructuredMessageDialogs._radioPosition(
    widget.connector,
  );
  late final bool _radioHadPosition = _position != null;

  /// The position was typed, picked or cleared by hand.
  bool _edited = false;
  bool _asking = false;

  /// When the radio answered while the dialog was open.
  DateTime? _readAt;

  /// A new key for the position field when the radio's answer refills it.
  int _filled = 0;
  bool _alsoPublic = true;
  bool _viewing = false;
  Timer? _giveUp;

  @override
  void initState() {
    super.initState();
    final radio = widget.connector;
    if (!radio.canAskSelfPosition) return;
    _asking = true;
    radio.selfGps.addListener(_onReading);
    radio.addSelfPositionViewer();
    _viewing = true;
    _giveUp = Timer(_askFor, () {
      if (mounted) setState(() => _asking = false);
    });
  }

  @override
  void dispose() {
    _giveUp?.cancel();
    widget.connector.selfGps.removeListener(_onReading);
    if (_viewing) widget.connector.removeSelfPositionViewer();
    _text.dispose();
    super.dispose();
  }

  void _onReading() {
    final reading = widget.connector.selfGps.value;
    if (reading == null ||
        reading.at.isBefore(_opened) ||
        !widget.connector.hasValidLocation(
          reading.latitude,
          reading.longitude,
        )) {
      return;
    }
    _giveUp?.cancel();
    setState(() {
      _asking = false;
      _readAt = reading.at;
      if (_edited) return;
      final radio = StructuredMessageDialogs._radioPosition(widget.connector);
      if (radio != null && radio != _position) {
        _position = radio;
        _filled++;
      }
    });
  }

  String _age(AppLocalizations l10n, DateTime at) {
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return l10n.time_justNow;
    if (d.inHours < 1) return l10n.time_minutesAgo(d.inMinutes);
    if (d.inDays < 1) return l10n.time_hoursAgo(d.inHours);
    return l10n.time_daysAgo(d.inDays);
  }

  /// Where the position came from and how old it is, as far as the radio
  /// says: never more.
  Widget? _source(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    Widget line(IconData? icon, String text, {Color? color}) => Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon == null)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(icon, size: 16, color: color ?? scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: color ?? scheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        );
    if (_edited) {
      return _position != null && _radioHadPosition
          ? line(Icons.edit_location_alt_outlined, l10n.sos_positionTyped)
          : null;
    }
    if (_asking) return line(null, l10n.sos_askingRadio);
    if (_position == null) return null;
    // A radio that lost its fix still answers, with its last position: as
    // old as the GPS's last change, not the reading.
    final old = StructuredMessageDialogs._mayBeOld(context, widget.connector);
    if (old != null) return line(Icons.history, old, color: scheme.error);
    final read = _readAt;
    if (read != null) {
      return line(
        Icons.gps_fixed,
        l10n.sos_positionFrom(
          DateTimeHelper.time(context, read),
          _age(l10n, read),
        ),
      );
    }
    final last = widget.connector.selfGps.value;
    final warn = scheme.error;
    if (last != null &&
        widget.connector.hasValidLocation(last.latitude, last.longitude)) {
      return line(
        Icons.history,
        l10n.sos_positionNotNew(
          DateTimeHelper.time(context, last.at),
          _age(l10n, last.at),
        ),
        color: warn,
      );
    }
    return line(Icons.history, l10n.sos_positionAgeUnknown, color: warn);
  }

  SosRequest _request() => SosRequest(
        message: SosMessage(position: _position!, text: _text.text.trim()),
        alsoPublic: widget.offerPublic && _alsoPublic,
        followRadio: !(_edited && _radioHadPosition),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final muted = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: scheme.onSurfaceVariant,
        );
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
          key: ValueKey(_filled),
          initial: _position,
          emptyHelper: _asking ? null : l10n.tray_noRadioPosition,
          onChanged: (position, _) => setState(() {
            _position = position;
            _edited = true;
          }),
        ),
        ?_source(context),
        if (widget.offerPublic)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            controlAffinity: ListTileControlAffinity.leading,
            value: _alsoPublic,
            onChanged: (v) => setState(() => _alsoPublic = v ?? false),
            title: Text(l10n.sos_alsoPublic),
            subtitle: Text(l10n.sos_alsoPublicHint),
          ),
        if (widget.inChannel) ...[
          const SizedBox(height: 6),
          Text(
            widget.repeats ? l10n.sos_repeats : l10n.sos_publicOnce,
            style: muted,
          ),
          if (widget.traxOnly) ...[
            const SizedBox(height: 6),
            Text(
              l10n.sos_traxOnly,
              style: muted?.copyWith(color: scheme.error),
            ),
          ],
          if (widget.replaces case final chat?) ...[
            const SizedBox(height: 6),
            Text(
              l10n.sos_replacesOther(chat),
              style: muted?.copyWith(color: scheme.error),
            ),
          ],
        ],
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
              : () => Navigator.pop(context, _request()),
          child: Text(
            widget.inChannel ? l10n.dialog_sosTitle : l10n.dialog_insert,
          ),
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
    final locale = DateTimeHelper.localeOf(context);
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
    final locale = DateTimeHelper.localeOf(context);
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
