// Adapted from meshcore-open lib/services/image_codec_backend.dart (MIT, see
// the repository's LICENSE), commit 3944c4f: the adapter between the
// range coder and the entropy loop.

import 'dart:typed_data';

import 'entropy_tables.dart';
import 'image_codec_entropy.dart';
import 'rans_coder.dart';

/// Adapts the pure-Dart [RansEncoder]/[RansDecoder] to the narrow ports the
/// entropy loop is written against, so the four-stage arithmetic can be
/// tested without either the coder or a model runtime.
class AeicRansCoders implements AeicRansCoderFactory {
  final EntropyTables tables;

  const AeicRansCoders(this.tables);

  @override
  AeicRansEncoder createEncoder() => _RansEncoderPort(RansEncoder(tables));

  @override
  AeicRansDecoder createDecoder(Uint8List bitstream) =>
      _RansDecoderPort(RansDecoder(tables, bitstream));
}

class _RansEncoderPort implements AeicRansEncoder {
  final RansEncoder _encoder;

  _RansEncoderPort(this._encoder);

  @override
  void pushSymbols(Int16List symbols, Int16List indexes, int cdfGroup) =>
      _encoder.encodeWithIndexes(symbols, indexes, cdfGroup);

  @override
  Uint8List finish() => _encoder.finish();
}

class _RansDecoderPort implements AeicRansDecoder {
  final RansDecoder _decoder;

  _RansDecoderPort(this._decoder);

  @override
  Int16List decodeStream(Int16List indexes, int cdfGroup) =>
      _decoder.decodeStream(indexes, cdfGroup);
}
