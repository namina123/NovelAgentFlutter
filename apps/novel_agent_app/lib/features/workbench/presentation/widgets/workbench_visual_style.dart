import 'package:flutter/material.dart';

import '../../../../../app/theme/theme_surface_spec.dart';
import '../../../../../shared/theme/novel_theme_context.dart';

@immutable
class WorkbenchVisualStyle {
  const WorkbenchVisualStyle({
    required this.surfacePadding,
    required this.sidebarPadding,
    required this.panelPadding,
    required this.auxiliaryPadding,
    required this.sectionGap,
    required this.headerGap,
    required this.compactGap,
    required this.microGap,
    required this.surfaceRadius,
    required this.sectionRadius,
    required this.titleFontSize,
    required this.sectionTitleFontSize,
    required this.bodyFontSize,
    required this.metaFontSize,
    required this.captionFontSize,
    required this.compactLabelFontSize,
    required this.titleLineHeight,
    required this.bodyLineHeight,
    required this.surfaceOverlayAlpha,
    required this.paneFrameAlpha,
    required this.paneFrameBorderAlpha,
    required this.sectionFillAlpha,
    required this.collaborationFillAlpha,
    required this.sectionBorderAlpha,
    required this.emphasizedSectionFillAlpha,
    required this.auxiliaryFillAlpha,
    required this.auxiliaryBorderAlpha,
    required this.dividerTrackAlpha,
    required this.dividerHandleAlpha,
    required this.dividerActiveHandleAlpha,
    required this.subtleBorderAlpha,
    required this.strongBorderAlpha,
    required this.optionIdleAlpha,
    required this.badgeFillAlpha,
    required this.disabledAlpha,
  });

  final EdgeInsets surfacePadding;
  final EdgeInsets sidebarPadding;
  final EdgeInsets panelPadding;
  final EdgeInsets auxiliaryPadding;
  final double sectionGap;
  final double headerGap;
  final double compactGap;
  final double microGap;
  final double surfaceRadius;
  final double sectionRadius;
  final double titleFontSize;
  final double sectionTitleFontSize;
  final double bodyFontSize;
  final double metaFontSize;
  final double captionFontSize;
  final double compactLabelFontSize;
  final double titleLineHeight;
  final double bodyLineHeight;
  final double surfaceOverlayAlpha;
  final double paneFrameAlpha;
  final double paneFrameBorderAlpha;
  final double sectionFillAlpha;
  final double collaborationFillAlpha;
  final double sectionBorderAlpha;
  final double emphasizedSectionFillAlpha;
  final double auxiliaryFillAlpha;
  final double auxiliaryBorderAlpha;
  final double dividerTrackAlpha;
  final double dividerHandleAlpha;
  final double dividerActiveHandleAlpha;
  final double subtleBorderAlpha;
  final double strongBorderAlpha;
  final double optionIdleAlpha;
  final double badgeFillAlpha;
  final double disabledAlpha;

  static WorkbenchVisualStyle of(BuildContext context) {
    final control = context.novelControlStyleTokenSet;
    final normalizedSurfaceRadius = _normalizedRadius(
      control.panel.radius,
      fallback: 6,
      max: 8,
    );
    final normalizedSectionRadius = _normalizedRadius(
      control.card.radius,
      fallback: 5,
      max: 6,
    );
    return WorkbenchVisualStyle(
      surfacePadding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      sidebarPadding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      panelPadding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      auxiliaryPadding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      sectionGap: 10,
      headerGap: 10,
      compactGap: 6,
      microGap: 4,
      surfaceRadius: normalizedSurfaceRadius,
      sectionRadius: normalizedSectionRadius,
      titleFontSize: 14,
      sectionTitleFontSize: 12,
      bodyFontSize: 11.5,
      metaFontSize: 10.5,
      captionFontSize: 10,
      compactLabelFontSize: 10.5,
      titleLineHeight: 1.2,
      bodyLineHeight: 1.45,
      surfaceOverlayAlpha: 0.16,
      paneFrameAlpha: 0.34,
      paneFrameBorderAlpha: 0.5,
      sectionFillAlpha: 0.9,
      collaborationFillAlpha: 0.94,
      sectionBorderAlpha: 0.54,
      emphasizedSectionFillAlpha: 0.42,
      auxiliaryFillAlpha: 0.28,
      auxiliaryBorderAlpha: 0.5,
      dividerTrackAlpha: 0.64,
      dividerHandleAlpha: 0.68,
      dividerActiveHandleAlpha: 0.88,
      subtleBorderAlpha: 0.36,
      strongBorderAlpha: 0.44,
      optionIdleAlpha: 0.42,
      badgeFillAlpha: 0.52,
      disabledAlpha: 0.42,
    );
  }

  Color subtleBorder(Color color) => color.withValues(alpha: subtleBorderAlpha);

  Color strongBorder(Color color) => color.withValues(alpha: strongBorderAlpha);

  Color disabledForeground(Color color) => color.withValues(alpha: disabledAlpha);

  Color optionBackground(ThemeSurfaceSpec surface, {required bool selected}) {
    return selected
        ? surface.highlightBackgroundColor
        : surface.backgroundColor.withValues(alpha: optionIdleAlpha);
  }

  Color sectionBackground(
    ThemeSurfaceSpec surface, {
    bool emphasized = false,
  }) {
    return emphasized
        ? surface.highlightBackgroundColor.withValues(
            alpha: emphasizedSectionFillAlpha,
          )
        : surface.backgroundColor.withValues(alpha: sectionFillAlpha);
  }

  Color badgeBackground(ThemeSurfaceSpec surface) {
    return surface.backgroundColor.withValues(alpha: badgeFillAlpha);
  }
}

double _normalizedRadius(
  double value, {
  required double fallback,
  required double max,
}) {
  final normalized = value <= 0 ? fallback : value;
  return normalized > max ? max : normalized;
}
