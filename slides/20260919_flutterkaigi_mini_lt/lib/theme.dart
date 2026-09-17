import 'package:flutter/material.dart';

/// Material 3 color roles, with a rose primary and a separate blue palette.
class MaterialTheme {
  const MaterialTheme();

  static const pink = Color(0xFFC55883);
  static const blue = Color(0xFF438CCA);

  static ColorScheme colorScheme(Brightness brightness) {
    final rose = ColorScheme.fromSeed(
      seedColor: pink,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    final sky = ColorScheme.fromSeed(
      seedColor: blue,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    return rose.copyWith(
      secondary: sky.primary,
      onSecondary: sky.onPrimary,
      secondaryContainer: sky.primaryContainer,
      onSecondaryContainer: sky.onPrimaryContainer,
      secondaryFixed: sky.primaryFixed,
      secondaryFixedDim: sky.primaryFixedDim,
      onSecondaryFixed: sky.onPrimaryFixed,
      onSecondaryFixedVariant: sky.onPrimaryFixedVariant,
    );
  }

  ThemeData light() => theme(colorScheme(Brightness.light));

  ThemeData dark() => theme(colorScheme(Brightness.dark));

  ThemeData theme(ColorScheme colors) => ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    fontFamily: 'Kiwi Maru',
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        fontSize: 112,
        height: 1.35,
        fontWeight: FontWeight.w500,
      ),
      displayMedium: TextStyle(
        fontSize: 88,
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
      displaySmall: TextStyle(
        fontSize: 72,
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
      headlineLarge: TextStyle(
        fontSize: 66,
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
      headlineMedium: TextStyle(
        fontSize: 54,
        height: 1.45,
        fontWeight: FontWeight.w500,
      ),
      headlineSmall: TextStyle(
        fontSize: 46,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
      titleLarge: TextStyle(
        fontSize: 40,
        height: 1.5,
        fontWeight: FontWeight.w500,
      ),
      titleMedium: TextStyle(fontSize: 32, height: 1.5),
      titleSmall: TextStyle(fontSize: 28, height: 1.5),
      bodyLarge: TextStyle(fontSize: 36, height: 1.65),
      bodyMedium: TextStyle(fontSize: 30, height: 1.6),
      bodySmall: TextStyle(fontSize: 24, height: 1.5),
      labelLarge: TextStyle(
        fontSize: 24,
        height: 1.4,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(fontSize: 22, height: 1.4),
      labelSmall: TextStyle(fontSize: 20, height: 1.4),
    ).apply(bodyColor: colors.onSurface, displayColor: colors.onSurface),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      textStyle: TextStyle(fontFamily: 'Kiwi Maru', fontSize: 16),
    ),
  );
}
