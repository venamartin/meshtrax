import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/repeater_cli_screen.dart';
import 'package:meshtrax/widgets/cli_console.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));

  List<String> quick({required bool room}) => [
    for (final c in repeaterCliQuickCommands(en, room: room)) c.command,
  ];

  List<CliHelpEntry> help({required bool room}) => [
    for (final s in repeaterCliHelpSections(en, room: room)) ...s.entries,
  ];

  List<String> commands({required bool room}) => [
    for (final e in help(room: room)) e.command,
  ];

  test('a repeater has Repeat On and Repeat Off first', () {
    expect(quick(room: false).take(2), ['set repeat on', 'set repeat off']);
    expect(quick(room: false), containsAll(['discover.neighbors', 'neighbors']));
  });

  test('a room has no quick command it answers with an error', () {
    // "ERR - repeat now deprecated", "Unknown command" and "not supported".
    for (final refused in [
      'set repeat on',
      'set repeat off',
      'discover.neighbors',
      'neighbors',
    ]) {
      expect(quick(room: true), isNot(contains(refused)));
    }
    expect(quick(room: true), contains('clock sync'));
  });

  test("a repeater's help has its own commands and not a room's", () {
    expect(
      commands(room: false),
      containsAll([
        'set repeat {on|off}',
        'discover.neighbors',
        'clock sync',
        'power',
        'set loop.detect {off|minimal|moderate|strict}',
      ]),
    );
    expect(commands(room: false), isNot(contains('room.post {message}')));
    expect(
      commands(room: false),
      isNot(contains('set allow.read.only {on|off}')),
    );
  });

  test("a room's help has room.post and nothing about passing packets on", () {
    expect(
      commands(room: true),
      containsAll(['room.post {message}', 'set allow.read.only {on|off}']),
    );
    for (final repeaterOnly in [
      'set repeat {on|off}',
      'neighbors',
      'discover.neighbors',
      'set flood.max {max-hops}',
    ]) {
      expect(commands(room: true), isNot(contains(repeaterOnly)));
    }
  });

  test('every setting offers the get that reads it back', () {
    for (final room in [false, true]) {
      for (final e in help(room: room)) {
        if (!e.command.startsWith('set ')) continue;
        final name = e.command.split(' ')[1];
        // The firmware reads the private key back only over USB.
        expect(
          e.getCommand,
          name == 'prv.key' ? isNull : 'get $name',
          reason: e.command,
        );
      }
    }
  });

  test('no command is listed twice', () {
    for (final room in [false, true]) {
      final all = commands(room: room);
      expect(all.toSet().length, all.length);
    }
  });
}
