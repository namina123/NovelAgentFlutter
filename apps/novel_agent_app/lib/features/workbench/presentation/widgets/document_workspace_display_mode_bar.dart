import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'document_workspace_display_mode.dart';
import 'workbench_visual_style.dart';

class DocumentWorkspaceDisplayModeBar extends StatelessWidget {
  const DocumentWorkspaceDisplayModeBar({
    super.key,
    required this.selectedMode,
    required this.canRender,
    required this.hasDocument,
    required this.onModeSelected,
  });

  final DocumentWorkspaceDisplayMode selectedMode;
  final bool canRender;
  final bool hasDocument;
  final ValueChanged<DocumentWorkspaceDisplayMode> onModeSelected;

  @override
  Widget build(BuildContext context) {
    final optionSurface = context.novelThemeSurfaces.optionTile;
    return Wrap(
      spacing: 5,
      runSpacing: 4,
      children: [
        _DisplayModeChip(
          label: '正文',
          selected: selectedMode == DocumentWorkspaceDisplayMode.source,
          onSelected: () => onModeSelected(DocumentWorkspaceDisplayMode.source),
          foregroundColor: optionSurface.foregroundColor,
        ),
        _DisplayModeChip(
          label: '预览',
          selected: selectedMode == DocumentWorkspaceDisplayMode.render,
          enabled: hasDocument && canRender,
          onSelected: () => onModeSelected(DocumentWorkspaceDisplayMode.render),
          foregroundColor: optionSurface.foregroundColor,
        ),
        _DisplayModeChip(
          label: '结构',
          selected: selectedMode == DocumentWorkspaceDisplayMode.structure,
          enabled: hasDocument,
          onSelected: () =>
              onModeSelected(DocumentWorkspaceDisplayMode.structure),
          foregroundColor: optionSurface.foregroundColor,
        ),
      ],
    );
  }
}

class _DisplayModeChip extends StatelessWidget {
  const _DisplayModeChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    required this.foregroundColor,
    this.enabled = true,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onSelected;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final visual = WorkbenchVisualStyle.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onSelected : null,
        borderRadius: BorderRadius.circular(visual.sectionRadius),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: selected
                ? optionSurface.highlightBackgroundColor.withValues(alpha: 0.24)
                : optionSurface.backgroundColor.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(visual.sectionRadius),
            border: selected
                ? Border.all(
                    color: optionSurface.highlightBorderColor.withValues(
                      alpha: 0.22,
                    ),
                  )
                : Border.all(
                    color: optionSurface.borderColor.withValues(alpha: 0.08),
                  ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: visual.compactLabelFontSize,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              color: enabled
                  ? foregroundColor
                  : visual.disabledForeground(foregroundColor),
            ),
          ),
        ),
      ),
    );
  }
}
