import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/toolbar_icon_button.dart';
import '../contracts/document_workspace_action_handler.dart';
import 'document_workspace_display_mode.dart';
import 'document_workspace_display_mode_bar.dart';
import 'workbench_visual_style.dart';

class DocumentToolbarBar extends StatelessWidget {
  const DocumentToolbarBar({
    super.key,
    required this.onActionRequested,
    required this.onDisplayModeSelected,
    required this.selectedMode,
    required this.canRender,
    required this.hasDocument,
  });

  final ValueChanged<DocumentToolbarAction> onActionRequested;
  final ValueChanged<DocumentWorkspaceDisplayMode> onDisplayModeSelected;
  final DocumentWorkspaceDisplayMode selectedMode;
  final bool canRender;
  final bool hasDocument;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    final statusLabel = !hasDocument
        ? '空白'
        : canRender
        ? 'Markdown'
        : 'Text';
    return LayoutBuilder(
      builder: (context, constraints) {
        final actions = [
          ToolbarIconButton(
            icon: Icons.save_outlined,
            tooltip: '保存',
            dense: true,
            onPressed: () => onActionRequested(DocumentToolbarAction.save),
          ),
          ToolbarIconButton(
            icon: Icons.rate_review_outlined,
            tooltip: '审稿',
            tone: ToolbarIconTone.warm,
            dense: true,
            onPressed: () => onActionRequested(DocumentToolbarAction.review),
          ),
        ];
        final compact = constraints.maxWidth < 520;
        final trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ToolbarStatusPill(label: statusLabel, emphasized: hasDocument),
            SizedBox(width: visual.compactGap + 1),
            ...actions,
          ],
        );
        return Container(
          padding: EdgeInsets.fromLTRB(
            visual.compactGap + 1,
            visual.microGap + 2,
            visual.compactGap + 1,
            visual.microGap + 2,
          ),
          decoration: BoxDecoration(
            color: surface.backgroundColor.withValues(alpha: 0.025),
            border: Border(
              top: BorderSide(
                color: surface.borderColor.withValues(alpha: 0.08),
                width: surface.borderWidth,
              ),
            ),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DocumentWorkspaceDisplayModeBar(
                      selectedMode: selectedMode,
                      canRender: canRender,
                      hasDocument: hasDocument,
                      onModeSelected: onDisplayModeSelected,
                    ),
                    SizedBox(height: visual.compactGap + 1),
                    trailing,
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: DocumentWorkspaceDisplayModeBar(
                        selectedMode: selectedMode,
                        canRender: canRender,
                        hasDocument: hasDocument,
                        onModeSelected: onDisplayModeSelected,
                      ),
                    ),
                    SizedBox(width: visual.compactGap + 2),
                    trailing,
                  ],
                ),
        );
      },
    );
  }
}

class _ToolbarStatusPill extends StatelessWidget {
  const _ToolbarStatusPill({required this.label, required this.emphasized});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.optionTile;
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: emphasized
            ? surface.highlightBackgroundColor.withValues(alpha: 0.18)
            : surface.backgroundColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(visual.sectionRadius),
        border: Border.all(
          color: emphasized
              ? surface.highlightBorderColor.withValues(alpha: 0.18)
              : surface.borderColor.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: visual.compactLabelFontSize - 0.4,
          fontWeight: FontWeight.w700,
          color: emphasized ? colors.textColor : colors.mutedTextColor,
        ),
      ),
    );
  }
}
