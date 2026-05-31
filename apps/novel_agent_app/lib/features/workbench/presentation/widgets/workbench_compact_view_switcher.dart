import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/workbench_compact_primary_view.dart';
import 'workbench_desktop_style.dart';

class WorkbenchCompactViewSwitcher extends StatelessWidget {
  const WorkbenchCompactViewSwitcher({
    super.key,
    required this.activeView,
    required this.onViewSelected,
  });

  final WorkbenchCompactPrimaryView activeView;
  final ValueChanged<WorkbenchCompactPrimaryView> onViewSelected;

  @override
  Widget build(BuildContext context) {
    final style = WorkbenchDesktopStyle.of(context);
    final panel = context.novelThemeSurfaces.panel;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.paneFrameColor,
        border: Border.all(color: style.paneFrameBorderColor),
        borderRadius: BorderRadius.circular(style.sectionRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Row(
          children: WorkbenchCompactPrimaryView.values
              .map(
                (view) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _WorkbenchCompactViewButton(
                      view: view,
                      selected: view == activeView,
                      mutedForegroundColor: style.mutedForegroundColor,
                      panelColor: panel.backgroundColor,
                      panelBorderColor: panel.borderColor,
                      highlightBackgroundColor:
                          panel.highlightBackgroundColor,
                      highlightBorderColor: panel.highlightBorderColor,
                      highlightForegroundColor:
                          panel.highlightForegroundColor,
                      onPressed: () => onViewSelected(view),
                    ),
                  ),
                ),
              )
              .toList(growable: false),
        ),
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
    final foreground = selected
        ? highlightForegroundColor
        : mutedForegroundColor;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? highlightBackgroundColor : panelColor,
          border: Border.all(
            color: selected ? highlightBorderColor : panelBorderColor,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(view.icon, size: 16, color: foreground),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                view.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
