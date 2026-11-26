import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/services/app_debug_log_service.dart';
import 'package:meshtrax/storage/app_debug_log_store.dart';

void main() {
  late Directory dir;
  final stores = <AppDebugLogStore>[];

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('debug_log_test');
  });

  tearDown(() async {
    for (final store in stores) {
      await store.flush();
    }
    stores.clear();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  /// One run of the app with the log on, and its store to wait for writes.
  (AppDebugLogService, AppDebugLogStore) run({int maxLines = 100}) {
    final store = AppDebugLogStore(dir, maxLines: maxLines);
    stores.add(store);
    return (AppDebugLogService(store: store)..setEnabled(true), store);
  }

  /// What the log shows, without the line each run starts under.
  List<String> shown(AppDebugLogService log) => [
    for (final e in log.entries)
      if (!e.message.endsWith(' started')) e.message,
  ];

  test('the lines of the run before are back, oldest first', () async {
    final (first, firstStore) = run();
    first
      ..info('one', tag: 'Retry')
      ..warn('two\nlines, "quoted" ∆🍓', tag: 'Pathfinder')
      ..error('three');
    await firstStore.flush();

    final (second, _) = run();
    await second.restore();

    final back = second.entries.take(3).toList();
    expect(
      [for (final e in back) e.message],
      ['one', 'two\nlines, "quoted" ∆🍓', 'three'],
    );
    expect([for (final e in back) e.tag], ['Retry', 'Pathfinder', 'App']);
    expect([for (final e in back) e.level], AppDebugLogLevel.values);
    expect(
      back.first.timestamp.millisecondsSinceEpoch,
      first.entries.first.timestamp.millisecondsSinceEpoch,
    );
  });

  test('each run starts under a line naming its build', () async {
    final started = matches(r'^MeshTrax .+ started$');
    final (first, firstStore) = run();
    await first.restore();
    first.info('a');
    await firstStore.flush();

    final (second, _) = run();
    await second.restore();

    expect([for (final e in second.entries) e.message], [started, 'a', started]);
  });

  test('lines logged while the files are read come after the earlier ones',
      () async {
    final (first, firstStore) = run();
    first
      ..info('a')
      ..info('b');
    await firstStore.flush();

    final (second, secondStore) = run();
    final restoring = second.restore();
    second.info('c');
    await restoring;
    expect(shown(second), ['a', 'b', 'c']);

    await secondStore.flush();
    final (third, _) = run();
    await third.restore();
    expect(shown(third), ['a', 'b', 'c']);
  });

  test('the files keep the newest lines, and twice the limit at most',
      () async {
    final (first, firstStore) = run(maxLines: 5);
    for (var i = 1; i <= 12; i++) {
      first.info('line $i');
      if (i.isEven) await firstStore.flush();
    }

    final onDisk = [
      for (final file in dir.listSync().whereType<File>())
        ...file.readAsLinesSync().where((line) => line.isNotEmpty),
    ];
    expect(onDisk.length, inInclusiveRange(5, 10));

    final (second, _) = run(maxLines: 5);
    await second.restore();
    expect(shown(second), [for (var i = 8; i <= 12; i++) 'line $i']);
  });

  test('a line cut short by a stop of the app costs only itself', () async {
    final (first, firstStore) = run();
    first.info('kept');
    await firstStore.flush();
    // The app stopped in the middle of a line, and of a character.
    File('${dir.path}/app.log').writeAsBytesSync([
      ...utf8.encode('\n{"t":17641,"m":"cut'),
      0xF0,
      0x9F,
    ], mode: FileMode.append);

    // The next line written lands right behind the cut one.
    final (second, secondStore) = run();
    second.info('after');
    await secondStore.flush();

    final (third, _) = run();
    await third.restore();
    expect(shown(third), ['kept', 'after']);
  });

  test('Clear log empties the files as well', () async {
    final (first, firstStore) = run();
    first.info('gone');
    await firstStore.flush();

    first.clear();
    await firstStore.flush();
    expect(dir.existsSync(), isFalse);

    final (second, _) = run();
    await second.restore();
    expect(shown(second), isEmpty);
  });

  test('a clear while the files are read does not bring the lines back',
      () async {
    final (first, firstStore) = run();
    first.info('gone');
    await firstStore.flush();

    final (second, _) = run();
    final restoring = second.restore();
    second.clear();
    await restoring;

    expect(shown(second), isEmpty);
  });

  test('nothing is kept while the log is off', () async {
    final store = AppDebugLogStore(dir);
    AppDebugLogService(store: store).info('unseen');
    await store.flush();

    expect(dir.listSync(), isEmpty);
  });

  test('a folder that cannot be written costs the lines, not the app',
      () async {
    final blocker = File('${dir.path}/blocker')..writeAsStringSync('x');
    final store = AppDebugLogStore(Directory('${blocker.path}/log'));
    final log = AppDebugLogService(store: store)..setEnabled(true);

    await log.restore();
    log.info('still shown');
    await store.flush();

    expect(log.entries.last.message, 'still shown');
  });
}
