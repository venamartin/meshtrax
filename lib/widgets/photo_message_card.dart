import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:traxpix/traxpix.dart' show PhotoPosition, litBox;

import '../helpers/link_handler.dart';
import '../helpers/navigate_helper.dart';
import '../helpers/position_text.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../services/photo_mesh.dart';
import '../services/photo_model_downloads.dart';
import '../services/photo_save.dart';
import '../services/photo_store.dart';
import '../utils/format_bytes.dart';
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
    final models = PhotoModelDownloads.instance;
    if (image == null &&
        !record.outgoing &&
        models != null &&
        (!store.photosEnabled || !models.installed)) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox.square(
          dimension: size,
          child: ColoredBox(
            color: scheme.surfaceContainerHigh,
            child: Center(child: _getPhotos(context, models)),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PhotoViewerScreen(
            messageId: messageId,
            bytes: record.bytes,
            tag: record.tag,
            senderName: record.outgoing ? null : senderName,
            photoTime: photoTime,
            subjectOnly: record.subjectOnly,
            subjectBox: record.subjectBox,
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
                    _framed(
                      Image.file(image, fit: BoxFit.cover, gaplessPlayback: true),
                      record.subjectBox,
                      size,
                    ),
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

  /// [picture], a [size] square, zoomed in on [box]: a Subject only photo's
  /// subject, as fractions of its side. Unchanged without one.
  static Widget _framed(Widget picture, List<double>? box, double size) {
    if (box == null) return picture;
    final w = box[2] - box[0], h = box[3] - box[1];
    final k = (1 / (w > h ? w : h)).clamp(1.0, 4.0);
    final cx = (box[0] + box[2]) / 2 * size;
    final cy = (box[1] + box[3]) / 2 * size;
    return ClipRect(
      child: Transform(
        transform: Matrix4.identity()
          ..translateByDouble(size / 2 - k * cx, size / 2 - k * cy, 0, 1)
          ..scaleByDouble(k, k, 1, 1),
        child: picture,
      ),
    );
  }

  /// A received photo this phone can't show yet, as photos are off or the
  /// photo model isn't on it: one button turns photos on and downloads the
  /// model, after saying how big it is; then the photo shows its progress,
  /// and once the model is in, the photo can be rebuilt.
  Widget _getPhotos(BuildContext context, PhotoModelDownloads models) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final total = PhotoModelDownloads.totalBytes;
    final downloading = models.active.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_outlined,
            size: 40,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 6),
          Text(
            downloading
                ? l10n.photo_modelTitle
                : models.installed
                ? l10n.photo_photosOffHint
                : l10n.photo_getPhotosHint(formatBytes(total)),
            style: quiet,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          if (downloading) ...[
            LinearProgressIndicator(value: models.bytesDone / total),
            const SizedBox(height: 4),
            Text(
              l10n.photo_modelProgress(
                formatBytes(models.bytesDone),
                formatBytes(total),
              ),
              style: quiet,
            ),
          ] else
            FilledButton.tonal(
              onPressed: () => _turnOnPhotos(context, models),
              child: Text(l10n.photo_getPhotos),
            ),
        ],
      ),
    );
  }

  /// Turns photos on, and downloads the photo model once the user said yes
  /// to its size, as App settings, Messaging, Photos does.
  Future<void> _turnOnPhotos(
    BuildContext context,
    PhotoModelDownloads models,
  ) async {
    final store = PhotoStore.instance;
    if (models.installed) {
      store.photosEnabled = true;
      return;
    }
    final l10n = context.l10n;
    final size = formatBytes(PhotoModelDownloads.totalBytes);
    final wifiOnly = context
        .read<AppSettingsService>()
        .settings
        .mapDownloadsWifiOnly;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.photo_getPhotosTitle),
        content: Text(
          wifiOnly
              ? '${l10n.photo_getPhotosBody(size)} ${l10n.photo_getPhotosWifi}'
              : l10n.photo_getPhotosBody(size),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.photo_downloadModel),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    store.photosEnabled = true;
    final short = await models.download(l10n);
    if (short != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.photo_notEnoughSpace(
              formatBytes(short.needed),
              formatBytes(short.free),
            ),
          ),
        ),
      );
    }
  }

  /// What a photo of mine is doing while its packets go.
  Widget _sendingLine(BuildContext context, PhotoSendState going) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final failed = going.step == PhotoSendStep.failed;
    final color = failed
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    final error = going.error;
    final text = switch (going.step) {
      PhotoSendStep.waiting => l10n.photo_waitingToSend,
      PhotoSendStep.sending => going.repair
          ? l10n.photo_sendingRepairPacket(going.packet, going.packets)
          : l10n.photo_sendingPacket(going.packet, going.packets),
      PhotoSendStep.again =>
        l10n.photo_sendingPacketAgain(going.packet, going.packets),
      PhotoSendStep.observers =>
        l10n.photo_askingObservers(going.packet, going.packets),
      PhotoSendStep.failed => l10n.photo_notSent(
        error is PhotoSendException ? error.text(l10n) : '$error',
      ),
    };
    return SizedBox(
      width: size,
      child: Row(
        children: [
          if (failed)
            Icon(Icons.error_outline, size: 14, color: color)
          else
            SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: color),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = PhotoStore.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([
        store,
        PhotoMesh.sending,
        ?PhotoModelDownloads.instance,
      ]),
      builder: (context, _) {
        final record = store.recordFor(messageId);
        if (record == null) return Text(context.l10n.photo_chatPhoto);
        final body = _body(context, record);
        final tag = record.tag;
        final position = record.position;
        final going = record.outgoing
            ? PhotoMesh.sending.value[messageId]
            : null;
        if (tag == null && position == null && going == null) return body;
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
            if (going != null) ...[
              const SizedBox(height: 6),
              _sendingLine(context, going),
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

  /// Only the subject was sent, on black: the viewer opens zoomed in on it,
  /// at [subjectBox] when it's known (fractions of the picture's side).
  final bool subjectOnly;
  final List<double>? subjectBox;

  const PhotoViewerScreen({
    super.key,
    required String this.messageId,
    required this.bytes,
    required DateTime this.photoTime,
    this.tag,
    this.senderName,
    this.subjectOnly = false,
    this.subjectBox,
  }) : previewPng = null;

  const PhotoViewerScreen.preview(
    Uint8List this.previewPng, {
    super.key,
    this.tag,
    this.subjectOnly = false,
    this.subjectBox,
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

  /// Where a Subject only picture's subject is, as fractions of its side,
  /// and whether the view has opened on it yet.
  ({double left, double top, double right, double bottom})? _subject;
  bool _framed = false;

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
    await _findSubject();
    if (photoAutoEnlargeAllowed && store.enlargeAutomatically) await _enlarge();
  }

  /// The lit part of a Subject only picture, to open zoomed in on.
  Future<void> _findSubject() async {
    if (!widget.subjectOnly) return;
    if (widget.subjectBox case [final l, final t, final r, final b]) {
      if (mounted) {
        setState(() => _subject = (left: l, top: t, right: r, bottom: b));
      }
      return;
    }
    final png =
        widget.previewPng ??
        PhotoStore.instance.imageFor(widget.messageId!)?.readAsBytesSync();
    if (png == null) return;
    final image = await decodePng(png);
    final side = image.width;
    final rgba = (await image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    ))!.buffer.asUint8List();
    image.dispose();
    final rgb = Uint8List(side * side * 3);
    for (var i = 0, j = 0; j < rgba.length; i += 3, j += 4) {
      rgb[i] = rgba[j];
      rgb[i + 1] = rgba[j + 1];
      rgb[i + 2] = rgba[j + 2];
    }
    final box = litBox(rgb, side: side);
    if (mounted && box != null) setState(() => _subject = box);
  }

  /// The view that frames [box] (fractions of the square picture, which is
  /// centred in [size]) with a little room around it.
  static Matrix4 _framing(
    ({double left, double top, double right, double bottom}) box,
    Size size,
  ) {
    final s = size.shortestSide;
    final ox = (size.width - s) / 2, oy = (size.height - s) / 2;
    final w = (box.right - box.left) * s, h = (box.bottom - box.top) * s;
    final k = (0.92 * (size.width / w < size.height / h
            ? size.width / w
            : size.height / h))
        .clamp(1.0, 6.0);
    final cx = ox + (box.left + box.right) / 2 * s;
    final cy = oy + (box.top + box.bottom) / 2 * s;
    return Matrix4.identity()
      ..translateByDouble(size.width / 2 - k * cx, size.height / 2 - k * cy, 0, 1)
      ..scaleByDouble(k, k, 1, 1);
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
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final subject = _subject;
                        if (subject != null && !_framed) {
                          _framed = true;
                          final size = constraints.biggest;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted) {
                              _zoom.value = _framing(subject, size);
                            }
                          });
                        }
                        return GestureDetector(
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
                    );
                      },
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
