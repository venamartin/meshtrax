import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show Locale;
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/services/photo_mesh.dart';
import 'package:meshtrax/services/photo_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxpix/traxpix.dart';

ImageReassemblyFailure failure({
  int got = 2,
  int total = 4,
  bool parity = true,
  ImageReassemblyFailureReason reason = ImageReassemblyFailureReason.expired,
}) => ImageReassemblyFailure(
  key: const ImageStreamKey(senderPrefix: 0xa1b2, imgId: 0x3a, channelIndex: 1),
  total: total,
  receivedDataChunks: got,
  hadParity: parity,
  firstSeen: DateTime(2026, 11, 20, 12),
  expiredAt: DateTime(2026, 11, 20, 12, 1),
  reason: reason,
);

final en = lookupAppLocalizations(const Locale('en'));
final de = lookupAppLocalizations(const Locale('de'));

ChannelMessage message(String text, String? packetHash) => ChannelMessage(
  senderName: 'Alex',
  text: text,
  timestamp: DateTime(2026, 11, 20, 12),
  isOutgoing: false,
  status: ChannelMessageStatus.sent,
  channelIndex: 1,
  packetHash: packetHash,
);

void main() {
  group('an incomplete photo in the chat', () {
    test('counts packets as the sender does, repair packet included', () {
      expect(
        PhotoMesh.incompleteText(en, failure()),
        '📷 Photo #3a incomplete: 3 of 5 packets',
      );
      expect(
        PhotoMesh.incompleteText(en, failure(got: 1, parity: false)),
        '📷 Photo #3a incomplete: 1 of 5 packets',
      );
    });

    test('says when every packet came but the photo can\'t be read', () {
      expect(
        PhotoMesh.incompleteText(
          en,
          failure(
            got: 4,
            reason: ImageReassemblyFailureReason.unsupportedFormat,
          ),
        ),
        '📷 Photo #3a couldn\'t be read',
      );
    });

    test('is plain text, not a photo card', () {
      final text = PhotoMesh.incompleteText(en, failure());
      expect(
        PhotoMesh.isPhotoMessage(message(text, 'photo-incomplete:a1b2:58:1')),
        isFalse,
      );
    });
  });

  group('a photo in the chat', () {
    test('is known by its packet hash, in any language', () {
      expect(
        PhotoMesh.isPhotoMessage(message('📷 Foto #3a', 'photo:a1b2:58:1')),
        isTrue,
      );
      expect(
        PhotoMesh.isPhotoMessage(message('📷 Photo #3a', 'photo:own:58:1')),
        isTrue,
      );
      expect(PhotoMesh.isPhotoMessage(message('📷 Photo #3a', null)), isFalse);
      expect(
        PhotoMesh.isPhotoMessage(message('📷 Photo #3a', 'ab12cd')),
        isFalse,
      );
    });

    test('a photo keeps its tag exactly as the sender typed it', () {
      final record = PhotoRecord(
        messageId: 'm1',
        bytes: 400,
        packets: 4,
        outgoing: false,
        tag: 'Road washed out',
      );
      expect(PhotoRecord.fromJson(record.toJson()).tag, 'Road washed out');
      expect(
        PhotoRecord.fromJson(
          PhotoRecord(
            messageId: 'm2',
            bytes: 400,
            packets: 4,
            outgoing: true,
          ).toJson(),
        ).tag,
        isNull,
      );
    });
  });

  group('rebuild received photos automatically', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      PrefsManager.reset();
      await PrefsManager.initialize();
    });

    test('is off until turned on, then remembered', () async {
      expect(PhotoStore.instance.rebuildAutomatically, isFalse);
      PhotoStore.instance.rebuildAutomatically = true;
      expect(PhotoStore.instance.rebuildAutomatically, isTrue);
      expect(
        PrefsManager.instance.getBool('photo_rebuild_automatically'),
        isTrue,
      );
      PhotoStore.instance.rebuildAutomatically = false;
    });
  });

  test(
    'the picture cache drops its oldest pictures first, down to the cap',
    () {
      final dir = Directory.systemTemp.createTempSync('photocache');
      addTearDown(() => dir.deleteSync(recursive: true));
      final start = DateTime(2026, 11, 20, 12);
      for (var i = 0; i < 5; i++) {
        File('${dir.path}/$i.png')
          ..writeAsBytesSync(List.filled(100, 0))
          ..setLastModifiedSync(start.add(Duration(minutes: i)));
      }
      trimPictureCache(dir, cap: 300);
      final left = dir.listSync().map((e) => e.uri.pathSegments.last).toSet();
      expect(left, {'2.png', '3.png', '4.png'});
      trimPictureCache(dir, cap: 300);
      expect(dir.listSync(), hasLength(3));
    },
  );
}
