import 'package:flutter/material.dart';

import 'app_typography.dart';
import 'control_style_token_set.dart';
import 'novel_theme_extension.dart';
import 'theme_token_set.dart';

class ThemeResolver {
  const ThemeResolver();

  ThemeData resolve(ThemeTokenSet tokenSet) {
    final colors = tokenSet.colors;
    final controlStyle = tokenSet.controlStyle;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: tokenSet.descriptor.brightness,
        primary: colors.accentColor,
        onPrimary: colors.inverseTextColor,
        secondary: colors.warmStrongColor,
        onSecondary: colors.inverseTextColor,
        error: colors.dangerStrongColor,
        onError: colors.inverseTextColor,
        surface: colors.panelBackground,
        onSurface: colors.textColor,
      ),
    );
    final textTheme = AppTypography.applyCjkFallback(
      base.textTheme.apply(
        bodyColor: colors.textColor,
        displayColor: colors.textColor,
      ),
    );

    final inputBorder = _inputBorder(
      controlStyle,
      color: tokenSet.surfaces.inputDock.borderColor,
    );

    return base.copyWith(
      scaffoldBackgroundColor: colors.canvasBackground,
      dividerColor: tokenSet.surfaces.splitter.borderColor,
      cardTheme: CardThemeData(
        color: colors.panelBackground,
        margin: controlStyle.card.margin,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(controlStyle.card.radius),
          side: BorderSide(
            color: tokenSet.surfaces.panel.borderColor,
            width: controlStyle.card.borderWidth,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.inputBackground,
        contentPadding: controlStyle.input.contentPadding,
        constraints: BoxConstraints(minHeight: controlStyle.input.minHeight),
        border: inputBorder,
        enabledBorder: inputBorder,
        focusedBorder: inputBorder.copyWith(
          borderSide: BorderSide(
            color: colors.lineStrongColor,
            width: controlStyle.input.borderWidth,
          ),
        ),
      ),
      primaryTextTheme: AppTypography.applyCjkFallback(base.primaryTextTheme),
      iconTheme: IconThemeData(color: colors.textColor),
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[
        NovelThemeExtension(tokenSet: tokenSet),
      ],
    );
  }

  OutlineInputBorder _inputBorder(
    ControlStyleTokenSet controlStyle, {
    required Color color,
  }) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlStyle.input.radius),
      borderSide: BorderSide(
        color: color,
        width: controlStyle.input.borderWidth,
      ),
    );
  }
}
