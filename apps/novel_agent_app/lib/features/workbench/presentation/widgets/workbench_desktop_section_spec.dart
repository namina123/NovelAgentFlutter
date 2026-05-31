import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import 'workbench_desktop_section_id.dart';

class WorkbenchDesktopSectionSpec {
  const WorkbenchDesktopSectionSpec({
    required this.id,
    required this.surfaceRole,
    required this.backgroundColor,
    required this.borderColor,
    required this.topAccentColor,
    required this.innerFrameColor,
    required this.innerFrameBorderColor,
    required this.radius,
  });

  final WorkbenchDesktopSectionId id;
  final PanelSurfaceRole surfaceRole;
  final Color backgroundColor;
  final Color borderColor;
  final Color topAccentColor;
  final Color innerFrameColor;
  final Color innerFrameBorderColor;
  final double radius;
}
