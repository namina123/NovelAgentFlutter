import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'workbench_visual_style.dart';

@immutable
class WorkbenchDesktopStyle {
  const WorkbenchDesktopStyle({
    required this.surfacePadding,
    required this.sectionGap,
    required this.headerGap,
    required this.surfaceRadius,
    required this.sectionRadius,
    required this.surfaceBackgroundColor,
    required this.surfaceOverlayColor,
    required this.paneFrameColor,
    required this.paneFrameBorderColor,
    required this.navigationSectionColor,
    required this.navigationSectionBorderColor,
    required this.canvasSectionColor,
    required this.canvasSectionBorderColor,
    required this.collaborationSectionColor,
    required this.collaborationSectionBorderColor,
    required this.auxiliarySectionColor,
    required this.auxiliarySectionBorderColor,
    required this.dividerTrackColor,
    required this.dividerHandleColor,
    required this.dividerActiveHandleColor,
    required this.foregroundColor,
    required this.mutedForegroundColor,
  });

  final EdgeInsets surfacePadding;
  final double sectionGap;
  final double headerGap;
  final double surfaceRadius;
  final double sectionRadius;
  final Color surfaceBackgroundColor;
  final Color surfaceOverlayColor;
  final Color paneFrameColor;
  final Color paneFrameBorderColor;
  final Color navigationSectionColor;
  final Color navigationSectionBorderColor;
  final Color canvasSectionColor;
  final Color canvasSectionBorderColor;
  final Color collaborationSectionColor;
  final Color collaborationSectionBorderColor;
  final Color auxiliarySectionColor;
  final Color auxiliarySectionBorderColor;
  final Color dividerTrackColor;
  final Color dividerHandleColor;
  final Color dividerActiveHandleColor;
  final Color foregroundColor;
  final Color mutedForegroundColor;

  static WorkbenchDesktopStyle of(BuildContext context) {
    final colors = context.novelThemeColors;
    final panel = context.novelThemeSurfaces.panel;
    final sidebar = context.novelThemeSurfaces.sidebar;
    final splitter = context.novelThemeSurfaces.splitter;
    final visual = WorkbenchVisualStyle.of(context);
    return WorkbenchDesktopStyle(
      surfacePadding: visual.surfacePadding,
      sectionGap: visual.sectionGap,
      headerGap: visual.headerGap,
      surfaceRadius: visual.surfaceRadius,
      sectionRadius: visual.sectionRadius,
      surfaceBackgroundColor: colors.canvasBackground,
      surfaceOverlayColor: colors.panelBackground.withValues(
        alpha: visual.surfaceOverlayAlpha,
      ),
      paneFrameColor: panel.backgroundColor.withValues(
        alpha: visual.paneFrameAlpha,
      ),
      paneFrameBorderColor: colors.lineColor.withValues(
        alpha: visual.paneFrameBorderAlpha,
      ),
      navigationSectionColor: sidebar.backgroundColor.withValues(
        alpha: visual.sectionFillAlpha,
      ),
      navigationSectionBorderColor: sidebar.borderColor.withValues(
        alpha: visual.sectionBorderAlpha,
      ),
      canvasSectionColor: panel.backgroundColor.withValues(
        alpha: visual.sectionFillAlpha,
      ),
      canvasSectionBorderColor: panel.borderColor.withValues(
        alpha: visual.sectionBorderAlpha,
      ),
      collaborationSectionColor: sidebar.backgroundColor.withValues(
        alpha: visual.collaborationFillAlpha,
      ),
      collaborationSectionBorderColor: sidebar.borderColor.withValues(
        alpha: visual.sectionBorderAlpha,
      ),
      auxiliarySectionColor: panel.highlightBackgroundColor.withValues(
        alpha: visual.auxiliaryFillAlpha,
      ),
      auxiliarySectionBorderColor: panel.highlightBorderColor.withValues(
        alpha: visual.auxiliaryBorderAlpha,
      ),
      dividerTrackColor: splitter.backgroundColor.withValues(
        alpha: visual.dividerTrackAlpha,
      ),
      dividerHandleColor: splitter.borderColor.withValues(
        alpha: visual.dividerHandleAlpha,
      ),
      dividerActiveHandleColor: splitter.highlightBorderColor.withValues(
        alpha: visual.dividerActiveHandleAlpha,
      ),
      foregroundColor: panel.foregroundColor,
      mutedForegroundColor: panel.mutedForegroundColor,
    );
  }
}
