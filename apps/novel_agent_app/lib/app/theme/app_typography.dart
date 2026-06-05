import 'package:flutter/material.dart';

class AppTypography {
  const AppTypography._();

  static const List<String> cjkFontFamilyFallback = <String>[
    'Microsoft YaHei UI',
    'Microsoft YaHei',
    'PingFang SC',
    'Hiragino Sans GB',
    'Noto Sans CJK SC',
    'Noto Sans SC',
    'Source Han Sans SC',
    'WenQuanYi Micro Hei',
    'Arial Unicode MS',
  ];

  static TextTheme applyCjkFallback(TextTheme textTheme) {
    return textTheme.copyWith(
      displayLarge: _copyWithFallback(textTheme.displayLarge),
      displayMedium: _copyWithFallback(textTheme.displayMedium),
      displaySmall: _copyWithFallback(textTheme.displaySmall),
      headlineLarge: _copyWithFallback(textTheme.headlineLarge),
      headlineMedium: _copyWithFallback(textTheme.headlineMedium),
      headlineSmall: _copyWithFallback(textTheme.headlineSmall),
      titleLarge: _copyWithFallback(textTheme.titleLarge),
      titleMedium: _copyWithFallback(textTheme.titleMedium),
      titleSmall: _copyWithFallback(textTheme.titleSmall),
      bodyLarge: _copyWithFallback(textTheme.bodyLarge),
      bodyMedium: _copyWithFallback(textTheme.bodyMedium),
      bodySmall: _copyWithFallback(textTheme.bodySmall),
      labelLarge: _copyWithFallback(textTheme.labelLarge),
      labelMedium: _copyWithFallback(textTheme.labelMedium),
      labelSmall: _copyWithFallback(textTheme.labelSmall),
    );
  }

  static TextStyle? _copyWithFallback(TextStyle? style) {
    return style?.copyWith(fontFamilyFallback: cjkFontFamilyFallback);
  }
}
