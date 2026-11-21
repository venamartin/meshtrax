import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/models/repeater_regions.dart';
import 'package:meshtrax/screens/repeater_regions_screen.dart';
import 'package:meshtrax/services/repeater_regions_controller.dart';

class _Region {
  _Region(this.name, this.parent, {this.repeats = true});
  final String name;
  String? parent;
  bool repeats;
}

/// Answers `region` commands as MeshCore's CommonCLI::handleRegionCmd and
/// RegionMap do, replies cut at 159 characters.
class _FakeRepeater {
  final regions = <_Region>[];
  bool noRegionRepeats = true;
  String? own;
  bool tooOld = false;
  bool silent = false;
  final sent = <String>[];

  static String _cut(String s) => s.length > 159 ? s.substring(0, 159) : s;

  _Region? _byPrefix(String p) {
    for (final r in regions) {
      if (r.name == p) return r;
    }
    for (final r in regions.reversed) {
      if (r.name.startsWith(p)) return r;
    }
    return null;
  }

  void _tree(StringBuffer out, String? parent, int depth) {
    for (final r in regions.where((r) => r.parent == parent)) {
      out.write('${' ' * depth}${r.name}${r.repeats ? ' F' : ''}\n');
      _tree(out, r.name, depth + 1);
    }
  }

  String _list(bool allowed) {
    final out = <String>[];
    var len = 0;
    if (noRegionRepeats == allowed) {
      out.add('*');
      len = 2;
    }
    for (final r in regions.where((r) => r.repeats == allowed)) {
      if (len + r.name.length + 2 < 160) {
        out.add(r.name);
        len += r.name.length + 1;
      }
    }
    return out.isEmpty ? '-none-' : out.join(',');
  }

  Future<String> call(String command) async {
    sent.add(command);
    if (silent) throw TimeoutException('no reply');
    final p = command.split(' ');
    if (command == 'region') {
      final out = StringBuffer('*^${noRegionRepeats ? ' F' : ''}\n');
      _tree(out, null, 1);
      return _cut(out.toString());
    }
    switch (p[1]) {
      case 'list':
        return tooOld ? 'Err - ??' : _list(p[2] == 'allowed');
      case 'save':
        return 'OK';
      case 'default':
        if (p.length == 2) return ' default scope is ${own ?? '<null>'}';
        if (p[2] == '<null>') {
          own = null;
          return ' default scope is now <null>';
        }
        final r = _byPrefix(p[2]) ?? (regions..add(_Region(p[2], null))).last;
        r.repeats = true;
        own = r.name;
        return ' default scope is now ${r.name}';
      case 'allowf' || 'denyf':
        final on = p[1] == 'allowf';
        if (p[2] == '*') {
          noRegionRepeats = on;
          return 'OK';
        }
        final r = _byPrefix(p[2]);
        if (r == null) return 'Err - unknown region';
        r.repeats = on;
        return 'OK';
      case 'put':
        // A full table: putRegion returns NULL.
        if (p[2] == 'full') return 'Err - unable to put';
        String? parent;
        if (p.length >= 4 && p[3] != '*') {
          final found = _byPrefix(p[3]);
          if (found == null) return 'Err - unknown parent';
          parent = found.name;
        }
        final existing = regions.where((r) => r.name == p[2]).firstOrNull;
        if (existing != null) {
          if (parent == existing.name) return 'Err - unable to put';
          existing
            ..parent = parent
            ..repeats = true;
        } else {
          regions.add(_Region(p[2], parent));
        }
        return 'OK - (flood allowed)';
      case 'remove':
        final r = regions.where((r) => r.name == p[2]).firstOrNull;
        if (r == null) return 'Err - not found';
        if (regions.any((c) => c.parent == r.name)) return 'Err - not empty';
        regions.remove(r);
        return 'OK';
    }
    return 'Err - ??';
  }
}

List<String> _names(RepeaterRegionsController c) =>
    [for (final r in c.regions.regions) r.name];

RepeaterRegion _region(RepeaterRegionsController c, String name) =>
    c.regions.regions.singleWhere((r) => r.name == name);

void main() {
  group('reading the firmware listing', () {
    test('nests by indent, F marks repeated, ^ and # are dropped', () {
      final regions = RepeaterRegions.parse(
        tree: '*^ F\n bayarea F\n  sf\n  #marin F\n la F\n',
        allowed: '*,bayarea,marin,la',
      );
      expect(regions.noRegionRepeats, isTrue);
      expect([for (final r in regions.regions) r.name],
          ['bayarea', 'sf', 'marin', 'la']);
      final sf = regions.regions[1];
      expect(sf.parent, 'bayarea');
      expect(sf.depth, 1);
      expect(sf.repeats, isFalse);
      expect(regions.regions.last.parent, isNull);
      expect(regions.mayBeIncomplete, isFalse);
    });

    test('no region refused: * without F', () {
      final regions = RepeaterRegions.parse(tree: '*^\n sf F\n', allowed: 'sf');
      expect(regions.noRegionRepeats, isFalse);
    });

    test('a cut listing is filled in from the name lists', () {
      final tree = '*^ F\n${[
        for (var i = 0; i < 20; i++) ' region$i F\n',
      ].join()}';
      final regions = RepeaterRegions.parse(
        tree: tree.substring(0, 159),
        allowed: '*,${[for (var i = 0; i < 20; i++) 'region$i'].join(',')}',
        denied: 'quiet',
      );
      expect(regions.regions, hasLength(21));
      expect(regions.regions.last.name, 'quiet');
      expect(regions.regions.last.repeats, isFalse);
      expect(regions.mayBeIncomplete, isTrue,
          reason: 'the allowed list is as long as a cut reply');
    });


    test('the default and the error replies', () {
      expect(RepeaterRegions.parseDefault(' default scope is <null>'), isNull);
      expect(RepeaterRegions.parseDefault(' default scope is #sf'), 'sf');
      expect(RepeaterRegions.parseNameList('-none-'), isEmpty);
      for (final err in ['Err - ??', 'Unknown command', '??']) {
        expect(RepeaterRegions.isError(err), isTrue, reason: err);
      }
      expect(RepeaterRegions.isError('OK - (flood allowed)'), isFalse);
    });
  });

  group('the controller against a repeater', () {
    late _FakeRepeater repeater;
    late RepeaterRegionsController c;

    setUp(() {
      repeater = _FakeRepeater()
        ..regions.addAll([
          _Region('bayarea', null),
          _Region('sf', 'bayarea', repeats: false),
          _Region('la', null),
        ])
        ..own = 'bayarea';
      c = RepeaterRegionsController(repeater.call);
    });

    test('reads regions, repeats and its own region', () async {
      await c.load();
      expect(c.status, RepeaterRegionsStatus.ready);
      expect(_names(c), ['bayarea', 'sf', 'la']);
      expect(_region(c, 'sf').repeats, isFalse);
      expect(c.ownRegion, 'bayarea');
      expect(repeater.sent, ['region list allowed', 'region', 'region default']);
    });

    test('a repeater too old for region lists', () async {
      repeater.tooOld = true;
      await c.load();
      expect(c.status, RepeaterRegionsStatus.tooOld);
    });

    test('no answer', () async {
      repeater.silent = true;
      await c.load();
      expect(c.status, RepeaterRegionsStatus.noAnswer);
    });

    test('a switch sends allowf or denyf, then saves', () async {
      await c.load();
      repeater.sent.clear();
      expect(await c.setRepeats('sf', true), isTrue);
      expect(repeater.sent, ['region allowf sf', 'region save']);
      expect(_region(c, 'sf').repeats, isTrue);
      expect(await c.setRepeats(null, false), isTrue);
      expect(repeater.noRegionRepeats, isFalse);
      expect(c.regions.noRegionRepeats, isFalse);
    });

    test('several regions added under a parent, saved once', () async {
      await c.load();
      repeater.sent.clear();
      expect(await c.add(['marin', '#oakland'], 'bayarea'), isTrue);
      expect(repeater.sent.take(3), [
        'region put marin bayarea',
        'region put oakland bayarea',
        'region save',
      ]);
      expect(_region(c, 'marin').parent, 'bayarea');
      expect(_region(c, 'oakland').repeats, isTrue);
    });

    test('moving a region keeps it off when it was off', () async {
      await c.load();
      repeater.sent.clear();
      expect(await c.move('sf', null), isTrue);
      expect(repeater.sent.take(3),
          ['region put sf *', 'region denyf sf', 'region save']);
      expect(_region(c, 'sf').parent, isNull);
      expect(_region(c, 'sf').repeats, isFalse);
    });

    test('regions under a region are not offered as its new parent', () async {
      await c.load();
      expect(c.descendantsOf('bayarea'), {'sf'});
      expect(c.hasChildren('bayarea'), isTrue);
    });

    test('removing a region with regions under it is refused', () async {
      await c.load();
      repeater.sent.clear();
      expect(await c.remove('bayarea'), isFalse);
      expect(c.problem, RepeaterRegionsProblem.hasChildren);
      expect(repeater.sent.first, 'region remove bayarea');
      expect(repeater.sent, isNot(contains('region save')));
      expect(_names(c), contains('bayarea'));
    });

    test('a refusal partway still saves what went through', () async {
      await c.load();
      repeater.sent.clear();
      expect(await c.add(['marin', 'full', 'oakland'], null), isFalse);
      expect(c.problem, RepeaterRegionsProblem.refused);
      expect(c.refusal, 'Err - unable to put');
      expect(repeater.sent.take(3),
          ['region put marin', 'region put full', 'region save']);
      expect(_names(c), contains('marin'));
      expect(_names(c), isNot(contains('oakland')));
    });

    test('nothing went through: nothing to save', () async {
      await c.load();
      repeater.sent.clear();
      expect(await c.add(['marin'], 'nowhere'), isFalse);
      expect(c.refusal, 'Err - unknown parent');
      expect(repeater.sent, isNot(contains('region save')));
    });


    test('its own region is set without a separate save', () async {
      await c.load();
      repeater.sent.clear();
      expect(await c.setOwnRegion('la'), isTrue);
      expect(repeater.sent.first, 'region default la');
      expect(repeater.sent, isNot(contains('region save')));
      expect(c.ownRegion, 'la');
      expect(await c.setOwnRegion(null), isTrue);
      expect(c.ownRegion, isNull);
    });
  });

  group('the screen', () {
    late _FakeRepeater repeater;
    late RepeaterRegionsController c;
    final contact = Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => i)),
      name: 'Hilltop',
      type: advTypeRepeater,
      pathLength: 0,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime.now(),
    );

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: RepeaterRegionsScreen(repeater: contact, controller: c),
        ),
      );
      await tester.pumpAndSettle();
    }

    setUp(() {
      repeater = _FakeRepeater()
        ..regions.addAll([
          _Region('bayarea', null),
          _Region('sf', 'bayarea', repeats: false),
        ]);
      c = RepeaterRegionsController(repeater.call);
    });

    testWidgets('lists the regions under their parents', (tester) async {
      await open(tester);
      expect(find.text('Hilltop'), findsOneWidget);
      expect(find.text('Repeat messages with no region'), findsOneWidget);
      expect(find.text('bayarea'), findsOneWidget);
      expect(find.text('Not repeated'), findsOneWidget);
      double indent(String name) => tester.getTopLeft(find.text(name)).dx;

      expect(indent('sf'), greaterThan(indent('bayarea')));
    });

    testWidgets('turning off messages with no region asks first',
        (tester) async {
      await open(tester);
      await tester.tap(find.widgetWithText(
          SwitchListTile, 'Repeat messages with no region'));
      await tester.pumpAndSettle();
      expect(find.text('Stop repeating messages with no region?'),
          findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(repeater.noRegionRepeats, isTrue);

      await tester.tap(find.widgetWithText(
          SwitchListTile, 'Repeat messages with no region'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Turn off'));
      await tester.pumpAndSettle();
      expect(repeater.noRegionRepeats, isFalse);
    });

    testWidgets('add a region from the dialog', (tester) async {
      await open(tester);
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'bayarea');
      await tester.pump();
      expect(find.text('Already on this repeater.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'marin');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Add'));
      await tester.pumpAndSettle();
      expect(repeater.regions.map((r) => r.name), contains('marin'));
      expect(find.text('marin'), findsOneWidget);
    });

    testWidgets('a repeater too old says so', (tester) async {
      repeater.tooOld = true;
      await open(tester);
      expect(find.textContaining('1.15 or newer'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });
  });
}
