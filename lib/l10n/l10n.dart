import 'package:material_ui/material_ui.dart';
import 'app_localizations.dart';

// AppLocalizations.localizationsDelegates still lists flutter_localizations'
// Material and Cupertino delegates, which material_ui's widgets don't read
// (flutter/flutter#191072).
const appLocalizationsDelegates = <LocalizationsDelegate<dynamic>>[
  AppLocalizations.delegate,
  ...GlobalMaterialLocalizations.delegates,
];

extension LocalizationExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
