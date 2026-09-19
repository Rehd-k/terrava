import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TerravaColors {
  TerravaColors._();

  static const primary = Color(0xFF000000);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFF006C4A);
  static const secondaryContainer = Color(0xFF82F5C1);
  static const onSecondaryContainer = Color(0xFF00714E);
  static const secondaryFixed = Color(0xFF85F8C4);
  static const secondaryFixedDim = Color(0xFF68DBA9);
  static const onSecondary = Color(0xFFFFFFFF);
  static const onSecondaryFixed = Color(0xFF002114);
  static const tertiaryContainer = Color(0xFF2F1500);
  static const tertiaryFixed = Color(0xFFFFDCC3);
  static const tertiaryFixedDim = Color(0xFFFFB77D);
  static const onTertiaryContainer = Color(0xFFC76C00);
  static const onTertiaryFixed = Color(0xFF2F1500);
  static const onTertiaryFixedVariant = Color(0xFF6E3900);
  static const primaryContainer = Color(0xFF131B2E);
  static const onPrimaryContainer = Color(0xFF7C839B);
  static const primaryFixedDim = Color(0xFFBEC6E0);
  static const background = Color(0xFFF7F9FB);
  static const surface = Color(0xFFF7F9FB);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainerLow = Color(0xFFF2F4F6);
  static const surfaceContainer = Color(0xFFECEEF0);
  static const surfaceContainerHigh = Color(0xFFE6E8EA);
  static const surfaceContainerHighest = Color(0xFFE0E3E5);
  static const onSurface = Color(0xFF191C1E);
  static const onSurfaceVariant = Color(0xFF45464D);
  static const outline = Color(0xFF76777D);
  static const outlineVariant = Color(0xFFC6C6CD);
  static const error = Color(0xFFBA1A1A);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);
  static const mapCanvas = Color(0xFFE9EDEC);
}

ThemeData buildTerravaTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: TerravaColors.primary,
      onPrimary: TerravaColors.onPrimary,
      secondary: TerravaColors.secondary,
      onSecondary: TerravaColors.onSecondary,
      surface: TerravaColors.surface,
      onSurface: TerravaColors.onSurface,
      error: TerravaColors.error,
      outline: TerravaColors.outline,
    ),
    scaffoldBackgroundColor: TerravaColors.background,
  );

  final textTheme = GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

  return base.copyWith(
    textTheme: textTheme.apply(
      bodyColor: TerravaColors.onSurface,
      displayColor: TerravaColors.onSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: TerravaColors.surfaceContainerLowest,
      foregroundColor: TerravaColors.onSurface,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: TerravaColors.onSurface,
      ),
    ),
  );
}
