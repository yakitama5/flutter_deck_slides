import 'package:flutter/material.dart';

const miniNavy = Color(0xFF082B55);
const miniCoral = Color(0xFFFF7163);
const miniYellow = Color(0xFFFFEA70);
const miniTurquoise = Color(0xFF20D3BD);
const miniTeal = Color(0xFF006D70);
const paper = Color(0xFFF3F7FB);
const ink = miniNavy;
const muted = Color(0xFF52677D);
const mint = Color(0xFFE0F6F0);
const slideSize = Size(1600, 900);

// Accents follow the mini #6 event artwork, on a solid navy foundation.
const warmGradient = LinearGradient(colors: [miniCoral, miniYellow]);
const freshGradient = LinearGradient(colors: [miniYellow, miniTurquoise]);
const kaigi2026Gradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [
    Color(0xFFFF0055),
    Color(0xFF6200EA),
    Color(0xFF6200EA),
    Color(0xFF001155),
  ],
  stops: [0, .4, .6, 1],
);

final openingTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: miniNavy,
    primary: miniNavy,
    secondary: miniTeal,
    surface: paper,
  ),
  scaffoldBackgroundColor: miniNavy,
  fontFamily: 'Noto Sans JP',
  cardTheme: const CardThemeData(
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(32)),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 96,
      height: 1.12,
      fontWeight: FontWeight.w900,
    ),
    displayMedium: TextStyle(
      fontSize: 72,
      height: 1.2,
      fontWeight: FontWeight.w700,
    ),
    headlineLarge: TextStyle(
      fontSize: 56,
      height: 1.25,
      fontWeight: FontWeight.w700,
    ),
    headlineMedium: TextStyle(
      fontSize: 40,
      height: 1.3,
      fontWeight: FontWeight.w700,
    ),
    bodyLarge: TextStyle(fontSize: 30, height: 1.5),
    bodyMedium: TextStyle(fontSize: 24, height: 1.5),
    labelLarge: TextStyle(
      fontSize: 22,
      height: 1.3,
      fontWeight: FontWeight.w500,
    ),
  ).apply(bodyColor: ink, displayColor: ink),
);

class SlideCanvas extends StatelessWidget {
  const SlideCanvas({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: openingTheme,
    child: ColoredBox(
      color: miniNavy,
      child: Center(
        child: FittedBox(
          child: SizedBox.fromSize(
            size: slideSize,
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'Noto Sans JP',
                fontSize: 28,
                height: 1.4,
                color: ink,
              ),
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
}
