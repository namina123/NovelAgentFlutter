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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DisplayModeChip(
          label: '编辑',
          selected: selectedMode == DocumentWorkspaceDisplayMode.source,
          onSelected: () => onModeSelected(DocumentWorkspaceDisplayMode.source),
          foregroundColor: optionSurface.foregroundColor,
        ),
        _DisplayModeChip(
          label: '渲染',
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
    final visual = WorkbenchVisualStyle.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onSelected : null,
        borderRadius: BorderRadius.zero,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(10, 7, 10, 7),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? foregroundColor.withValues(alpha: 0.82)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: visual.compactLabelFontSize - 0.1,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: enabled
                  ? foregroundColor
                  : visual.disabledForeground(foregroundColor).withValues(
                      alpha: 0.7,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
