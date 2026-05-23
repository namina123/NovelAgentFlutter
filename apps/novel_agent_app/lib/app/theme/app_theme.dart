import 'package:flutter/material.dart';

import 'app_chrome.dart';
import 'app_palette.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    // 中文注释: 主题集中定义旧项目浅暖底色和蓝金强调色，避免控件各自散落颜色常量。
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        surface: AppPalette.panel,
        primary: AppPalette.accent,
        secondary: AppPalette.warmStrong,
        onSurface: AppPalette.text,
        onPrimary: AppPalette.white,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppPalette.background,
      dividerColor: AppPalette.lineStrong,
      textTheme: base.textTheme.apply(
        bodyColor: AppPalette.text,
        displayColor: AppPalette.text,
      ),
      cardTheme: const CardThemeData(
        color: AppPalette.panel,
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.white.withValues(alpha: 0.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: AppChrome.inputBorder(sideColor: AppPalette.line),
        enabledBorder: AppChrome.inputBorder(sideColor: AppPalette.line),
        focusedBorder: AppChrome.inputBorder(sideColor: AppPalette.lineStrong),
      ),
    );
  }

  static ThemeData dark() {
    // 中文注释: 夜间主题复用同一组组件密度和边框语言，只替换配色层，避免亮暗模式像两套完全不同的应用。
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        surface: Color(0xFF1E252B),
        primary: Color(0xFF78B6C7),
        secondary: Color(0xFFE1B166),
        onSurface: Color(0xFFF1EFE8),
        onPrimary: Color(0xFF0E171B),
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF141A1F),
      dividerColor: const Color(0xFF4E6972),
      textTheme: base.textTheme.apply(
        bodyColor: const Color(0xFFF1EFE8),
        displayColor: const Color(0xFFF1EFE8),
      ),
      cardTheme: const CardThemeData(
        color: Color(0xFF1E252B),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF212C33),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: AppChrome.inputBorder(sideColor: const Color(0xFF4E6972)),
        enabledBorder: AppChrome.inputBorder(
          sideColor: const Color(0xFF4E6972),
        ),
        focusedBorder: AppChrome.inputBorder(
          sideColor: const Color(0xFF78B6C7),
        ),
      ),
    );
  }
}
