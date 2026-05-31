import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import 'workbench_desktop_section_id.dart';
import 'workbench_desktop_section_spec.dart';
import 'workbench_desktop_style.dart';
import 'workbench_visual_style.dart';

class WorkbenchDesktopSectionSpecResolver {
  const WorkbenchDesktopSectionSpecResolver();

  WorkbenchDesktopSectionSpec resolve(
    BuildContext context,
    WorkbenchDesktopSectionId id,
  ) {
    final style = WorkbenchDesktopStyle.of(context);
    final sidebar = context.novelThemeSurfaces.sidebar;
    final panel = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    return switch (id) {
      WorkbenchDesktopSectionId.navigation => WorkbenchDesktopSectionSpec(
        id: id,
        surfaceRole: PanelSurfaceRole.sidebar,
        backgroundColor: style.navigationSectionColor,
        borderColor: style.navigationSectionBorderColor,
        topAccentColor: visual.strongBorder(sidebar.highlightBorderColor),
        innerFrameColor: sidebar.backgroundColor.withValues(
          alpha: visual.sectionFillAlpha,
        ),
        innerFrameBorderColor: sidebar.borderColor.withValues(
          alpha: visual.sectionBorderAlpha,
        ),
        radius: style.sectionRadius,
      ),
      WorkbenchDesktopSectionId.primaryCanvas => WorkbenchDesktopSectionSpec(
        id: id,
        surfaceRole: PanelSurfaceRole.panel,
        backgroundColor: style.canvasSectionColor,
        borderColor: style.canvasSectionBorderColor,
        topAccentColor: visual.strongBorder(panel.highlightBorderColor),
        innerFrameColor: panel.backgroundColor.withValues(
          alpha: visual.sectionFillAlpha,
        ),
        innerFrameBorderColor: panel.borderColor.withValues(
          alpha: visual.sectionBorderAlpha,
        ),
        radius: style.sectionRadius,
      ),
      WorkbenchDesktopSectionId.collaboration => WorkbenchDesktopSectionSpec(
        id: id,
        surfaceRole: PanelSurfaceRole.sidebar,
        backgroundColor: style.collaborationSectionColor,
        borderColor: style.collaborationSectionBorderColor,
        topAccentColor: visual.strongBorder(sidebar.highlightBorderColor),
        innerFrameColor: sidebar.backgroundColor.withValues(
          alpha: visual.collaborationFillAlpha,
        ),
        innerFrameBorderColor: sidebar.borderColor.withValues(
          alpha: visual.sectionBorderAlpha,
        ),
        radius: style.sectionRadius,
      ),
    };
  }
}
