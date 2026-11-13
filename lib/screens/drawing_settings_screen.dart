import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../helpers/svg_drawing.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../widgets/drawing_canvas.dart';

String _hexOf(int color) =>
    '#${(color & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Whether drawings show, and how they look on this phone. A message only
/// says what to draw, so this changes nothing anyone else sees.
class DrawingSettingsScreen extends StatefulWidget {
  const DrawingSettingsScreen({super.key});

  /// A stick figure: a circle head, a body, two legs and bent arms.
  static const previewPath =
      'M58 18a8 8 0 1 1 0-.1zM50 26v34l-14 30m14-30 14 30M26 44l12 6 12-6 12 6 12-6';

  @override
  State<DrawingSettingsScreen> createState() => _DrawingSettingsScreenState();
}

class _DrawingSettingsScreenState extends State<DrawingSettingsScreen> {
  static final _preview =
      SvgDrawing.tryParse(DrawingSettingsScreen.previewPath)!;

  // Where a slider is while it's dragged. Saved when the finger lifts: every
  // step of a drag would otherwise write the settings and repaint the drawings
  // in every open chat.
  double? _lineWidth;
  int? _glow;
  int? _scanlines;

  Future<void> _pickPenColor(AppSettingsService service) async {
    final picked = await showDialog<int>(
      context: context,
      builder: (_) =>
          _PenColorDialog(initial: service.settings.drawingPenColor),
    );
    if (picked != null) await service.setDrawingLook(penColor: picked);
  }

  Widget _slider({
    required String label,
    required String text,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return ListTile(
      title: Row(
        children: [
          Expanded(child: Text(label)),
          Text(text),
        ],
      ),
      subtitle: Slider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        label: text,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final service = context.watch<AppSettingsService>();
    final settings = service.settings;
    final lineWidth = _lineWidth ?? settings.drawingLineWidth;
    final glow = _glow ?? settings.drawingGlow;
    final scanlines = _scanlines ?? settings.drawingScanlines;
    final look = DrawingLook(
      pen: Color(settings.drawingPenColor),
      lineWidth: lineWidth,
      glow: glow,
      scanlines: scanlines,
    );
    return Scaffold(
      appBar: AppBar(
        title: AdaptiveAppBarTitle(l10n.appSettings_drawings),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            LayoutBuilder(
              builder: (context, constraints) => DrawingCanvas(
                drawing: _preview,
                look: look,
                size: Size(constraints.maxWidth, 240),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.draw_outlined),
                    title: Text(l10n.drawingSettings_show),
                    subtitle: Text(l10n.drawingSettings_showSubtitle),
                    value: settings.showDrawings,
                    onChanged: service.setShowDrawings,
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: Text(l10n.drawingSettings_penColor),
                    subtitle: Text(_hexOf(settings.drawingPenColor)),
                    trailing: _Swatch(color: settings.drawingPenColor),
                    onTap: () => _pickPenColor(service),
                  ),
                  const Divider(height: 1),
                  _slider(
                    label: l10n.drawingSettings_lineWidth,
                    text: lineWidth == lineWidth.roundToDouble()
                        ? lineWidth.toStringAsFixed(0)
                        : lineWidth.toString(),
                    value: lineWidth,
                    min: 1,
                    max: 4,
                    divisions: 12,
                    onChanged: (v) => setState(() => _lineWidth = v),
                    onChangeEnd: (v) {
                      service.setDrawingLook(lineWidth: v);
                      setState(() => _lineWidth = null);
                    },
                  ),
                  _slider(
                    label: l10n.drawingSettings_glow,
                    text: '$glow',
                    value: glow.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (v) => setState(() => _glow = v.round()),
                    onChangeEnd: (v) {
                      service.setDrawingLook(glow: v.round());
                      setState(() => _glow = null);
                    },
                  ),
                  _slider(
                    label: l10n.drawingSettings_scanlines,
                    text: '$scanlines',
                    value: scanlines.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 100,
                    onChanged: (v) => setState(() => _scanlines = v.round()),
                    onChangeEnd: (v) {
                      service.setDrawingLook(scanlines: v.round());
                      setState(() => _scanlines = null);
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextButton.icon(
                      icon: const Icon(Icons.restart_alt),
                      label: Text(l10n.common_reset),
                      onPressed: service.resetDrawingLook,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final int color;

  const _Swatch({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Color(color),
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }
}

/// The classic monitor colors at a tap, or any color by its code. Pops the
/// color as an ARGB int.
class _PenColorDialog extends StatefulWidget {
  final int initial;

  const _PenColorDialog({required this.initial});

  @override
  State<_PenColorDialog> createState() => _PenColorDialogState();
}

class _PenColorDialogState extends State<_PenColorDialog> {
  static const _presets = [0xFF33FF33, 0xFF5DF06E, 0xFFFFB000, 0xFFE8E8E8];
  static final _hex = RegExp(r'^#?([0-9a-fA-F]{6})$');

  late final _code = TextEditingController(text: _hexOf(widget.initial));

  int? get _parsed {
    final m = _hex.firstMatch(_code.text.trim());
    return m == null ? null : 0xFF000000 | int.parse(m.group(1)!, radix: 16);
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parsed = _parsed;
    return AlertDialog(
      title: Text(l10n.drawingSettings_penColor),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final preset in _presets)
                Tooltip(
                  message: _hexOf(preset),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.pop(context, preset),
                    child: _Swatch(color: preset),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _code,
            autocorrect: false,
            enableSuggestions: false,
            style: drawingCodeStyle,
            decoration: InputDecoration(
              labelText: l10n.drawingSettings_colorCode,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed:
              parsed == null ? null : () => Navigator.pop(context, parsed),
          child: Text(l10n.common_ok),
        ),
      ],
    );
  }
}
