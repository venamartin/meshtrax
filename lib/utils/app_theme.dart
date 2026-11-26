import 'package:material_ui/material_ui.dart';

import 'route_transitions.dart';

/// The app's look, light or dark.
ThemeData appTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: brightness,
  ),
  useMaterial3: true,
  fontFamily: 'Liberation Sans',
  fontFamilyFallback: const ['Noto Color Emoji', 'DejaVu Sans'],
  snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  pageTransitionsTheme: appPageTransitions,
);
