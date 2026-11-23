import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:traxmap/traxmap.dart';
import 'package:traxpix/traxpix.dart';
import 'package:traxpix_litert/traxpix_litert.dart';

import '../connector/meshcore_connector.dart';
import '../helpers/utf8_length_limiter.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n.dart';
import '../models/channel.dart';
import '../storage/prefs_manager.dart';
import '../services/photo_mesh.dart';
import '../services/photo_rules.dart';
import '../services/photo_store.dart';
import '../widgets/photo_ai_mark.dart';
import '../widgets/photo_footprint_mark.dart';
import '../widgets/photo_message_card.dart' show photoPositionDistance;

enum _Step { pick, crop, working, ready, flagged, sending }

class PhotoSendScreen extends StatefulWidget {
  final Channel channel;

  const PhotoSendScreen({super.key, required this.channel});

  @override
  State<PhotoSendScreen> createState() => _PhotoSendScreenState();
}

class _PhotoSendScreenState extends State<PhotoSendScreen> {
  _Step _step = _Step.pick;
  ui.Image? _source;
  final _transform = TransformationController();
  double _viewport = 320;
  bool _centred = false;
  String _working = '';
  Uint8List? _bitstream;
  Uint8List? _previewPng;
  String? _previewNote;
  String _sendStatus = '';
  final _tag = TextEditingController();

  /// Only to the radios in direct range; otherwise the photo goes the way the
  /// channel's messages go.
  bool _zeroHop = false;

  /// Faces are blurred before coding. On for each new photo.
  bool _blurFaces = true;

  /// Faces covered in the photo as coded, and whether in dark grey: the
  /// blurred photo didn't pass the check.
  int _faces = 0;
  bool _darkened = false;

  /// The radio's position goes with the photo. Off for each new photo.
  bool _includePosition = false;

  /// The position's size in bytes, which is its accuracy.
  int _positionBytes = 5;

  /// Asked for fresh positions while the switch is on.
  MeshCoreConnector? _positionSource;

  /// The sender has read why photos on Public and hashtag channels ask a lot
  /// of the mesh, and asked not to see it again.
  static const _openChannelKey = 'photo_open_channel_explained';

  @override
  void dispose() {
    _transform.dispose();
    _source?.dispose();
    _tag.dispose();
    _positionSource?.removeSelfPositionViewer();
    super.dispose();
  }

  bool get _canUseCamera => Platform.isIOS || Platform.isAndroid;

  Future<void> _pick(ImageSource source) async {
    final XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 95,
      );
    } on PlatformException catch (e) {
      // The picker asks for the camera itself; this is the answer "no".
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'camera_access_denied'
                ? context.l10n.photo_cameraDenied
                : context.l10n.photo_pickFailed(e.message ?? e.code),
          ),
        ),
      );
      return;
    }
    if (file == null) return;
    final codec = await ui.instantiateImageCodec(await file.readAsBytes());
    final frame = await codec.getNextFrame();
    setState(() {
      _source?.dispose();
      _source = frame.image;
      _centred = false;
      _transform.value = Matrix4.identity();
      _step = _Step.crop;
    });
  }

  /// Scale that makes the photo's short side fill the square.
  double get _fit {
    final s = _source!;
    return _viewport / math.min(s.width, s.height);
  }

  /// The part of the photo inside the square, in photo pixels.
  Rect get _cropRect {
    final s = _source!;
    final inverse = Matrix4.inverted(_transform.value);
    final a = MatrixUtils.transformPoint(inverse, Offset.zero) / _fit;
    final b =
        MatrixUtils.transformPoint(inverse, Offset(_viewport, _viewport)) /
        _fit;
    return Rect.fromPoints(
      a,
      b,
    ).intersect(Rect.fromLTWH(0, 0, s.width.toDouble(), s.height.toDouble()));
  }

  /// The crop scaled to 512x512 packed RGB, what the codec takes.
  Future<Uint8List> _cropToRgb() async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder).drawImageRect(
      _source!,
      _cropRect,
      const Rect.fromLTWH(0, 0, 512, 512),
      Paint()..filterQuality = FilterQuality.high,
    );
    final image = await recorder.endRecording().toImage(512, 512);
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    image.dispose();
    final rgb = Uint8List(512 * 512 * 3);
    for (var i = 0, j = 0; j < rgba.length; i += 3, j += 4) {
      rgb[i] = rgba[j];
      rgb[i + 1] = rgba[j + 1];
      rgb[i + 2] = rgba[j + 2];
    }
    return rgb;
  }

  Future<void> _preview() async {
    final l10n = context.l10n;
    setState(() {
      _step = _Step.working;
      _working = l10n.photo_checkingAndCoding;
      _previewPng = null;
      _previewNote = null;
    });
    final store = PhotoStore.instance;
    if (!await store.modelsReady()) {
      _fail(l10n.photo_modelMissing);
      return;
    }
    ImageCodecSession? codec;
    try {
      final rgb = await _cropToRgb();
      codec = await ImageCodecSession.spawn(await store.sendingBundle());
      final cover = _blurFaces ? FaceCover.blur : FaceCover.none;
      var sent = await codec.encode(rgb, faces: cover);
      var bitstream = sent.bitstream;
      if (bitstream == null) {
        setState(() => _step = _Step.flagged);
        return;
      }
      _bitstream = bitstream;
      _faces = sent.faces;
      _darkened = false;
      // What the receivers will see: rebuilt and checked here first.
      var room = imageCodecHasRoomToRebuild();
      if (!room) {
        releaseMapMemory();
        await Future<void>.delayed(const Duration(seconds: 1));
        room = imageCodecHasRoomToRebuild();
      }
      if (!room) {
        // No rebuild to check here, so the original takes the sender's margin.
        if (store.bundle.safetyRule.flags(sent.scores, forSender: true)) {
          setState(() => _step = _Step.flagged);
          return;
        }
        _previewNote = l10n.photo_previewNoMemory;
      } else {
        setState(() => _working = l10n.photo_rebuildingPreview);
        var rebuilt = await codec.rebuild(bitstream, forSender: true);
        if (rebuilt.flagged && cover == FaceCover.blur && sent.faces > 0) {
          // A blurred face can still be rebuilt as something it isn't: the
          // faces go under dark grey instead.
          sent = await codec.encode(rgb, faces: FaceCover.dark);
          bitstream = sent.bitstream;
          if (bitstream == null) {
            setState(() => _step = _Step.flagged);
            return;
          }
          _bitstream = bitstream;
          _darkened = true;
          rebuilt = await codec.rebuild(bitstream, forSender: true);
        }
        if (rebuilt.flagged) {
          setState(() => _step = _Step.flagged);
          return;
        }
        _previewPng = await rgbToPng(rebuilt.rgb!);
      }
      if (mounted) setState(() => _step = _Step.ready);
    } catch (e) {
      _fail(l10n.photo_prepareFailed('$e'));
    } finally {
      await codec?.dispose();
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    setState(() => _step = _Step.crop);
  }

  static String _secs(AppLocalizations l10n, Duration d) {
    final s = d.inMilliseconds / 1000.0;
    return l10n.photo_seconds(
      NumberFormat(s < 10 ? '0.0' : '0', l10n.localeName).format(s),
    );
  }

  /// What goes with the picture: the tag as typed and, when switched on, the
  /// radio's position at the chosen accuracy.
  PhotoExtras _extras(MeshCoreConnector connector) => PhotoExtras(
    tag: _tag.text,
    position: _includePosition && connector.hasSelfPosition
        ? PhotoPosition.at(
            connector.selfLatitude!,
            connector.selfLongitude!,
            bytes: _positionBytes,
          )
        : null,
  );

  /// Packets the coded photo takes with its extras, the repair packet
  /// included.
  int _packets(MeshCoreConnector connector) =>
      imageDataChunkCount(
        photoPayload(_bitstream!, _extras(connector)).length,
      ) +
      1;

  void _watchPosition(MeshCoreConnector connector, bool on) {
    _includePosition = on;
    if (on && _positionSource == null) {
      _positionSource = connector..addSelfPositionViewer();
    } else if (!on && _positionSource != null) {
      _positionSource!.removeSelfPositionViewer();
      _positionSource = null;
    }
  }

  /// On a MeshCore frequency the sender confirms what the photo costs. On
  /// Public or a hashtag channel they first read why a photo there asks a lot
  /// of the mesh, until they say not to show it again.
  Future<bool> _confirmSend(MeshCoreConnector connector) async {
    final warning = photoWarningFor(widget.channel, connector.currentFreqHz);
    if (warning == PhotoWarning.none) return true;
    final l10n = context.l10n;
    final airtimeMs = connector.estimatePacketAirtimeMs;
    final onAir =
        Duration(milliseconds: airtimeMs(kPhotoPacketAirBytes)) *
        _packets(connector);
    final messages = photoTextMessages(onAir, airtimeMs);
    final open = warning == PhotoWarning.openChannel;
    if (open && !(PrefsManager.instance.getBool(_openChannelKey) ?? false)) {
      if (!await _explainOpenChannel(onAir, messages) || !mounted) {
        return false;
      }
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.photo_confirmTitle),
        content: Text(
          [
            l10n.photo_confirmAirtime(
              _packets(connector),
              _secs(l10n, onAir),
              messages,
            ),
            if (open) l10n.photo_confirmOpenChannel(widget.channel.displayName),
            _zeroHop ? l10n.photo_confirmZeroHop : l10n.photo_confirmFlood,
          ].join('\n\n'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.photo_send),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  /// Why a photo on Public or a hashtag channel asks a lot of the mesh, and
  /// what's better; "don't show again" persists.
  Future<bool> _explainOpenChannel(Duration onAir, int messages) async {
    final l10n = context.l10n;
    var dontShowAgain = false;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(l10n.photo_openChannelTitle(widget.channel.displayName)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final line in [
                  l10n.photo_openChannelNotEveryone,
                  l10n.photo_openChannelAirtime(_secs(l10n, onAir), messages),
                  l10n.photo_openChannelRepeaters,
                  l10n.photo_openChannelBetter,
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(line),
                  ),
                CheckboxListTile(
                  title: Text(l10n.photo_dontShowAgain),
                  value: dontShowAgain,
                  onChanged: (value) =>
                      setDialogState(() => dontShowAgain = value ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.common_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.common_continue),
            ),
          ],
        ),
      ),
    );
    if (ok == true && dontShowAgain) {
      await PrefsManager.instance.setBool(_openChannelKey, true);
    }
    return ok == true;
  }

  Future<void> _send() async {
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();
    if (!await _confirmSend(connector) || !mounted) return;
    setState(() {
      _step = _Step.sending;
      _sendStatus = l10n.photo_sending;
    });
    try {
      await PhotoMesh.of(connector).sendPhoto(
        _bitstream!,
        widget.channel.index,
        tag: _tag.text,
        position: _extras(connector).position,
        zeroHop: _zeroHop,
        previewPng: _previewPng,
        onProgress: (p) {
          if (mounted) {
            setState(
              () => _sendStatus = p.isParityChunk
                  ? l10n.photo_sendingRepairPacket(p.sentChunks, p.totalChunks)
                  : l10n.photo_sendingPacket(p.sentChunks, p.totalChunks),
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      final why = e is PhotoSendException ? e.text(l10n) : '$e';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.photo_notSent(why))));
      setState(() => _step = _Step.ready);
      return;
    }
    if (photoRulesApply(connector.currentFreqHz)) {
      await notePhotoSent(
        connector.selfPublicKeyHex,
        DateTime.now(),
        viaRepeaters: !_zeroHop,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.photo_sendTitle(widget.channel.displayName)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: switch (_step) {
            _Step.pick => _pickView(context),
            _Step.crop => _cropView(context),
            _Step.working => [
              const SizedBox(height: 48),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(_working, textAlign: TextAlign.center),
            ],
            _Step.flagged => [
              const SizedBox(height: 32),
              const Icon(Icons.block, size: 48),
              const SizedBox(height: 12),
              Text(
                context.l10n.photo_flaggedNotSent,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => setState(() => _step = _Step.pick),
                child: Text(context.l10n.photo_chooseAnother),
              ),
            ],
            _Step.ready || _Step.sending => _readyView(context),
          },
        ),
      ),
    );
  }

  List<Widget> _pickView(BuildContext context) => [
    Text(context.l10n.photo_squareIntro),
    const SizedBox(height: 16),
    if (_canUseCamera)
      FilledButton.icon(
        onPressed: () => _pick(ImageSource.camera),
        icon: const Icon(Icons.photo_camera),
        label: Text(context.l10n.photo_takePhoto),
      ),
    const SizedBox(height: 8),
    FilledButton.tonalIcon(
      onPressed: () => _pick(ImageSource.gallery),
      icon: const Icon(Icons.photo_library),
      label: Text(context.l10n.photo_choosePhoto),
    ),
  ];

  List<Widget> _cropView(BuildContext context) => [
    Text(context.l10n.photo_cropHint),
    const SizedBox(height: 12),
    LayoutBuilder(
      builder: (context, constraints) {
        _viewport = math.min(constraints.maxWidth, 420);
        final s = _source!;
        final w = s.width * _fit, h = s.height * _fit;
        if (!_centred) {
          _centred = true;
          _transform.value = Matrix4.translationValues(
            -(w - _viewport) / 2,
            -(h - _viewport) / 2,
            0,
          );
        }
        return Center(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            child: ClipRect(
              child: SizedBox(
                width: _viewport,
                height: _viewport,
                child: InteractiveViewer(
                  transformationController: _transform,
                  constrained: false,
                  minScale: 1,
                  maxScale: 8,
                  boundaryMargin: EdgeInsets.zero,
                  child: SizedBox(
                    width: w,
                    height: h,
                    child: RawImage(image: s, fit: BoxFit.fill),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: const Icon(Icons.face_retouching_off),
      title: Text(context.l10n.photo_blurFaces),
      subtitle: Text(context.l10n.photo_blurFacesHint),
      value: _blurFaces,
      onChanged: (on) => setState(() => _blurFaces = on),
    ),
    const SizedBox(height: 8),
    FilledButton(onPressed: _preview, child: Text(context.l10n.photo_preview)),
    TextButton(
      onPressed: () => setState(() => _step = _Step.pick),
      child: Text(context.l10n.photo_chooseAnother),
    ),
  ];

  List<Widget> _readyView(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final quiet = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final connector = context.watch<MeshCoreConnector>();
    final packets = _packets(connector);
    final airtimeMs = connector.estimatePacketAirtimeMs;
    final sendTime =
        photoGapFor(
              photoPayload(_bitstream!, _extras(connector)).length,
              zeroHop: _zeroHop,
              airtimeMs: airtimeMs,
              shared: photoRulesApply(connector.currentFreqHz),
            ) *
            (packets - 1) +
        Duration(milliseconds: airtimeMs(kPhotoPacketAirBytes));
    final sending = _step == _Step.sending;
    final key = connector.selfPublicKeyHex;
    final blocked = sending || PhotoStore.instance.ignoreTimeLimits
        ? null
        : photoSendBlocked(
            freqKhz: connector.currentFreqHz,
            lastSent: photoLastSent(key),
            lastSentViaRepeaters: photoLastSentViaRepeaters(key),
            viaRepeaters: !_zeroHop,
            now: DateTime.now(),
          );
    return [
      if (_previewPng != null)
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  Image.memory(_previewPng!, width: double.infinity),
                  const Positioned(left: 8, bottom: 6, child: PhotoAiMark()),
                  const Positioned.fill(child: PhotoFootprintMark()),
                ],
              ),
            ),
          ),
        ),
      if (_previewNote != null) Text(_previewNote!, style: quiet),
      if (_faces > 0)
        Text(
          _darkened
              ? l10n.photo_facesDarkened(_faces)
              : l10n.photo_facesBlurred(_faces),
          style: quiet,
        ),
      const SizedBox(height: 16),
      TextField(
        controller: _tag,
        enabled: !sending,
        maxLength: kPhotoTagMaxCharacters,
        inputFormatters: [
          Utf8LengthLimitingTextInputFormatter(kPhotoTagMaxBytes),
        ],
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: l10n.photo_tagTitle,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (_) => setState(() {}),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.place_outlined),
        title: Text(l10n.photo_includePosition),
        subtitle: Text(
          connector.hasSelfPosition
              ? l10n.photo_positionFromRadio(
                  photoPositionDistance(l10n, _positionBytes),
                )
              : l10n.photo_noPosition,
        ),
        value: _includePosition && connector.hasSelfPosition,
        onChanged: sending || !connector.hasSelfPosition
            ? null
            : (on) => setState(() => _watchPosition(connector, on)),
      ),
      if (_includePosition && connector.hasSelfPosition)
        SegmentedButton<int>(
          segments: [
            for (final size in kPhotoPositionSizes)
              ButtonSegment(
                value: size,
                label: Text(photoPositionDistance(l10n, size)),
              ),
          ],
          selected: {_positionBytes},
          showSelectedIcon: false,
          onSelectionChanged: sending
              ? null
              : (s) => setState(() => _positionBytes = s.first),
        ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.near_me_outlined),
        title: Text(l10n.photo_zeroHop),
        subtitle: Text(l10n.photo_zeroHopHint),
        value: _zeroHop,
        onChanged: sending ? null : (on) => setState(() => _zeroHop = on),
      ),
      Text(
        l10n.photo_sendFigures(packets, _secs(l10n, sendTime)),
        style: quiet,
      ),
      if (blocked != null) ...[
        const SizedBox(height: 8),
        Text(switch (blocked.reason) {
          PhotoBlockReason.wait => l10n.photo_blockedWait(
            photoGapZeroHop.inMinutes,
            blocked.minutes,
          ),
          PhotoBlockReason.waitRepeaters => l10n.photo_blockedWaitRepeaters(
            photoGapRepeaters.inMinutes,
            blocked.minutes,
          ),
        }, style: quiet?.copyWith(color: theme.colorScheme.error)),
      ],
      const SizedBox(height: 16),
      Row(
        children: [
          if (!sending)
            TextButton.icon(
              onPressed: () => setState(() => _step = _Step.crop),
              icon: const Icon(Icons.crop, size: 18),
              label: Text(l10n.photo_changeCrop),
            ),
          const Spacer(),
          FilledButton.icon(
            onPressed: sending || blocked != null || !connector.isConnected
                ? null
                : _send,
            icon: const Icon(Icons.send),
            label: Text(sending ? _sendStatus : l10n.photo_send),
          ),
        ],
      ),
    ];
  }
}
