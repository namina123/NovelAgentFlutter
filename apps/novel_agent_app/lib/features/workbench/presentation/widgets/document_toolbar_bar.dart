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
    // 中文注释: 这一轮先削弱顶部“工具台”感，只保留轻量查看方式和少量必要动作。
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '正文工作区',
                    style: TextStyle(
                      fontSize: visual.sectionTitleFontSize,
                      height: visual.titleLineHeight,
                      fontWeight: FontWeight.w800,
                      color: surface.foregroundColor,
                    ),
                  ),
                  SizedBox(height: visual.microGap - 2),
                  Text(
                    '围绕当前文档继续写作、预览或检查结构。',
                    style: TextStyle(
                      fontSize: visual.metaFontSize,
                      height: visual.bodyLineHeight,
                      fontWeight: FontWeight.w600,
                      color: surface.mutedForegroundColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Wrap(
              spacing: visual.compactGap,
              runSpacing: visual.compactGap,
              children: [
                ToolbarIconButton(
                  icon: Icons.save_outlined,
                  tooltip: '保存',
                  onPressed: () =>
                      onActionRequested(DocumentToolbarAction.save),
                ),
                ToolbarIconButton(
                  icon: Icons.rate_review_outlined,
                  tooltip: '审稿',
                  tone: ToolbarIconTone.warm,
                  onPressed: () =>
                      onActionRequested(DocumentToolbarAction.review),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '查看方式',
              style: TextStyle(
                fontSize: visual.metaFontSize,
                fontWeight: FontWeight.w700,
                color: surface.mutedForegroundColor,
              ),
            ),
            SizedBox(height: visual.compactGap),
            DocumentWorkspaceDisplayModeBar(
              selectedMode: selectedMode,
              canRender: canRender,
              hasDocument: hasDocument,
              onModeSelected: onDisplayModeSelected,
            ),
          ],
        ),
      ],
    );
  }
}
