import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'workbench_visual_style.dart';

class WorkbenchObjectPanelBody extends StatelessWidget {
  const WorkbenchObjectPanelBody({
    super.key,
    required this.child,
    required this.semanticsLabel,
  });

  final Widget child;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    return Semantics(
      label: semanticsLabel,
      child: DecoratedBox(
        key: const ValueKey<String>('workbench_object_panel_body'),
        decoration: BoxDecoration(
          color: surface.backgroundColor.withValues(
            alpha: visual.auxiliaryFillAlpha,
          ),
          borderRadius: BorderRadius.circular(visual.sectionRadius),
          border: Border.all(
            color: visual.subtleBorder(surface.borderColor),
            width: surface.borderWidth,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(visual.sectionRadius),
          child: child,
        ),
      ),
    );
  }
}
