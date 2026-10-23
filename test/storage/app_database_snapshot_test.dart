import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/models/channel_message.dart';
import 'package:meshtrax/models/message.dart';
import 'package:meshtrax/storage/app_database.dart';
import 'package:meshtrax/storage/channel_message_store.dart';
import 'package:meshtrax/storage/message_store.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The debug "Export message database" action saves a VACUUM INTO copy; a
// replay test opens that copy with useFileForTesting.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const scope = 'deadbeef00cafe';
  const channel = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
  const contact = 'aa11aa11aa11aa11aa11aa11aa11aa11';

  late Directory dir;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    AppDatabase.useInMemoryForTesting();
    dir = await Directory.systemTemp.createTemp('meshtrax_snapshot_');
  });

  tearDown(() async {
    // Windows will not delete a file the copy still holds open.
    await AppDatabase.instance.close();
    AppDatabase.useInMemoryForTesting();
    await dir.delete(recursive: true);
  });

  test('a snapshot holds the same rows and opens as a database', () async {
    final channels = ChannelMessageStore()..setPublicKeyHex = scope;
    final messages = MessageStore()..setPublicKeyHex = scope;
    await channels.saveChannelMessages(channel, [
      ChannelMessage(
        senderKey: null,
        senderName: 'Tester',
        text: 'hello 👋',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1753000000000),
        isOutgoing: false,
        status: ChannelMessageStatus.sent,
        channelIndex: 0,
        messageId: 'c1',
        reactions: const {'👍': 2},
        reactionSenders: const {
          '👍': ['A', 'B'],
        },
      ),
    ]);
    await messages.saveMessages(contact, [
      Message(
        senderKey: Uint8List.fromList(List.filled(32, 7)),
        text: 'hi',
        timestamp: DateTime.fromMillisecondsSinceEpoch(1753000001000),
        isOutgoing: true,
        status: MessageStatus.delivered,
        messageId: 'd1',
      ),
    ]);
    final channelBefore = await channels.loadChannelMessages(channel);
    final dmBefore = await messages.loadMessages(contact);

    final path = '${dir.path}${Platform.pathSeparator}copy.sqlite';
    await AppDatabase.instance.snapshotTo(path);
    expect(File(path).lengthSync(), greaterThan(0));

    AppDatabase.useFileForTesting(path);
    final channelAfter = await channels.loadChannelMessages(channel);
    final dmAfter = await messages.loadMessages(contact);
    expect(channelAfter.single.messageId, channelBefore.single.messageId);
    expect(channelAfter.single.text, 'hello 👋');
    expect(channelAfter.single.reactions, {'👍': 2});
    expect(channelAfter.single.reactionSenders, {
      '👍': ['A', 'B'],
    });
    expect(dmAfter.single.messageId, dmBefore.single.messageId);
    expect(dmAfter.single.status, MessageStatus.delivered);
  });
}
