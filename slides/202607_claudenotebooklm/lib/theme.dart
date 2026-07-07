import 'package:flutter/material.dart';
import 'package:flutter_deck/flutter_deck.dart';
import 'package:google_fonts/google_fonts.dart';

/// 全スライド共通で参照するブランド・アクセントカラー定義。
abstract final class AppColors {
  // ベース（MD3 シード）
  static const seed = Color(0xFF4285F4); // Google Blue

  // Google 4色（アクセント・図解の彩り）
  static const googleBlue = Color(0xFF4285F4);
  static const googleRed = Color(0xFFEA4335);
  static const googleYellow = Color(0xFFFBBC04);
  static const googleGreen = Color(0xFF34A853);

  // 構成図のブランド色（ノード塗り）
  static const claude = Color(0xFFD97757); // Claude テラコッタ
  static const notebookLm = Color(0xFF0B57D0); // NotebookLM（Google Blue 700）
  static const geminiStart = Color(0xFF4285F4); // Gemini グラデ始点
  static const geminiEnd = Color(0xFF9B72CB); // Gemini グラデ終点
  static const drive = Color(0xFF34A853);
  static const dropbox = Color(0xFF0061FF);
  static const github = Color(0xFF24292E);
  static const slack = Color(0xFF611F69);
  static const excel = Color(0xFF217346);
  static const backlog = Color(0xFF4CAF93);
  static const windowsBatch = Color(0xFF0078D4); // タスクスケジューラ/PowerShell
}

/// アプリ全体の MD3 ライトテーマ（Google 調配色 + Noto Sans JP）。
FlutterDeckThemeData buildAppFlutterDeckTheme() {
  final theme = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.seed),
    textTheme: GoogleFonts.notoSansJpTextTheme(),
    useMaterial3: true,
  );

  final base = FlutterDeckThemeData.fromTheme(theme);

  // プロジェクタ投影前提で本文サイズを底上げする(既定の bodyLarge=28/bodyMedium=22/bodySmall=16 では
  // 会議室後方から読みづらいため)。文字量を減らす代わりにサイズを優先する。
  return base.copyWith(
    textTheme: base.textTheme.copyWith(
      bodyLarge: base.textTheme.bodyLarge.copyWith(fontSize: 32),
      bodyMedium: base.textTheme.bodyMedium.copyWith(fontSize: 28),
      bodySmall: base.textTheme.bodySmall.copyWith(fontSize: 22),
    ),
  );
}
