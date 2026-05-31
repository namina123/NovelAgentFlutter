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
    // 中文注释: 查看方式退成轻量 chips，让它更像“当前文档的阅读方式”，而不是一个编辑器模式总站。
    final optionSurface = context.novelThemeSurfaces.optionTile;
    final visual = WorkbenchVisualStyle.of(context);
    return Wrap(
      spacing: visual.compactGap,
      runSpacing: visual.compactGap,
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: visual.optionBackground(optionSurface, selected: false),
      selectedColor: optionSurface.highlightBackgroundColor,
      disabledColor: visual.optionBackground(optionSurface, selected: false),
      side: BorderSide(
        color: selected
            ? optionSurface.highlightBorderColor
            : optionSurface.borderColor,
        width: optionSurface.borderWidth,
      ),
      labelStyle: TextStyle(
        fontSize: visual.compactLabelFontSize,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
        color: enabled
            ? foregroundColor
            : visual.disabledForeground(foregroundColor),
      ),
      onSelected: enabled ? (_) => onSelected() : null,
    );
  }
}
