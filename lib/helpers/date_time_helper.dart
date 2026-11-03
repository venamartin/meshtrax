import 'dart:io' show Platform;

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../utils/platform_info.dart';

/// Dates and times on screen, the system's way: the order of day and month
/// from its region, 12- or 24-hour from its clock setting (every platform
/// passes that on), names in the app's language. Logs and exports keep
/// their own fixed format.
class DateTimeHelper {
  DateTimeHelper._();

  static final Map<String, DateFormat> _formats = {};

  /// The locale dates are written in: the app's language with the system's
  /// region when the system speaks it. The app knows only "English"; the
  /// region is what tells 11/3 from 03/11. Only dates take the region, so
  /// the rest of the app keeps its one translation per language.
  static String localeOf(BuildContext context) {
    final language = Localizations.localeOf(context).languageCode;
    final formats = systemFormats();
    final candidates = [
      if (formats != null) _split(formats),
      for (final l in WidgetsBinding.instance.platformDispatcher.locales)
        (l.languageCode, l.countryCode),
    ];
    for (final (lang, region) in candidates) {
      if (lang != language || region == null) continue;
      final locale = '${language}_$region';
      if (DateFormat.localeExists(locale)) return locale;
    }
    return language;
  }

  /// The system's own setting for how dates are written where it is not in
  /// the language list Flutter passes on, else null. Windows: the Regional
  /// format, which Platform.localeName reads (GetUserDefaultLocaleName);
  /// Flutter passes the display languages. Linux: see [linuxFormats];
  /// Flutter passes the message languages. Android, iOS and macOS give the
  /// region in the list itself.
  @visibleForTesting
  static String? Function() systemFormats = () {
    if (PlatformInfo.isWindows) return Platform.localeName;
    if (PlatformInfo.isLinux) return linuxFormats(Platform.environment);
    return null;
  };

  /// LC_TIME, unless LC_ALL overrides it; LANG when neither is set.
  @visibleForTesting
  static String? linuxFormats(Map<String, String> environment) {
    for (final name in const ['LC_ALL', 'LC_TIME', 'LANG']) {
      final value = environment[name];
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  /// "en-GB", "en_GB.UTF-8" or "sr-Latn-RS" as (language, region); "C" and
  /// "POSIX" have no region.
  static (String, String?) _split(String name) {
    final parts = name.split(RegExp('[.@]')).first.split(RegExp('[-_]'));
    final region = RegExp(r'^([A-Za-z]{2}|\d{3})$');
    return (
      parts.first.toLowerCase(),
      parts.skip(1).where(region.hasMatch).firstOrNull?.toUpperCase(),
    );
  }

  /// [skeleton] must be one of intl's named skeletons (DateFormat.yMd and
  /// the like): anything else is read as a literal pattern.
  static DateFormat _format(BuildContext context, String skeleton) {
    final locale = localeOf(context);
    return _formats.putIfAbsent(
        '$locale $skeleton', () => DateFormat(skeleton, locale));
  }

  /// "2:22 PM" or "14:22", as the phone's clock reads. [seconds] for a
  /// detail screen.
  static String time(BuildContext context, DateTime t, {bool seconds = false}) {
    final h24 = MediaQuery.alwaysUse24HourFormatOf(context);
    final skeleton = seconds ? (h24 ? 'Hms' : 'jms') : (h24 ? 'Hm' : 'jm');
    return _format(context, skeleton).format(t);
  }

  /// "11/3" or "03/11".
  static String dayMonth(BuildContext context, DateTime t) =>
      _format(context, 'Md').format(t);

  /// "11/3/2026" or "03/11/2026".
  static String date(BuildContext context, DateTime t) =>
      _format(context, 'yMd').format(t);

  /// "Tue, Nov 3" or "Tue 3 Nov": the heading over a day's messages.
  static String dayHeading(BuildContext context, DateTime t) =>
      _format(context, 'MMMEd').format(t);

  /// "Tue".
  static String weekday(BuildContext context, DateTime t) =>
      _format(context, 'E').format(t);
}
