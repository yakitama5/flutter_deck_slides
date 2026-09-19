import 'package:flutter/material.dart';

/// Material 3 roles drawn from the FlutterKaigi mini Okayama event artwork.
class MaterialTheme {
  const MaterialTheme();

  static const navy = Color(0xFF082B53);
  static const coral = Color(0xFFFF896B);
  static const cyan = Color(0xFF55CDF1);
  static const yellow = Color(0xFFFFEA73);

  static ColorScheme colorScheme(Brightness brightness) {
    final base = ColorScheme.fromSeed(
      seedColor: cyan,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.tonalSpot,
    );
    if (brightness == Brightness.light) {
      return base.copyWith(
        primary: const Color(0xFFA53D28),
        onPrimary: const Color(0xFFFFFFFF),
        primaryContainer: const Color(0xFFFFDAD0),
        onPrimaryContainer: const Color(0xFF3D0A02),
        secondary: const Color(0xFF006580),
        onSecondary: const Color(0xFFFFFFFF),
        secondaryContainer: const Color(0xFFCAEEFF),
        onSecondaryContainer: const Color(0xFF002F49),
        tertiary: const Color(0xFF6F5E00),
        onTertiary: const Color(0xFFFFFFFF),
        surface: const Color(0xFFF6F9FF),
        onSurface: navy,
      );
    }
    return base.copyWith(
      primary: coral,
      onPrimary: const Color(0xFF42170C),
      primaryContainer: const Color(0xFF473C50),
      onPrimaryContainer: const Color(0xFFFFE9E1),
      secondary: cyan,
      onSecondary: const Color(0xFF002F49),
      secondaryContainer: const Color(0xFF124967),
      onSecondaryContainer: const Color(0xFFD2F2FF),
      tertiary: yellow,
      onTertiary: const Color(0xFF393000),
      tertiaryContainer: const Color(0xFF494522),
      onTertiaryContainer: const Color(0xFFFFF3B4),
      surface: navy,
      onSurface: const Color(0xFFF7FAFF),
      onSurfaceVariant: const Color(0xFFBDCEE2),
      surfaceDim: const Color(0xFF062447),
      surfaceBright: const Color(0xFF214B72),
      surfaceContainerLowest: const Color(0xFF062447),
      surfaceContainerLow: const Color(0xFF0B315B),
      surfaceContainer: const Color(0xFF103760),
      surfaceContainerHigh: const Color(0xFF163F68),
      surfaceContainerHighest: const Color(0xFF1D486F),
      outline: const Color(0xFF7D9BBC),
      outlineVariant: const Color(0xFF345779),
    );
  }

  ThemeData light() => theme(colorScheme(Brightness.light));

  ThemeData dark() => theme(colorScheme(Brightness.dark));

  ThemeData theme(ColorScheme colors) => ThemeData(
    useMaterial3: true,
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    fontFamily: 'Noto Sans JP',
    textTheme: TextTheme(
      displayLarge: _type(112, 1.35, FontWeight.w700),
      displayMedium: _type(88, 1.4, FontWeight.w700),
      displaySmall: _type(72, 1.4, FontWeight.w700),
      headlineLarge: _type(66, 1.4, FontWeight.w700),
      headlineMedium: _type(54, 1.45, FontWeight.w700),
      headlineSmall: _type(46, 1.5, FontWeight.w600),
      titleLarge: _type(40, 1.5, FontWeight.w600),
      titleMedium: _type(32, 1.5, FontWeight.w600),
      titleSmall: _type(28, 1.5, FontWeight.w600),
      bodyLarge: _type(36, 1.65),
      bodyMedium: _type(30, 1.6),
      bodySmall: _type(24, 1.5),
      labelLarge: _type(24, 1.4, FontWeight.w600),
      labelMedium: _type(22, 1.4),
      labelSmall: _type(20, 1.4),
    ).apply(bodyColor: colors.onSurface, displayColor: colors.onSurface),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    ),
    tooltipTheme: const TooltipThemeData(
      textStyle: TextStyle(
        fontFamily: 'Noto Sans JP',
        fontSize: 16,
        fontVariations: [FontVariation('wght', 400)],
      ),
    ),
  );
  // Explicit axes avoid inheriting the variable font's thin default instance.
  static TextStyle _type(
    double size,
    double height, [
    FontWeight weight = FontWeight.w400,
  ]) => TextStyle(
    fontSize: size,
    height: height,
    fontWeight: weight,
    fontVariations: [FontVariation('wght', weight.value.toDouble())],
  );
}
