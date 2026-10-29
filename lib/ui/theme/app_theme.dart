import 'package:flutter/material.dart';

ThemeData criarTemaAplicativo() {
  const colorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1E3A8A),
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: Color(0xFFDBEAFE),
    onPrimaryContainer: Color(0xFF1E3A8A),
    secondary: Color(0xFF516070),
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: Color(0xFFD5E4F8),
    onSecondaryContainer: Color(0xFF576676),
    tertiary: Color(0xFF15803D),
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFDCFCE7),
    onTertiaryContainer: Color(0xFF166534),
    error: Color(0xFFB91C1C),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: Color(0xFFF8FAFC),
    onSurface: Color(0xFF0F172A),
    surfaceContainerHighest: Color(0xFFF1F5F9),
    onSurfaceVariant: Color(0xFF475569),
    outline: Color(0xFFCBD5E1),
    outlineVariant: Color(0xFFE2E8F0),
    shadow: Color(0xFF0F172A),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF0F172A),
    onInverseSurface: Color(0xFFF8FAFC),
    inversePrimary: Color(0xFFDBEAFE),
    surfaceTint: Color(0xFF1E3A8A),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colorScheme.surface,
    appBarTheme: const AppBarTheme(centerTitle: false),
    cardTheme: const CardThemeData(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: const StadiumBorder(),
      ),
    ),
  );
}
