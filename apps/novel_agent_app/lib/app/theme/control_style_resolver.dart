import 'package:flutter/material.dart';

import 'control_style_token_set.dart';
import 'theme_color_tokens.dart';
import 'theme_surface_spec.dart';
import 'theme_surface_spec_set.dart';

class ControlStyleResolver {
  const ControlStyleResolver();

  ThemeSurfaceSpecSet resolveSurfaceSpecs({
    required ThemeColorTokens colors,
    required ControlStyleTokenSet controlStyle,
  }) {
    // 中文注释: 表面语义颜色仍然由主题决定，但几何与边框厚度改由控件风格注入。
    ThemeSurfaceSpec makeSurface({
      required Color backgroundColor,
      required Color borderColor,
      required Color foregroundColor,
      required Color mutedForegroundColor,
      required Color highlightBackgroundColor,
      required Color highlightBorderColor,
      required Color highlightForegroundColor,
      required double radius,
      required double borderWidth,
    }) {
      return ThemeSurfaceSpec(
        backgroundColor: backgroundColor,
        borderColor: borderColor,
        foregroundColor: foregroundColor,
        mutedForegroundColor: mutedForegroundColor,
        highlightBackgroundColor: highlightBackgroundColor,
        highlightBorderColor: highlightBorderColor,
        highlightForegroundColor: highlightForegroundColor,
        borderWidth: borderWidth,
        radius: radius,
      );
    }

    final panelChrome = controlStyle.panel;
    final inputChrome = controlStyle.input;
    final chipChrome = controlStyle.chip;

    return ThemeSurfaceSpecSet(
      panel: makeSurface(
        backgroundColor: colors.panelBackground,
        borderColor: colors.lineColor,
        foregroundColor: colors.textColor,
        mutedForegroundColor: colors.mutedTextColor,
        highlightBackgroundColor: colors.accentSoftColor,
        highlightBorderColor: colors.lineStrongColor,
        highlightForegroundColor: colors.textColor,
        radius: panelChrome.radius,
        borderWidth: panelChrome.borderWidth,
      ),
      sidebar: makeSurface(
        backgroundColor: colors.sidebarBackground,
        borderColor: colors.lineColor,
        foregroundColor: colors.textColor,
        mutedForegroundColor: colors.mutedTextColor,
        highlightBackgroundColor: colors.accentSoftColor,
        highlightBorderColor: colors.lineStrongColor,
        highlightForegroundColor: colors.textColor,
        radius: panelChrome.radius,
        borderWidth: panelChrome.borderWidth,
      ),
      inputDock: makeSurface(
        backgroundColor: colors.inputBackground,
        borderColor: colors.lineColor,
        foregroundColor: colors.textColor,
        mutedForegroundColor: colors.mutedTextColor,
        highlightBackgroundColor: colors.accentSoftColor,
        highlightBorderColor: colors.lineStrongColor,
        highlightForegroundColor: colors.textColor,
        radius: inputChrome.radius,
        borderWidth: inputChrome.borderWidth,
      ),
      conversationEntry: makeSurface(
        backgroundColor: colors.panelBackground,
        borderColor: colors.lineColor,
        foregroundColor: colors.textColor,
        mutedForegroundColor: colors.mutedTextColor,
        highlightBackgroundColor: colors.accentSoftColor,
        highlightBorderColor: colors.lineStrongColor,
        highlightForegroundColor: colors.textColor,
        radius: panelChrome.radius,
        borderWidth: panelChrome.borderWidth,
      ),
      toolRow: makeSurface(
        backgroundColor: colors.panelBackground,
        borderColor: colors.lineColor,
        foregroundColor: colors.textColor,
        mutedForegroundColor: colors.mutedTextColor,
        highlightBackgroundColor: colors.accentSoftColor,
        highlightBorderColor: colors.lineStrongColor,
        highlightForegroundColor: colors.textColor,
        radius: panelChrome.radius,
        borderWidth: panelChrome.borderWidth,
      ),
      optionTile: makeSurface(
        backgroundColor: colors.accentSoftColor,
        borderColor: colors.lineColor,
        foregroundColor: colors.textColor,
        mutedForegroundColor: colors.mutedTextColor,
        highlightBackgroundColor: colors.accentColor.withValues(alpha: 0.14),
        highlightBorderColor: colors.lineStrongColor,
        highlightForegroundColor: colors.textColor,
        radius: chipChrome.radius,
        borderWidth: chipChrome.borderWidth,
      ),
      splitter: makeSurface(
        backgroundColor: colors.canvasBackground,
        borderColor: colors.lineColor,
        foregroundColor: colors.lineStrongColor,
        mutedForegroundColor: colors.mutedTextColor,
        highlightBackgroundColor: colors.canvasBackground,
        highlightBorderColor: colors.lineStrongColor,
        highlightForegroundColor: colors.lineStrongColor,
        radius: 0,
        borderWidth: controlStyle.card.dividerWidth,
      ),
    );
  }
}
