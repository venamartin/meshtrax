import 'package:pinenacl/ed25519.dart';

const int _pubKeySize = 32;
const int _timestampSize = 4;
const int _signatureSize = 64;
const int _signatureEnd = _pubKeySize + _timestampSize + _signatureSize;
// MeshCore.h MAX_ADVERT_DATA_SIZE: the firmware signs and checks only this
// much app data.
const int _maxAdvertDataSize = 32;

// One advert is heard once per repeater that passes it on, and a check costs
// a few milliseconds, so recent answers are kept. Keyed by the whole payload,
// so a real signature on changed data still fails.
const int _recentMax = 256;
final Map<String, bool> _recent = {};

/// Whether an advert [payload] (key, timestamp, signature, app data) carries
/// a valid Ed25519 signature, checked the way the firmware's
/// Mesh::onRecvPacket does. The radio logs every packet it hears before that
/// check, so adverts read from the RX log can be forged.
bool advertSignatureValid(Uint8List payload) {
  if (payload.length < _signatureEnd) return false;
  final key = String.fromCharCodes(payload);
  final valid = _recent.remove(key) ?? _check(payload);
  _recent[key] = valid;
  if (_recent.length > _recentMax) _recent.remove(_recent.keys.first);
  return valid;
}

bool _check(Uint8List payload) {
  final appDataEnd = payload.length > _signatureEnd + _maxAdvertDataSize
      ? _signatureEnd + _maxAdvertDataSize
      : payload.length;
  final message = Uint8List.fromList([
    ...payload.sublist(0, _pubKeySize + _timestampSize),
    ...payload.sublist(_signatureEnd, appDataEnd),
  ]);
  try {
    return VerifyKey(payload.sublist(0, _pubKeySize)).verify(
      signature: Signature(
        payload.sublist(_pubKeySize + _timestampSize, _signatureEnd),
      ),
      message: message,
    );
  } catch (_) {
    return false;
  }
}
