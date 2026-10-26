import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/services/ui_view_state_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<UiViewStateService> fresh() async {
    final s = UiViewStateService();
    await s.initialize();
    return s;
  }

  test('a draft left in a chat is there after a restart', () async {
    final s = await fresh();
    s.setDraft('chat-a', 'half a thou');
    s.flushDrafts();
    await Future<void>.delayed(Duration.zero);

    final restarted = await fresh();
    expect(restarted.draft('chat-a'), 'half a thou');
    expect(restarted.draft('chat-b'), '');
  });

  test('blank text clears the draft', () async {
    final s = await fresh();
    s.setDraft('chat-a', 'something');
    s.setDraft('chat-a', '   ');
    s.flushDrafts();
    expect(s.draft('chat-a'), '');
    expect(s.drafts, isEmpty);
  });

  test('typing saves quietly; leaving tells the chats list once', () {
    fakeAsync((async) {
      late UiViewStateService s;
      fresh().then((v) => s = v);
      async.flushMicrotasks();
      var notified = 0;
      s.addListener(() => notified++);

      s.setDraft('chat-a', 'h');
      s.setDraft('chat-a', 'he');
      s.setDraft('chat-a', 'hel');
      async.elapse(const Duration(seconds: 2));
      expect(notified, 0, reason: 'bubbles watch this service');
      expect(PrefsManager.instance.getString('ui_drafts'), contains('hel'));

      s.flushDrafts();
      async.flushMicrotasks();
      expect(notified, 1);
    });
  });

  test('a second screen sending the draft is not undone by the first closing',
      () async {
    final s = await fresh();
    // Screen A, typing.
    s.setDraft('bob', 'running late, b');
    // Screen B on the same chat (a notification tap) finishes and sends.
    s.setDraft('bob', '');
    s.flushDrafts(); // B closes
    s.flushDrafts(); // then A, which wrote nothing new
    expect(s.draft('bob'), '');
  });
}
