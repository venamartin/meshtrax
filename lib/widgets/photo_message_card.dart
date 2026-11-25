import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:traxpix/traxpix.dart' show PhotoPosition;

import '../helpers/link_handler.dart';
import '../helpers/navigate_helper.dart';
import '../helpers/position_text.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../services/photo_mesh.dart';
import '../services/photo_save.dart';
import '../services/photo_store.dart';
import 'photo_ai_mark.dart';
import 'photo_footprint_mark.dart';
import 'photo_report_dialog.dart';

/// The sender's tag, drawn as text by this app, never by the AI.
class PhotoTagLabel extends StatelessWidget {
  final String tag;
  final bool onDark;

  const PhotoTagLabel(this.tag, {super.key, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = onDark ? Colors.white : scheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.black.withValues(alpha: 0.45)
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sell_outlined, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              tag,
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

/// A position's accuracy, by its size in bytes, as the send screen offers it.
String photoPositionDistance(AppLocalizations l10n, int bytes) =>
    switch (bytes) {
      3 => l10n.photo_distance10km,
      4 => l10n.photo_distance600m,
      5 => l10n.photo_distance40m,
      _ => l10n.photo_distance2m,
    };

/// Where the sender sent a photo from, in the reader's coordinate format and
/// to the accuracy the sender chose, with Map and Navigate as on a location
/// card.
class PhotoPositionRow extends StatelessWidget {
  final PhotoPosition position;
  final String label;

  const PhotoPositionRow(this.position, {super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final format = coordFormatOf(context.watch<AppSettingsService>().settings);
    final at = LatLng(position.lat, position.lon);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Icon(
          Icons.place_outlined,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        Text(
          l10n.photo_positionAt(
            positionLines(position.lat, position.lon, format).first,
            photoPositionDistance(l10n, position.bytes),
          ),
          style: theme.textTheme.bodySmall,
        ),
        TextButton.icon(
          onPressed: () => LinkHandler.openMapAt(context, at, label: label),
          icon: const Icon(Icons.map_outlined, size: 18),
          label: Text(l10n.structured_map),
        ),
        TextButton.icon(
          onPressed: () => NavigateHelper.navigate(context, at, label: label),
          icon: const Icon(Icons.near_me_outlined, size: 18),
          label: Text(l10n.structured_navigate),
        ),
      ],
    );
  }
}

/// A photo in a chat: a square, the rebuilt picture once there is one. A
/// tap opens it full screen, rebuilding it there first if need be.
class PhotoMessageCard extends StatelessWidget {
  final String messageId;
  final String senderName;
  final DateTime photoTime;
  final double size;

  const PhotoMessageCard({
    super.key,
    required this.messageId,
    required this.senderName,
    required this.photoTime,
    this.size = 240,
  });

  Future<void> _block(BuildContext context) async {
    await context.read<AppSettingsService>().blockSender(senderName);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.photo_blockedSender(senderName))),
      );
    }
  }

  /// A notice in place of a photo that can't be shown, ever.
  Widget _notice(
    BuildContext context,
    IconData icon,
    String text, {
    List<Widget> actions = const [],
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: scheme.onErrorContainer),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
          if (actions.isNotEmpty) Wrap(spacing: 8, children: actions),
        ],
      ),
    );
  }

  Widget _body(BuildContext context, PhotoRecord record) {
    final store = PhotoStore.instance;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    if (record.reported) {
      return _notice(
        context,
        Icons.flag_outlined,
        context.l10n.photo_hiddenReported,
      );
    }
    if (record.flagged == true) {
      return _notice(
        context,
        Icons.hide_image_outlined,
        context.l10n.photo_hiddenFlagged,
        actions: record.outgoing
            ? const []
            : [
                TextButton(
                  onPressed: () => reportPhoto(
                    context,
                    messageId: messageId,
                    sender: senderName,
                    photoTime: photoTime,
                  ),
                  child: Text(context.l10n.photo_report),
                ),
                TextButton(
                  onPressed: () => _block(context),
                  child: Text(context.l10n.photo_block(senderName)),
                ),
              ],
      );
    }
    final image = store.imageFor(messageId);
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PhotoViewerScreen(
            messageId: messageId,
            bytes: record.bytes,
            tag: record.tag,
            senderName: record.outgoing ? null : senderName,
            photoTime: photoTime,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox.square(
          dimension: size,
          child: image != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(image, fit: BoxFit.cover, gaplessPlayback: true),
                    const Positioned(left: 8, bottom: 6, child: PhotoAiMark()),
                    const PhotoFootprintMark(),
                  ],
                )
              : ColoredBox(
                  color: scheme.surfaceContainerHigh,
                  child: Center(
                    child: store.isRebuilding(messageId)
                        ? const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_outlined,
                                size: 40,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                context.l10n.photo_tapToView,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = PhotoStore.instance;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final record = store.recordFor(messageId);
        if (record == null) return Text(context.l10n.photo_chatPhoto);
        final body = _body(context, record);
        final tag = record.tag;
        final position = record.position;
        if (tag == null && position == null) return body;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            body,
            if (tag != null) ...[const SizedBox(height: 6), PhotoTagLabel(tag)],
            if (position != null) ...[
              const SizedBox(height: 4),
              PhotoPositionRow(position, label: tag ?? senderName),
            ],
          ],
        );
      },
    );
  }
}

enum _ViewerAction { details, report, block }

/// A photo full screen: pinch or double-tap to zoom, Save at the top, and a
/// small Enhance 4x button at the bottom. A photo with no picture yet is
/// rebuilt here first. Phones with 8 GB or more can enhance by themselves as
/// it opens, if the setting is on. The controls fade after a few seconds,
/// as the full-screen map's do, and come back on a touch.
class PhotoViewerScreen extends StatefulWidget {
  /// The photo in the chat; null for [previewPng].
  final String? messageId;

  /// The sender's preview before sending, zoomed and enhanced the same way,
  /// with no Save or menu.
  final Uint8List? previewPng;
  final int bytes;
  final String? tag;

  /// The sender of a received photo, which can be reported; null for ours.
  final String? senderName;
  final DateTime? photoTime;

  const PhotoViewerScreen({
    super.key,
    required String this.messageId,
    required this.bytes,
    required DateTime this.photoTime,
    this.tag,
    this.senderName,
  }) : previewPng = null;

  const PhotoViewerScreen.preview(
    Uint8List this.previewPng, {
    super.key,
    this.tag,
  }) : messageId = null,
       bytes = 0,
       photoTime = null,
       senderName = null;

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  ui.Image? _enlarged;
  bool _enlarging = false;

  /// Why there's no picture to show, once a rebuild here didn't give one.
  RebuildOutcome? _problem;
  final _zoom = TransformationController();
  Offset? _doubleTapAt;
  bool _faded = false;
  Timer? _fadeTimer;

  static bool get _phone =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    if (_phone) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
      );
    }
    _wake();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _zoom.dispose();
    _enlarged?.dispose();
    if (_phone) {
      unawaited(
        SystemChrome.setEnabledSystemUIMode(
          SystemUiMode.manual,
          overlays: SystemUiOverlay.values,
        ),
      );
    }
    super.dispose();
  }

  /// Rebuilds the photo if it has no picture yet, then enhances it by itself
  /// where the phone and the setting allow.
  Future<void> _start() async {
    final store = PhotoStore.instance;
    final messageId = widget.messageId;
    if (messageId != null && store.imageFor(messageId) == null) {
      final outcome = await store.rebuild(messageId);
      if (!mounted) return;
      setState(
        () => _problem = outcome == RebuildOutcome.shown ? null : outcome,
      );
      if (_problem != null) return;
    }
    if (photoAutoEnlargeAllowed && store.enlargeAutomatically) await _enlarge();
  }

  void _wake() {
    _fadeTimer?.cancel();
    if (_faded) setState(() => _faded = false);
    _fadeTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _faded = true);
    });
  }

  Future<void> _enlarge() async {
    if (_enlarging || _enlarged != null) return;
    setState(() => _enlarging = true);
    final store = PhotoStore.instance;
    final preview = widget.previewPng;
    final result = preview != null
        ? await store.enlargePng(preview)
        : await store.enlarge(widget.messageId!);
    final rgb = result.rgb;
    final image = rgb == null ? null : await rgbToImage(rgb, side: 2048);
    if (!mounted) {
      image?.dispose();
      return;
    }
    setState(() {
      _enlarging = false;
      _enlarged = image;
    });
    if (image != null) return;
    final l10n = context.l10n;
    showDismissibleSnackBar(
      context,
      content: Text(switch (result.outcome) {
        RebuildOutcome.noMemory => l10n.photo_enlargeNoMemory,
        RebuildOutcome.flagged => l10n.photo_enlargeFlagged,
        RebuildOutcome.noModel => l10n.photo_modelMissing,
        _ => l10n.photo_enlargeFailed,
      }),
    );
  }

  /// What's on screen, the enhanced picture or the rebuilt one, saved with
  /// its "AI reconstructed" mark.
  Future<void> _save() async {
    final l10n = context.l10n;
    final file = PhotoStore.instance.imageFor(widget.messageId!);
    if (file == null) return;
    final small = _enlarged == null
        ? await decodePng(file.readAsBytesSync())
        : null;
    final png = await markedPng(_enlarged ?? small!, l10n.photo_label);
    small?.dispose();
    final saved = await savePhotoPicture(png);
    if (!mounted) return;
    showDismissibleSnackBar(
      context,
      content: Text(saved ? l10n.photo_saved : l10n.photo_saveFailed),
    );
  }

  Future<void> _act(_ViewerAction action) async {
    final l10n = context.l10n;
    final sender = widget.senderName;
    switch (action) {
      case _ViewerAction.details:
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.photo_label),
            content: Text(
              [
                l10n.photo_caption(widget.bytes),
                if (_enlarged != null) l10n.photo_enlargedNote,
              ].join('\n\n'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.common_ok),
              ),
            ],
          ),
        );
      case _ViewerAction.report when sender != null:
        await reportPhoto(
          context,
          messageId: widget.messageId!,
          sender: sender,
          photoTime: widget.photoTime!,
        );
        if (mounted &&
            PhotoStore.instance.recordFor(widget.messageId!)?.reported ==
                true) {
          Navigator.of(context).pop();
        }
      case _ViewerAction.block when sender != null:
        await context.read<AppSettingsService>().blockSender(sender);
        if (!mounted) return;
        showDismissibleSnackBar(
          context,
          content: Text(l10n.photo_blockedSender(sender)),
        );
        Navigator.of(context).pop();
      case _ViewerAction.report || _ViewerAction.block:
        break;
    }
  }

  void _toggleZoom() {
    final at = _doubleTapAt;
    if (at == null || _zoom.value.getMaxScaleOnAxis() > 1.01) {
      _zoom.value = Matrix4.identity();
      return;
    }
    const scale = 2.5;
    _zoom.value = Matrix4.identity()
      ..translateByDouble(-at.dx * (scale - 1), -at.dy * (scale - 1), 0, 1)
      ..scaleByDouble(scale, scale, 1, 1);
  }

  Widget _status(BuildContext context) {
    final l10n = context.l10n;
    final problem = _problem;
    const quiet = TextStyle(color: Colors.white70);
    if (problem == null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white70),
          const SizedBox(height: 12),
          Text(l10n.photo_rebuilding, style: quiet),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            problem == RebuildOutcome.flagged
                ? Icons.hide_image_outlined
                : Icons.photo_outlined,
            color: Colors.white70,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            switch (problem) {
              RebuildOutcome.flagged => l10n.photo_hiddenFlagged,
              RebuildOutcome.noMemory => l10n.photo_noMemory,
              RebuildOutcome.noModel => l10n.photo_modelMissing,
              _ => l10n.photo_rebuildFailed,
            },
            style: quiet,
            textAlign: TextAlign.center,
          ),
          if (problem == RebuildOutcome.noMemory ||
              problem == RebuildOutcome.failed) ...[
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                setState(() => _problem = null);
                unawaited(_start());
              },
              child: Text(l10n.photo_tryAgain),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final padding = MediaQuery.paddingOf(context);
    final messageId = widget.messageId;
    final preview = widget.previewPng;
    final file = messageId == null
        ? null
        : PhotoStore.instance.imageFor(messageId);
    final shown = file != null || preview != null;
    final enlarged = _enlarged;
    final tag = widget.tag;
    final button = IconButton.styleFrom(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurfaceVariant,
    );
    Widget fading(Widget child) => AnimatedOpacity(
      opacity: _faded ? 0.4 : 1,
      duration: const Duration(milliseconds: 300),
      child: child,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Listener(
        onPointerDown: (_) => _wake(),
        child: Stack(
          children: [
            Positioned.fill(
              child: !shown
                  ? Center(child: _status(context))
                  : GestureDetector(
                      onDoubleTapDown: (d) => _doubleTapAt = d.localPosition,
                      onDoubleTap: _toggleZoom,
                      child: InteractiveViewer(
                        transformationController: _zoom,
                        maxScale: 6,
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                enlarged != null
                                    ? RawImage(
                                        image: enlarged,
                                        fit: BoxFit.contain,
                                      )
                                    : preview != null
                                    ? Image.memory(preview, fit: BoxFit.contain)
                                    : Image.file(file!, fit: BoxFit.contain),
                                const PhotoFootprintMark(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            if (shown)
              Positioned(
                left: 16,
                bottom: 16 + padding.bottom,
                child: const PhotoAiMark(),
              ),
            Positioned(
              top: padding.top + 8,
              left: 8,
              right: 8,
              child: fading(
                Row(
                  children: [
                    IconButton(
                      tooltip: l10n.common_close,
                      style: button,
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (file != null)
                      IconButton(
                        tooltip: l10n.photo_save,
                        style: button,
                        icon: const Icon(Icons.download_outlined),
                        onPressed: _save,
                      ),
                    if (messageId != null)
                      PopupMenuButton<_ViewerAction>(
                        style: button,
                        icon: const Icon(Icons.more_vert),
                        onSelected: _act,
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: _ViewerAction.details,
                            child: Text(l10n.photo_details),
                          ),
                          if (widget.senderName case final sender?) ...[
                            PopupMenuItem(
                              value: _ViewerAction.report,
                              child: Text(l10n.photo_report),
                            ),
                            PopupMenuItem(
                              value: _ViewerAction.block,
                              child: Text(l10n.photo_block(sender)),
                            ),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (tag != null)
              Positioned(
                top: padding.top + 64,
                left: 16,
                right: 16,
                child: Center(child: PhotoTagLabel(tag, onDark: true)),
              ),
            if (shown && enlarged == null)
              Positioned(
                bottom: 12 + padding.bottom,
                left: 0,
                right: 0,
                child: Center(
                  child: fading(
                    FilledButton.tonalIcon(
                      onPressed: _enlarging ? null : _enlarge,
                      icon: _enlarging
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.auto_awesome_outlined, size: 18),
                      label: Text(
                        _enlarging ? l10n.photo_enhancing : l10n.photo_enhance,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
