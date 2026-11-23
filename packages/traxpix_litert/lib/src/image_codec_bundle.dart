import 'image_safety.dart';

/// The LiteRT photo model's files: the entropy network as six models (send
/// side, hyper synthesis, the four decode stages), the decoder in three (gs,
/// unet, vae), the 4x enlarger, the safety classifier, and the CDF tables.
class ImageCodecBundle {
  final String sidePath;
  final String hyperPath;
  final List<String> stagePaths;
  final String gsPath;
  final String unetPath;
  final String vaePath;
  final String enhancePath;
  final String safetyPath;
  final String tablesPath;

  /// Where XNNPACK keeps its packed weights, one file per model, written on
  /// first use. They are mapped from there instead of taking the app's
  /// memory. Null keeps them in memory.
  final String? weightCacheDir;
  final ImageSafetyThresholds safetyThresholds;

  const ImageCodecBundle({
    required this.sidePath,
    required this.hyperPath,
    required this.stagePaths,
    required this.gsPath,
    required this.unetPath,
    required this.vaePath,
    required this.enhancePath,
    required this.safetyPath,
    required this.tablesPath,
    this.weightCacheDir,
    this.safetyThresholds = ImageSafetyThresholds.standard,
  });

  /// The ft8 files in [dir], as `kImageCodecFiles` names them, with the
  /// weight caches in its `xnnpack` folder unless [weightCache] is false.
  factory ImageCodecBundle.inDirectory(String dir, {bool weightCache = true}) =>
      ImageCodecBundle(
        sidePath: '$dir/aeic_side_ft8.tflite',
        hyperPath: '$dir/aeic_hyper_ft8.tflite',
        stagePaths: [
          for (var i = 0; i < 4; i++) '$dir/aeic_stage${i}_ft8.tflite',
        ],
        gsPath: '$dir/aeic_decoder_gs_ft8_pt2e.tflite',
        unetPath: '$dir/aeic_decoder_unet_ft8_pt2e.tflite',
        vaePath: '$dir/aeic_decoder_vae_ft8_f32.tflite',
        enhancePath: '$dir/realesr-general-x4v3-dn05.tflite',
        safetyPath: '$dir/image-safety-classifier-s.tflite',
        tablesPath: '$dir/aeic_cdf_ft8.bin',
        weightCacheDir: weightCache ? '$dir/xnnpack' : null,
      );

  List<String> get allPaths => [
    sidePath,
    hyperPath,
    ...stagePaths,
    gsPath,
    unetPath,
    vaePath,
    enhancePath,
    safetyPath,
    tablesPath,
  ];
}
