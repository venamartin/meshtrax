/// One hosted file of the photo model. The app downloads it from [url] and
/// keeps it only if it is exactly [bytes] long with this [sha256].
class ImageCodecFile {
  final String name;
  final int bytes;

  /// Lowercase hex. It is also the URL's folder, so a URL never changes what
  /// it serves.
  final String sha256;

  /// The model version's folder it is served from.
  final String base;

  const ImageCodecFile(
    this.name,
    this.bytes,
    this.sha256, {
    this.base = kImageCodecBaseUrl,
  });

  String get url => '$base/$sha256/$name';
}

/// Where the `ft8` v1 photo model's LiteRT files live: a `models/` folder in
/// MeshTrax's maps bucket, checked against these hashes when uploaded.
/// Nothing there is ever overwritten; a new version goes to a new path.
const String kImageCodecBaseUrl =
    'https://maps.meshtrax.io/models/ft8/v1-litert';

/// The files the app downloads, 1,165,717,164 bytes in all.
const List<ImageCodecFile> kImageCodecFiles = [
  ImageCodecFile(
    'aeic_decoder_unet_ft8_pt2e.tflite',
    794455600,
    '4d85927a7cdd0777235986d53423a0ea1731adbbca869d5611b5a621e38004a8',
  ),
  ImageCodecFile(
    'aeic_decoder_gs_ft8_pt2e.tflite',
    67994256,
    '21b8d0a26c3bcbfdabb58f37cbb49fd6406431488d042294d0ee1ab52ab7d1b3',
  ),
  ImageCodecFile(
    'aeic_decoder_vae_ft8_f32.tflite',
    52140504,
    '9f87802e46a637e45d6e8ad66d46071590ff18c72ab4f2655b459725201edfe7',
  ),
  ImageCodecFile(
    'aeic_side_ft8.tflite',
    66868776,
    '7d86faf665302cf89f7dfc78aa1ed65d10d4580101e3811b8f19cc6bb5bd9898',
  ),
  ImageCodecFile(
    'aeic_hyper_ft8.tflite',
    7917292,
    '9acdee42e1fbef4897bbdfd877e5acb47b7c188c4fadecef81a0c1a15bdab202',
  ),
  ImageCodecFile(
    'aeic_stage0_ft8.tflite',
    36952400,
    '4f8ac63ebceb904dcda912748167c02a521bb7df533e0b9ff0cff7bc9a054b6f',
  ),
  ImageCodecFile(
    'aeic_stage1_ft8.tflite',
    36952400,
    'b65d49c2ca6d2d18f1bfaba2b15ec767a438f87e9ccf2297ada21a2ea82ef238',
  ),
  ImageCodecFile(
    'aeic_stage2_ft8.tflite',
    36952400,
    '4cb12da3059e56c4077f10e725eb8b0c39a6cd2efab67ae0667e7fc450515435',
  ),
  ImageCodecFile(
    'aeic_stage3_ft8.tflite',
    36952400,
    'a68efd09e17b6894a9798b668b2f3cc1e7084a137327dbfe0bf942b75ff1b2a9',
  ),
  ImageCodecFile(
    'aeic_cdf_ft8.bin',
    813648,
    '7b5798a9a55023389ba7518b5bef9a80cb07bb257f90fe98d8f445b796a62fa0',
  ),
  ImageCodecFile(
    'image-safety-classifier-s.tflite',
    22794792,
    '793d7d7685ff3a887471f462e4e044d53d734c42156f5d4f38cd32b097e55a45',
  ),
  ImageCodecFile(
    'realesr-general-x4v3-dn05.tflite',
    4922696,
    'fa307f6783051a68d834b54c963ecb06fedb9d580c200d3154bc69697715a576',
  ),
];

/// The NOTICE (which says how the files were made) and licences served
/// beside the model, as its licences require. The Stability AI licence also
/// needs "Powered by Stability AI" shown in the app.
const List<ImageCodecFile> kImageCodecLicences = [
  ImageCodecFile(
    'NOTICE.txt',
    3294,
    '48e05f78887b5c612e06e87e9537947128c4c94b4d7013e10aa1a1fad6f76450',
  ),
  ImageCodecFile(
    'LICENSE-StabilityAI-Community.md',
    11852,
    'd6f6b1a4dce5c852bd6d7d9482d002baf0ccdb71e662250b73be9eec8764ee8d',
  ),
  ImageCodecFile(
    'LICENSE-AEIC-MIT.txt',
    1068,
    '83ed66e2cf9e4ff9db4bf7e0c5f255d3afb4164e33f430708e01b611ab8ebad5',
  ),
  ImageCodecFile(
    'LICENSE-AdcSR-Apache-2.0.txt',
    11357,
    'c71d239df91726fc519c6eb72d318ec65820627232b2f796219e87dcf35d0ab4',
  ),
  ImageCodecFile(
    'LICENSE-image-safety-classifier-MIT.txt',
    1056,
    '974725c4c00d30a75dad1883552348f5b264f73de6945dbd7540ffe60e84ac2a',
  ),
  ImageCodecFile(
    'LICENSE-SwiftFormer-Apache-2.0.txt',
    11330,
    '06f726d93a7dfe8d712608d54d8849fed18b5a2ef6bf6243d9811a4c671ab5a5',
  ),
  ImageCodecFile(
    'LICENSE-Real-ESRGAN-BSD-3-Clause.txt',
    1519,
    '4a699ec4863d96a91fc265948a0c90033f7e8735d515524dcf3444736406e0c2',
  ),
];
