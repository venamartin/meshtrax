import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/helpers/date_time_helper.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/l10n/l10n.dart';

// A user with Imperial units saw day/month dates: the channel screen built
// them by hand. Dates follow the system's region, times its 12/24-hour
// switch, and Units has nothing to do with either (owner, 2026-11-03).
void main() {
  final t = DateTime(2026, 11, 3, 14, 22, 5); // a Tuesday
  final systemFormats = DateTimeHelper.systemFormats;

  // The machine running the tests must not decide: only the phone below.
  setUp(() => DateTimeHelper.systemFormats = () => null);
  tearDown(() => DateTimeHelper.systemFormats = systemFormats);

  /// A context in the app's [language] on a phone set to [phone].
  Future<BuildContext> on(WidgetTester tester, String language, Locale phone,
      {bool h24 = false}) async {
    tester.platformDispatcher.localesTestValue = [phone];
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    late BuildContext ctx;
    // The phone's 24-hour switch, as the app's MediaQuery passes it on.
    await tester.pumpWidget(MediaQuery(
      data: MediaQueryData(alwaysUse24HourFormat: h24),
      child: MaterialApp(
        locale: Locale(language),
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (c) {
          ctx = c;
          return const SizedBox();
        }),
      ),
    ));
    return ctx;
  }

  testWidgets('a US phone: month first, 12-hour', (tester) async {
    final ctx = await on(tester, 'en', const Locale('en', 'US'));
    expect(DateTimeHelper.dayMonth(ctx, t), '11/3');
    expect(DateTimeHelper.date(ctx, t), '11/3/2026');
    expect(DateTimeHelper.time(ctx, t), matches(RegExp(r'^2:22\sPM$')));
    expect(DateTimeHelper.dayHeading(ctx, t), 'Tue, Nov 3');
  });

  testWidgets('a UK phone: day first, 24-hour', (tester) async {
    final ctx = await on(tester, 'en', const Locale('en', 'GB'));
    expect(DateTimeHelper.dayMonth(ctx, t), '03/11');
    expect(DateTimeHelper.date(ctx, t), '03/11/2026');
    expect(DateTimeHelper.time(ctx, t), '14:22');
    expect(DateTimeHelper.dayHeading(ctx, t), 'Tue 3 Nov');
  });

  testWidgets('the 24-hour switch wins over the region', (tester) async {
    final ctx = await on(tester, 'en', const Locale('en', 'US'), h24: true);
    expect(DateTimeHelper.time(ctx, t), '14:22');
    expect(DateTimeHelper.time(ctx, t, seconds: true), '14:22:05');
    expect(DateTimeHelper.dayMonth(ctx, t), '11/3');
  });

  testWidgets('the app in another language writes that language\'s way',
      (tester) async {
    final ctx = await on(tester, 'de', const Locale('en', 'US'));
    expect(DateTimeHelper.localeOf(ctx), 'de');
    expect(DateTimeHelper.dayMonth(ctx, t), '3.11.');
    expect(DateTimeHelper.weekday(ctx, t), startsWith('Di'));
  });

  testWidgets('the first phone language the app speaks gives the region',
      (tester) async {
    tester.platformDispatcher.localesTestValue = [
      const Locale('ga', 'IE'),
      const Locale('en', 'AU'),
    ];
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(builder: (c) {
        ctx = c;
        return const SizedBox();
      }),
    ));
    expect(DateTimeHelper.localeOf(ctx), 'en_AU');
  });

  // Windows passes its display languages and Linux its message languages to
  // Flutter; how dates are written is a setting of its own on both.
  testWidgets('Windows: the Regional format beats the display language',
      (tester) async {
    DateTimeHelper.systemFormats = () => 'en-GB';
    final ctx = await on(tester, 'en', const Locale('en', 'US'));
    expect(DateTimeHelper.localeOf(ctx), 'en_GB');
    expect(DateTimeHelper.dayMonth(ctx, t), '03/11');
  });

  testWidgets('Linux: LC_TIME beats the message language', (tester) async {
    DateTimeHelper.systemFormats = () => 'en_GB.UTF-8';
    final ctx = await on(tester, 'en', const Locale('en', 'US'));
    expect(DateTimeHelper.localeOf(ctx), 'en_GB');
  });

  testWidgets('a format setting in another language, or C, is passed over',
      (tester) async {
    DateTimeHelper.systemFormats = () => 'de-DE';
    final ctx = await on(tester, 'en', const Locale('en', 'AU'));
    expect(DateTimeHelper.localeOf(ctx), 'en_AU');
    DateTimeHelper.systemFormats = () => 'C.UTF-8';
    expect(DateTimeHelper.localeOf(ctx), 'en_AU');
  });

  test('Linux reads LC_ALL, then LC_TIME, then LANG', () {
    expect(
        DateTimeHelper.linuxFormats(
            {'LANG': 'en_US.UTF-8', 'LC_TIME': 'en_GB.UTF-8'}),
        'en_GB.UTF-8');
    expect(
        DateTimeHelper.linuxFormats({
          'LANG': 'en_US.UTF-8',
          'LC_TIME': 'en_GB.UTF-8',
          'LC_ALL': 'en_AU.UTF-8',
        }),
        'en_AU.UTF-8');
    expect(DateTimeHelper.linuxFormats({'LANG': 'en_US.UTF-8', 'LC_TIME': ''}),
        'en_US.UTF-8');
    expect(DateTimeHelper.linuxFormats({}), isNull);
  });
}
