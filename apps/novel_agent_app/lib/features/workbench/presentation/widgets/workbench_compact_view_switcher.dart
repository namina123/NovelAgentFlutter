import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/workbench_compact_primary_view.dart';
import 'workbench_visual_style.dart';

class WorkbenchCompactViewSwitcher extends StatelessWidget {
  const WorkbenchCompactViewSwitcher({
    super.key,
    required this.activeView,
    required this.onViewSelected,
    this.showOverview = true,
  });

  final WorkbenchCompactPrimaryView activeView;
  final ValueChanged<WorkbenchCompactPrimaryView> onViewSelected;
  final bool showOverview;

  @override
  Widget build(BuildContext context) {
    final panel = context.novelThemeSurfaces.panel;
    final mutedForeground =
        context.novelThemeSurfaces.panel.mutedForegroundColor;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
      color: panel.backgroundColor.withValues(alpha: 0.16),
      child: Row(
        children: WorkbenchCompactPrimaryView.values
            .map(
              (view) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: _WorkbenchCompactViewButton(
                    view: view,
                    selected: view == activeView,
                    mutedForegroundColor: mutedForeground,
                    panelColor: panel.backgroundColor,
                    panelBorderColor: panel.borderColor,
                    highlightBackgroundColor: panel.highlightBackgroundColor
                        .withValues(alpha: 0.78),
                    highlightBorderColor: panel.highlightBorderColor.withValues(
                      alpha: 0.52,
                    ),
                    highlightForegroundColor: panel.highlightForegroundColor,
                    onPressed: () => onViewSelected(view),
                  ),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _WorkbenchCompactViewButton extends StatelessWidget {
  const _WorkbenchCompactViewButton({
    required this.view,
    required this.selected,
    required this.mutedForegroundColor,
    required this.panelColor,
    required this.panelBorderColor,
    required this.highlightBackgroundColor,
    required this.highlightBorderColor,
    required this.highlightForegroundColor,
    required this.onPressed,
  });

  final WorkbenchCompactPrimaryView view;
  final bool selected;
  final Color mutedForegroundColor;
  final Color panelColor;
  final Color panelBorderColor;
  final Color highlightBackgroundColor;
  final Color highlightBorderColor;
  final Color highlightForegroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final visual = WorkbenchVisualStyle.of(context);
    final foreground = selected
        ? highlightForegroundColor
        : mutedForegroundColor;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(visual.sectionRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? highlightBackgroundColor : panelColor,
          border: Border.all(
            color: selected
                ? highlightBorderColor
                : panelBorderColor.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(visual.sectionRadius),
        ),
        child: Text(
          view.label,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: visual.compactLabelFontSize - 0.1,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
