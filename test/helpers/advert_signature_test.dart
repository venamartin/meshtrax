import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/advert_signature.dart';
import 'package:pinenacl/ed25519.dart';

Uint8List _signedAdvert(
  SigningKey key,
  Uint8List appData, {
  int time = 1763400000,
}) {
  final pubKey = key.verifyKey.asTypedList;
  final timestamp = Uint8List(4)
    ..buffer.asByteData().setUint32(0, time, Endian.little);
  final signed = key.sign(
    Uint8List.fromList([...pubKey, ...timestamp, ...appData]),
  );
  return Uint8List.fromList([
    ...pubKey,
    ...timestamp,
    ...signed.signature.asTypedList,
    ...appData,
  ]);
}

void main() {
  final key = SigningKey.generate();
  // Flags 0x81 (chat node, has name) and a name.
  final appData = Uint8List.fromList([0x81, ...'Alice'.codeUnits]);

  test('a signed advert is valid', () {
    expect(advertSignatureValid(_signedAdvert(key, appData)), isTrue);
  });

  test('a changed name, time or key is forged', () {
    final advert = _signedAdvert(key, appData);
    final renamed = Uint8List.fromList(advert)..[advert.length - 1] ^= 1;
    final retimed = Uint8List.fromList(advert)..[32] ^= 1;
    final rekeyed = Uint8List.fromList(advert)
      ..setRange(0, 32, SigningKey.generate().verifyKey.asTypedList);
    expect(advertSignatureValid(renamed), isFalse);
    expect(advertSignatureValid(retimed), isFalse);
    expect(advertSignatureValid(rekeyed), isFalse);
  });

  test('a short or junk payload is not valid', () {
    expect(advertSignatureValid(Uint8List(99)), isFalse);
    expect(advertSignatureValid(Uint8List(120)), isFalse);
  });

  test(
    'only the first 32 bytes of app data are signed, as in the firmware',
    () {
      final long = Uint8List.fromList(List.generate(32, (i) => i + 1));
      final advert = _signedAdvert(key, long);
      expect(
        advertSignatureValid(Uint8List.fromList([...advert, 0xAA, 0xBB])),
        isTrue,
      );
    },
  );

  test('a remembered answer does not cover changed data', () {
    final advert = _signedAdvert(key, appData);
    expect(advertSignatureValid(advert), isTrue);
    final renamed = Uint8List.fromList(advert)..[advert.length - 1] ^= 1;
    expect(advertSignatureValid(renamed), isFalse);
    expect(advertSignatureValid(advert), isTrue);
  });
}
