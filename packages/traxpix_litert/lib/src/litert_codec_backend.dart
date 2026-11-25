import 'dart:typed_data';

import 'package:traxpix/traxpix.dart';
import 'image_codec_bundle.dart';
import 'image_safety.dart';
import 'litert_api.dart';
import 'tap_segmenter.dart';

/// Side of the square picture the graphs are exported for.
const int kImageCodecSquareSize = 512;

/// Side of a rebuilt picture enlarged 4x.
const int kImageCodecEnhancedSize = 4 * kImageCodecSquareSize;

/// Runs the photo model's LiteRT files. No model is compiled until an
/// operation needs it, the send and receive halves of the entropy network are
/// released before the decoder is compiled, and the decoder before either
/// entropy half.
class LiteRtImageCodecBackend {
  final ImageCodecBundle bundle;
  final AeicRansCoders _coders;
  final int threads;

  /// Where XNNPACK's packed-weight caches go, one per model, or null to keep
  /// packed weights in memory.
  final String? weightCacheDir;

  final LiteRtEnvironment _environment;
  final AeicEntropyGeometry _geometry = AeicEntropyGeometry.forResolution(
    kImageCodecSquareSize,
  );

  LiteRtModel? _side;
  LiteRtModel? _hyper;
  List<LiteRtModel>? _stages;
  LiteRtModel? _gs;
  LiteRtModel? _unet;
  LiteRtModel? _vae;
  LiteRtModel? _safety;
  LiteRtModel? _faceShort;
  LiteRtModel? _faceFull;
  LiteRtModel? _tap;

  LiteRtImageCodecBackend(
    this.bundle,
    this._coders, {
    required LiteRtApi api,
    required this.threads,
    this.weightCacheDir,
  }) : _environment = LiteRtEnvironment.create(api);

  LiteRtModel _load(
    String path, {
    int xnnpackFlags = 0,
    bool weightCache = true,
  }) => LiteRtModel.load(
    _environment,
    path,
    threads: threads,
    weightCachePath: weightCacheDir == null || !weightCache
        ? null
        : '$weightCacheDir/${path.split('/').last}.xnnpack_cache',
    xnnpackFlags: xnnpackFlags,
  );

  /// A float32 model in half precision, which for the decoder's last stage
  /// keeps flat areas such as sky smooth; in full precision on a CPU that
  /// can't. Never with the weight cache: in LiteRT 2.3.0 the cache aborts the
  /// app on a half-precision model (MMapWeightCacheProvider::LookUpOrInsert),
  /// and both such models are small.
  LiteRtModel _loadHalf(String path) {
    try {
      return _load(path, xnnpackFlags: kXnnpackForceFp16, weightCache: false);
    } on LiteRtException {
      return _load(path, weightCache: false);
    }
  }

  /// Checks the original, then covers its faces as [cover] says and codes
  /// it. The check is on the photo as taken, before any cover.
  Future<EncodedImage> checkedEncode(
    Uint8List rgbBytes, {
    FaceCover cover = FaceCover.none,
  }) async {
    final scores = classify(rgbBytes);
    if (bundle.safetyRule.flags(scores)) {
      return EncodedImage(scores: scores, flagged: true);
    }
    final (picture, faces) = coverFaces(rgbBytes, cover);
    return EncodedImage(
      scores: scores,
      flagged: false,
      bitstream: await encode(picture),
      faces: faces,
    );
  }

  /// [rgbBytes] with its faces covered as [cover] says, and how many.
  (Uint8List, int) coverFaces(Uint8List rgbBytes, FaceCover cover) {
    if (cover == FaceCover.none) return (rgbBytes, 0);
    final faces = findFaces(rgbBytes, _runFaceModel);
    final covered = cover == FaceCover.dark
        ? darkenFaces(rgbBytes, faces)
        : blurFaces(rgbBytes, faces);
    return (covered, faces.length);
  }

  /// One of the two BlazeFace models, kept loaded once used: they're small.
  /// Their outputs are told apart by size, 16 regressors per anchor and one
  /// score.
  FaceModelOutput _runFaceModel(Float32List input, {required bool fullRange}) {
    final path = fullRange ? bundle.faceFullPath : bundle.faceShortPath;
    if (path == null) throw StateError('This bundle has no face models.');
    final model = fullRange
        ? _faceFull ??= _load(path, weightCache: false)
        : _faceShort ??= _load(path, weightCache: false);
    final out = model.run([input]).values.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (out.length != 2) {
      throw StateError('$path gave ${out.length} outputs, not 2.');
    }
    return (regressors: out.first, logits: out.last);
  }

  /// What's under each of [taps] (x, y pairs from 0 to 1, from the top left)
  /// in [rgbBytes], the whole photo stretched to 512 x 512, outlined by the
  /// tap model and joined: 512 x 512, 255 where it's something tapped. The
  /// model stays loaded once used: it's small.
  Uint8List segment(Uint8List rgbBytes, List<double> taps) {
    final path = bundle.tapPath;
    if (path == null) throw StateError('This bundle has no tap model.');
    final model = _tap ??= _load(path, weightCache: false);
    const pixels = kTapSegmenterSize * kTapSegmenterSize;
    final joined = Uint8List(pixels);
    for (var t = 0; t + 1 < taps.length; t += 2) {
      final out = model
          .run([tapModelInput(rgbBytes, taps[t], taps[t + 1])])
          .values
          .single;
      if (out.length != pixels) {
        throw StateError('Tap model gave ${out.length} values, not $pixels.');
      }
      for (var i = 0; i < pixels; i++) {
        final v = out[i] <= 0
            ? 0
            : out[i] >= 1
            ? 255
            : (out[i] * 255).round();
        if (v > joined[i]) joined[i] = v;
      }
    }
    return joined;
  }

  Future<RebuiltImage> rebuild(
    Uint8List bitstream, {
    bool forSender = false,
  }) async {
    final rgb = await decodeToRgb(bitstream);
    final scores = classify(rgb);
    final flagged = bundle.safetyRule.flags(scores, forSender: forSender);
    return RebuiltImage(
      scores: scores,
      flagged: flagged,
      rgb: flagged ? null : rgb,
    );
  }

  ImageSafetyScores classify(
    Uint8List rgbBytes, {
    int side = kImageCodecSquareSize,
  }) {
    final model = _safety ??= _load(bundle.safetyPath);
    final p = model.run([imageSafetyInput(rgbBytes, side)])['output_0']!;
    if (p.length != 3) {
      throw StateError('Safety classifier gave ${p.length} scores, not 3.');
    }
    return ImageSafetyScores(nsfl: p[0], nsfw: p[1], sfw: p[2]);
  }

  Future<Uint8List> encode(Uint8List rgbBytes) async {
    _releaseDecoder();
    final side = _side ??= _load(bundle.sidePath);
    return _codec(LiteRtAeicEntropyNetwork(side: side)).encode(rgbBytes);
  }

  Future<Float32List> decodeToLatent(Uint8List bitstream) async {
    _releaseDecoder();
    final hyper = _hyper ??= _load(bundle.hyperPath);
    final stages = _stages ??= [for (final p in bundle.stagePaths) _load(p)];
    return _codec(
      LiteRtAeicEntropyNetwork(hyper: hyper, stages: stages),
    ).decodeToLatent(bitstream);
  }

  Future<Uint8List> decodeToRgb(Uint8List bitstream) async {
    final yHat = await decodeToLatent(bitstream);
    _releaseEntropy();
    return decodeLatentToRgb(yHat);
  }

  /// gs -> unet -> vae, as the lab's decode_compare.py runs them:
  /// `l_0 = unet(l_t) + residual`.
  Uint8List decodeLatentToRgb(Float32List yHat) {
    final gs = _gs ??= _load(bundle.gsPath);
    final unet = _unet ??= _load(bundle.unetPath);
    final vae = _vae ??= _loadHalf(bundle.vaePath);
    final g = gs.run([yHat]);
    final residual = g['output_1']!;
    final u = unet.run([g['output_0']!])['output_0']!;
    final l0 = Float32List(u.length);
    for (var i = 0; i < u.length; i++) {
      l0[i] = u[i] + residual[i];
    }
    return _chwFloatsToRgb(vae.run([l0])['output_0']!);
  }

  /// A rebuilt picture enlarged 4x by the compact Real-ESRGAN model, then
  /// checked like any rebuilt picture. Every other model is released first,
  /// and the enlarger after, so it never shares the memory with them.
  EnhancedImage enhance(Uint8List rgb) {
    _releaseDecoder();
    _releaseEntropy();
    const side = kImageCodecSquareSize, pixels = side * side;
    if (rgb.length != pixels * 3) {
      throw ArgumentError(
        'expected ${pixels * 3} RGB bytes, got ${rgb.length}',
      );
    }
    final input = Float32List(pixels * 3);
    for (var channel = 0; channel < 3; channel++) {
      for (var i = 0; i < pixels; i++) {
        input[channel * pixels + i] = rgb[i * 3 + channel] / 255.0;
      }
    }
    final model = _loadHalf(bundle.enhancePath);
    final Float32List out;
    try {
      out = model.run([input]).values.single;
    } finally {
      model.dispose();
    }
    const big = kImageCodecEnhancedSize * kImageCodecEnhancedSize;
    if (out.length != big * 3) {
      throw StateError(
        'Enlarger returned ${out.length} values, not ${big * 3}.',
      );
    }
    final enlarged = Uint8List(big * 3);
    for (var channel = 0; channel < 3; channel++) {
      final plane = channel * big;
      for (var i = 0, o = channel; i < big; i++, o += 3) {
        final scaled = out[plane + i] * 255;
        enlarged[o] = scaled <= 0
            ? 0
            : scaled >= 255
            ? 255
            : scaled.round();
      }
    }
    final scores = classify(enlarged, side: kImageCodecEnhancedSize);
    final flagged = bundle.safetyRule.flags(scores);
    return EnhancedImage(
      scores: scores,
      flagged: flagged,
      rgb: flagged ? null : enlarged,
    );
  }

  AeicEntropyCodec _codec(LiteRtAeicEntropyNetwork network) =>
      AeicEntropyCodec(geometry: _geometry, network: network, coders: _coders);

  static Uint8List _chwFloatsToRgb(Float32List flat) {
    const side = kImageCodecSquareSize;
    const pixels = side * side;
    if (flat.length != pixels * 3) {
      throw StateError(
        'Decoder returned ${flat.length} values, not ${pixels * 3}.',
      );
    }
    final rgb = Uint8List(pixels * 3);
    for (var channel = 0; channel < 3; channel++) {
      final plane = channel * pixels;
      var out = channel;
      for (var i = 0; i < pixels; i++, out += 3) {
        final scaled = (flat[plane + i] + 1.0) * 127.5;
        rgb[out] = scaled <= 0
            ? 0
            : scaled >= 255
            ? 255
            : scaled.round();
      }
    }
    return rgb;
  }

  void _releaseDecoder() {
    for (final model in [_gs, _unet, _vae]) {
      model?.dispose();
    }
    _gs = _unet = _vae = null;
  }

  void _releaseEntropy() {
    for (final model in [_side, _hyper, ...?_stages]) {
      model?.dispose();
    }
    _side = _hyper = null;
    _stages = null;
  }

  void dispose() {
    _releaseDecoder();
    _releaseEntropy();
    for (final model in [_safety, _faceShort, _faceFull, _tap]) {
      model?.dispose();
    }
    _safety = _faceShort = _faceFull = _tap = null;
    _environment.dispose();
  }
}

/// [AeicEntropyNetwork] over the LiteRT entropy models. Their outputs are
/// `output_<n>` in the order the lab's convert_torch.py returns them: the
/// send side's z_q is output 2, y_q0..3 outputs 7..10 and scales0..3 outputs
/// 11..14; a stage gives means then scales, already masked.
class LiteRtAeicEntropyNetwork implements AeicEntropyNetwork {
  final LiteRtModel? side;
  final LiteRtModel? hyper;
  final List<LiteRtModel>? stages;

  const LiteRtAeicEntropyNetwork({this.side, this.hyper, this.stages});

  @override
  bool get supportsDecodeSide => hyper != null && stages?.length == 4;

  @override
  Future<AeicEncodeSideTensors> runEncodeSide(Float32List imageChw) async {
    final model = side;
    if (model == null) {
      throw const AeicEntropyUnavailable('no send-side model loaded');
    }
    final out = model.run([imageChw]);
    return AeicEncodeSideTensors(
      zQ: out['output_2']!,
      yQ: [for (var i = 0; i < 4; i++) out['output_${7 + i}']!],
      scales: [for (var i = 0; i < 4; i++) out['output_${11 + i}']!],
    );
  }

  @override
  Future<Float32List> runHyperSynthesis(Float32List zQ) async {
    final model = hyper;
    if (model == null) {
      throw const AeicEntropyUnavailable('no hyper-synthesis model loaded');
    }
    return model.run([zQ])['output_0']!;
  }

  @override
  Future<AeicStageParams> runStage(int stage, Float32List base) async {
    final models = stages;
    if (models == null) {
      throw const AeicEntropyUnavailable('no decode-stage models loaded');
    }
    if (stage < 0 || stage > 3) {
      throw ArgumentError.value(stage, 'stage', 'must be 0..3');
    }
    final out = models[stage].run([base]);
    return AeicStageParams(
      meansSupp: out['output_0']!,
      scalesSupp: out['output_1']!,
    );
  }
}
