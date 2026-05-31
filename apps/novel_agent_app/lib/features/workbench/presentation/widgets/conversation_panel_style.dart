import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

@immutable
class ConversationPanelStyle {
  const ConversationPanelStyle({
    required this.outerPadding,
    required this.sectionGap,
    required this.bodyGap,
    required this.bandGap,
    required this.bandPadding,
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
  final double sectionGap;
  final double bodyGap;
  final double bandGap;
  final EdgeInsets bandPadding;
  final Color bandBackgroundColor;
  final Color bandBorderColor;
  final Color accentBandBackgroundColor;
  final Color accentBandForegroundColor;
  final Color foregroundColor;
  final Color mutedForegroundColor;
  final Color dividerColor;
  final Color timelineBackgroundColor;

  static ConversationPanelStyle of(BuildContext context) {
    final colors = context.novelThemeColors;
    final panel = context.novelThemeSurfaces.panel;
    final inputDock = context.novelThemeSurfaces.inputDock;
    return ConversationPanelStyle(
      outerPadding: const EdgeInsets.all(12),
      sectionGap: 10,
      bodyGap: 12,
      bandGap: 8,
      bandPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      bandBackgroundColor: inputDock.backgroundColor.withValues(alpha: 0.9),
      bandBorderColor: panel.borderColor.withValues(alpha: 0.9),
      accentBandBackgroundColor: panel.highlightBackgroundColor.withValues(
        alpha: 0.72,
      ),
      accentBandForegroundColor: colors.lineStrongColor,
      foregroundColor: panel.foregroundColor,
      mutedForegroundColor: panel.mutedForegroundColor,
      dividerColor: colors.lineColor.withValues(alpha: 0.84),
      timelineBackgroundColor: panel.backgroundColor.withValues(alpha: 0.84),
    );
  }
}
