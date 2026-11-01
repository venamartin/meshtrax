import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/health/health_check.dart';
import 'package:meshtrax/health/health_rules.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/screens/health_check_screen.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';

class _Radio extends MeshCoreConnector {
  _Radio(this.connected);
  bool connected;

  @override
  bool get isConnected => connected;

  @override
  Future<void> refreshDeviceInfoAndWait({
    Duration timeout = const Duration(seconds: 5),
  }) async {}

  @override
  Future<void> sendFrame(
    Uint8List data, {
    String? channelSendQueueId,
    bool expectsGenericAck = false,
  }) async {}
}

HealthRule _rule(
  String id,
  HealthSeverity severity, {
  bool finding = true,
  bool needsRadio = false,
  HealthFix? fix,
  Future<void> Function(HealthContext)? apply,
  HealthDialog? dialog,
  bool canFix = true,
  List<String> details = const [],
}) => HealthRule(
  id: id,
  enabled: true,
  severity: severity,
  title: 'title $id',
  why: 'why $id',
  needsRadio: needsRadio,
  check: (_) async => finding,
  fix: fix,
  apply: apply,
  fixDescription: 'does $id',
  dialog: dialog,
  canFix: (_) => canFix,
  details: (_) => details,
);

void main() {
  late AppSettingsService settings;
  late List<HealthDialog> opened;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
    settings = AppSettingsService();
    opened = [];
  });

  Future<void> pump(
    WidgetTester tester,
    List<HealthRule> rules, {
    bool connected = true,
    Size size = const Size(360, 640),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MeshCoreConnector>.value(
            value: _Radio(connected),
          ),
          ChangeNotifierProvider.value(value: settings),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HealthCheckScreen(
            rules: rules,
            openDialog: (context, dialog) async => opened.add(dialog),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('worst findings come first, then the passed count', (
    tester,
  ) async {
    await pump(tester, [
      _rule('tip', HealthSeverity.tip),
      _rule('ok', HealthSeverity.problem, finding: false),
      _rule('sug', HealthSeverity.suggestion),
      _rule('bad', HealthSeverity.problem),
    ], size: const Size(360, 2000));

    double y(String text) => tester.getTopLeft(find.text(text)).dy;
    expect(y('Problems'), lessThan(y('title bad')));
    expect(y('title bad'), lessThan(y('Suggestions')));
    expect(y('title sug'), lessThan(y('Tips')));
    expect(y('title tip'), lessThan(y('Checks passed: 1')));
    expect(find.text('title ok'), findsNothing);
    expect(find.text('why bad'), findsOneWidget);
  });

  testWidgets('nothing found says so', (tester) async {
    await pump(tester, [_rule('ok', HealthSeverity.problem, finding: false)]);
    expect(find.text('Everything looks good.'), findsOneWidget);
    expect(find.text('Problems'), findsNothing);
  });

  testWidgets('with no radio, radio rules are skipped and it says so', (
    tester,
  ) async {
    await pump(tester, [
      _rule('radio', HealthSeverity.problem, needsRadio: true),
      _rule('app', HealthSeverity.suggestion),
    ], connected: false);

    expect(find.textContaining('No radio is connected'), findsOneWidget);
    expect(find.text('title radio'), findsNothing);
    expect(find.text('title app'), findsOneWidget);
    expect(find.text('Checks passed: 0'), findsOneWidget);
  });

  testWidgets('Fix asks first, and Cancel changes nothing', (tester) async {
    var applied = 0;
    await pump(tester, [
      _rule(
        'a',
        HealthSeverity.suggestion,
        fix: HealthFix.apply,
        apply: (_) async => applied++,
      ),
    ]);

    await tester.tap(find.widgetWithText(FilledButton, 'Fix'));
    await tester.pumpAndSettle();
    expect(find.text('does a'), findsOneWidget);
    expect(applied, 0);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(applied, 0);
  });

  testWidgets('a confirmed Fix applies and the finding clears', (tester) async {
    var fixed = false;
    await pump(tester, [
      HealthRule(
        id: 'a',
        enabled: true,
        severity: HealthSeverity.suggestion,
        title: 'title a',
        why: 'why a',
        check: (_) async => !fixed,
        fix: HealthFix.apply,
        fixDescription: 'does a',
        apply: (_) async => fixed = true,
      ),
    ]);

    await tester.tap(find.widgetWithText(FilledButton, 'Fix'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Fix'));
    await tester.pumpAndSettle();

    expect(fixed, isTrue);
    expect(find.text('title a'), findsNothing);
    expect(find.text('Checks passed: 1'), findsOneWidget);
  });

  testWidgets('a Fix that fails says so and keeps the finding', (tester) async {
    await pump(tester, [
      _rule(
        'a',
        HealthSeverity.suggestion,
        fix: HealthFix.apply,
        apply: (_) async => throw Exception('dropped'),
      ),
    ]);

    await tester.tap(find.widgetWithText(FilledButton, 'Fix'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Fix'));
    await tester.pumpAndSettle();

    expect(find.textContaining('did not go through'), findsOneWidget);
    expect(find.text('title a'), findsOneWidget);
  });

  testWidgets('a value the user must supply opens its dialog, no confirm', (
    tester,
  ) async {
    await pump(tester, [
      _rule(
        'a',
        HealthSeverity.problem,
        fix: HealthFix.ask,
        dialog: HealthDialog.name,
      ),
    ]);

    await tester.tap(find.widgetWithText(FilledButton, 'Fix'));
    await tester.pumpAndSettle();

    expect(opened, [HealthDialog.name]);
    expect(find.text('does a'), findsNothing);
  });

  testWidgets('no Fix button when the rule cannot fix it, details still show', (
    tester,
  ) async {
    await pump(tester, [
      _rule(
        'a',
        HealthSeverity.problem,
        fix: HealthFix.apply,
        apply: (_) async {},
        canFix: false,
        details: const ['cannot wind back'],
      ),
      _rule('b', HealthSeverity.suggestion),
    ]);

    expect(find.widgetWithText(FilledButton, 'Fix'), findsNothing);
    expect(find.text('cannot wind back'), findsOneWidget);
  });

  testWidgets('the real rules fit a phone with every finding showing', (
    tester,
  ) async {
    await pump(tester, [
      for (final rule in healthRules.where((r) => r.enabled))
        HealthRule(
          id: rule.id,
          enabled: true,
          severity: rule.severity,
          title: rule.title,
          why: rule.why,
          check: (_) async => true,
          fix: rule.fix,
          dialog: rule.dialog,
          fixDescription: rule.fixDescription,
          apply: rule.apply,
          linkLabel: rule.linkLabel,
          linkUrl: rule.linkUrl,
        ),
    ], size: const Size(360, 12000));
    expect(tester.takeException(), isNull);
    expect(
      find.text(healthRules.firstWhere((r) => r.enabled).title),
      findsOneWidget,
    );
    expect(find.textContaining('Checks passed'), findsOneWidget);
    expect(find.text('Problems'), findsOneWidget);
  });

  testWidgets('a hidden finding stays hidden until shown again', (
    tester,
  ) async {
    await pump(tester, [_rule('a', HealthSeverity.suggestion)]);

    await tester.tap(find.text("Don't show again"));
    await tester.pumpAndSettle();
    expect(find.text('title a'), findsNothing);
    expect(settings.settings.dismissedHealthRules, {'a'});
    expect(find.text('Everything looks good.'), findsOneWidget);
    expect(find.text('Checks passed: 0'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();
    expect(find.text('title a'), findsNothing);

    await tester.tap(find.text('Show hidden findings: 1'));
    await tester.pumpAndSettle();
    expect(find.text('title a'), findsOneWidget);
    expect(settings.settings.dismissedHealthRules, isEmpty);
  });

  testWidgets('a hidden rule that no longer applies is not counted as hidden', (
    tester,
  ) async {
    await settings.dismissHealthRule('a');
    await pump(tester, [_rule('a', HealthSeverity.tip, finding: false)]);
    expect(find.textContaining('Show hidden'), findsNothing);
    expect(find.text('Checks passed: 1'), findsOneWidget);
  });

  testWidgets('Fix all lists the changes once and applies only those', (
    tester,
  ) async {
    final applied = <String>[];
    await pump(tester, [
      _rule(
        'a',
        HealthSeverity.suggestion,
        fix: HealthFix.apply,
        apply: (_) async => applied.add('a'),
      ),
      _rule(
        'b',
        HealthSeverity.tip,
        fix: HealthFix.apply,
        apply: (_) async => applied.add('b'),
      ),
      _rule(
        'typed',
        HealthSeverity.problem,
        fix: HealthFix.ask,
        dialog: HealthDialog.name,
      ),
      _rule(
        'blocked',
        HealthSeverity.problem,
        fix: HealthFix.apply,
        apply: (_) async => applied.add('blocked'),
        canFix: false,
      ),
    ]);

    await tester.tap(find.text('Fix all (2)'));
    await tester.pumpAndSettle();
    expect(find.text('does a'), findsOneWidget);
    expect(find.text('does b'), findsOneWidget);
    expect(find.text('does typed'), findsNothing);
    expect(applied, isEmpty);

    await tester.tap(find.widgetWithText(TextButton, 'Fix all (2)'));
    await tester.pumpAndSettle();
    expect(applied, ['a', 'b']);
    expect(opened, isEmpty);
  });

  testWidgets('Fix all keeps going when one change fails', (tester) async {
    final applied = <String>[];
    await pump(tester, [
      _rule(
        'a',
        HealthSeverity.suggestion,
        fix: HealthFix.apply,
        apply: (_) async => throw Exception('dropped'),
      ),
      _rule(
        'b',
        HealthSeverity.suggestion,
        fix: HealthFix.apply,
        apply: (_) async => applied.add('b'),
      ),
    ]);

    await tester.tap(find.text('Fix all (2)'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Fix all (2)'));
    await tester.pumpAndSettle();

    expect(applied, ['b']);
    expect(find.textContaining('did not go through'), findsOneWidget);
  });

  testWidgets('one fixable finding offers no Fix all', (tester) async {
    await pump(tester, [
      _rule(
        'a',
        HealthSeverity.suggestion,
        fix: HealthFix.apply,
        apply: (_) async {},
      ),
    ]);
    expect(find.textContaining('Fix all'), findsNothing);
  });

  testWidgets('a rule with a link shows its button', (tester) async {
    await pump(tester, [
      HealthRule(
        id: 'a',
        enabled: true,
        severity: HealthSeverity.suggestion,
        title: 'title a',
        why: 'why a',
        check: (_) async => true,
        linkLabel: 'Open the page',
        linkUrl: 'https://example.com',
      ),
    ]);
    expect(find.text('Open the page'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Fix'), findsNothing);
  });

  test('a rule that throws is skipped, the others still run', () async {
    final report = await runHealthCheck(
      HealthContext(_Radio(true), settings),
      rules: [
        HealthRule(
          id: 'boom',
          enabled: true,
          severity: HealthSeverity.problem,
          title: 't',
          why: 'w',
          check: (_) async => throw Exception('no plugin'),
        ),
        _rule('a', HealthSeverity.tip),
      ],
    );
    expect(report.findings.map((r) => r.id), ['a']);
    expect(report.passed, 0);
  });

  test('every enabled rule is ready to show and to fix', () {
    for (final rule in healthRules.where((r) => r.enabled)) {
      expect(rule.title, isNotEmpty, reason: rule.id);
      expect(rule.why, isNotEmpty, reason: rule.id);
      if (rule.fix == HealthFix.apply) {
        expect(rule.apply, isNotNull, reason: rule.id);
        expect(rule.fixDescription, isNotEmpty, reason: rule.id);
      }
      if (rule.fix == HealthFix.ask) {
        expect(rule.dialog, isNotNull, reason: rule.id);
      }
    }
  });

  test('rule ids are unique', () {
    final ids = healthRules.map((r) => r.id).toList();
    expect(ids.toSet().length, ids.length);
  });
}
