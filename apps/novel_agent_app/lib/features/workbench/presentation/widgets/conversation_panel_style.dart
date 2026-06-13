import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

@immutable
class ConversationPanelStyle {
  const ConversationPanelStyle({
    required this.outerPadding,
    required this.surfacePadding,
    required this.sectionGap,
    required this.bodyGap,
    required this.bandGap,
    required this.bandPadding,
    required this.sectionRadius,
    required this.titleFontSize,
    required this.bodyFontSize,
    required this.metaFontSize,
    required this.compactLabelFontSize,
    required this.bodyLineHeight,
    required this.bandBackgroundColor,
    required this.bandBorderColor,
    required this.accentBandBackgroundColor,
    required this.accentBandForegroundColor,
    required this.foregroundColor,
    required this.mutedForegroundColor,
    required this.dividerColor,
    required this.timelineBackgroundColor,
  });

  final EdgeInsets outerPadding;
  final EdgeInsets surfacePadding;
  final double sectionGap;
  final double bodyGap;
  final double bandGap;
  final EdgeInsets bandPadding;
  final double sectionRadius;
  final double titleFontSize;
  final double bodyFontSize;
  final double metaFontSize;
  final double compactLabelFontSize;
  final double bodyLineHeight;
  final Color bandBackgroundColor;
  final Color bandBorderColor;
  final Color accentBandBackgroundColor;
  final Color accentBandForegroundColor;
  final Color foregroundColor;
  final Color mutedForegroundColor;
  final Color dividerColor;
  final Color timelineBackgroundColor;

  double get microGap => bodyGap > 3 ? bodyGap - 2 : 1;

  double gap(double delta, {double min = 0}) {
    final value = bandGap + delta;
    return value < min ? min : value;
  }

  EdgeInsets inset({
    double left = 0,
    double top = 0,
    double right = 0,
    double bottom = 0,
    double min = 0,
  }) {
    return EdgeInsets.fromLTRB(
      _safeInsetValue(bandPadding.left + left, min),
      _safeInsetValue(bandPadding.top + top, min),
      _safeInsetValue(bandPadding.right + right, min),
      _safeInsetValue(bandPadding.bottom + bottom, min),
    );
  }

  static double _safeInsetValue(double value, double min) {
    return value < min ? min : value;
  }

  static ConversationPanelStyle of(BuildContext context) {
    final colors = context.novelThemeColors;
    final panel = context.novelThemeSurfaces.panel;
    final inputDock = context.novelThemeSurfaces.inputDock;
    return ConversationPanelStyle(
      outerPadding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      surfacePadding: const EdgeInsets.fromLTRB(8, 7, 8, 7),
      sectionGap: 6,
      bodyGap: 5,
      bandGap: 4.5,
      bandPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      sectionRadius: 8,
      titleFontSize: 14.5,
      bodyFontSize: 12,
      metaFontSize: 10.5,
      compactLabelFontSize: 11,
      bodyLineHeight: 1.5,
      bandBackgroundColor: inputDock.backgroundColor.withValues(alpha: 0.88),
      bandBorderColor: panel.borderColor.withValues(alpha: 0.78),
      accentBandBackgroundColor: panel.highlightBackgroundColor.withValues(
        alpha: 0.78,
      ),
      accentBandForegroundColor: colors.lineStrongColor,
      foregroundColor: panel.foregroundColor,
      mutedForegroundColor: panel.mutedForegroundColor,
      dividerColor: colors.lineColor.withValues(alpha: 0.78),
      timelineBackgroundColor: panel.backgroundColor.withValues(alpha: 0.7),
    );
  }
}
