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
      surfacePadding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      sidebarPadding: const EdgeInsets.fromLTRB(7, 8, 7, 7),
      panelPadding: const EdgeInsets.fromLTRB(10, 9, 10, 8),
      auxiliaryPadding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      sectionGap: 6,
      headerGap: 6,
      compactGap: 5,
      microGap: 3,
      surfaceRadius: normalizedSurfaceRadius,
      sectionRadius: normalizedSectionRadius,
      titleFontSize: 14.8,
      sectionTitleFontSize: 12.5,
      bodyFontSize: 12,
      metaFontSize: 10.5,
      captionFontSize: 10.5,
      compactLabelFontSize: 11,
      titleLineHeight: 1.2,
      bodyLineHeight: 1.5,
      surfaceOverlayAlpha: 0.08,
      paneFrameAlpha: 0.97,
      paneFrameBorderAlpha: 0.76,
      sectionFillAlpha: 0.92,
      collaborationFillAlpha: 0.96,
      sectionBorderAlpha: 0.66,
      emphasizedSectionFillAlpha: 0.24,
      auxiliaryFillAlpha: 0.16,
      auxiliaryBorderAlpha: 0.46,
      dividerTrackAlpha: 0.92,
      dividerHandleAlpha: 0.8,
      dividerActiveHandleAlpha: 0.96,
      subtleBorderAlpha: 0.62,
      strongBorderAlpha: 0.78,
      optionIdleAlpha: 0.62,
      badgeFillAlpha: 0.64,
      disabledAlpha: 0.42,
    );
  }

  Color subtleBorder(Color color) => color.withValues(alpha: subtleBorderAlpha);

  Color strongBorder(Color color) => color.withValues(alpha: strongBorderAlpha);

  Color disabledForeground(Color color) =>
      color.withValues(alpha: disabledAlpha);

  Color optionBackground(ThemeSurfaceSpec surface, {required bool selected}) {
    return selected
        ? surface.highlightBackgroundColor
        : surface.backgroundColor.withValues(alpha: optionIdleAlpha);
  }

  Color sectionBackground(ThemeSurfaceSpec surface, {bool emphasized = false}) {
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
