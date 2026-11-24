import 'dart:convert';
import 'dart:typed_data';

import 'image_safety.dart';

/// One photo in the Mac's `ref.txt` for the phone test, tab-separated: the
/// name, the bitstream the Mac coded (base64, `-` when flagged), the hash of
/// the latent the Mac decoded from it, and the Mac's safety scores.
class ReferencePhoto {
  final String name;
  final Uint8List? bitstream;
  final String? latentHash;
  final ImageSafetyScores scores;

  const ReferencePhoto(this.name, this.bitstream, this.latentHash, this.scores);

  factory ReferencePhoto.parse(String line) {
    final f = line.split('\t');
    if (f.length != 6) throw FormatException('bad ref.txt line', line);
    return ReferencePhoto(
      f[0],
      f[1] == '-' ? null : base64.decode(f[1]),
      f[2] == '-' ? null : f[2],
      ImageSafetyScores(
        nsfl: double.parse(f[3]),
        nsfw: double.parse(f[4]),
        sfw: double.parse(f[5]),
      ),
    );
  }
}

String referenceLine(
  String name,
  Uint8List? bitstream,
  Float32List? latent,
  ImageSafetyScores scores,
) => [
  name,
  bitstream == null ? '-' : base64.encode(bitstream),
  latent == null ? '-' : latentHash(latent),
  scores.nsfl.toStringAsExponential(9),
  scores.nsfw.toStringAsExponential(9),
  scores.sfw.toStringAsExponential(9),
].join('\t');

/// FNV-1a 64 over the latent's bytes: equal on two devices only if every
/// float is bit-identical.
String latentHash(Float32List latent) {
  var h = -3750763034362895579; // 0xcbf29ce484222325
  for (final b in latent.buffer.asUint8List(
    latent.offsetInBytes,
    latent.lengthInBytes,
  )) {
    h = (h ^ b) * 1099511628211;
  }
  return h.toUnsigned(64).toRadixString(16).padLeft(16, '0');
}
