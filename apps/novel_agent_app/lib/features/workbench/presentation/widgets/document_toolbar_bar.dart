import 'package:flutter/material.dart';

import '../../../../../shared/widgets/section_heading.dart';
import '../../../../../shared/widgets/toolbar_icon_button.dart';
import '../contracts/document_workspace_action_handler.dart';

class DocumentToolbarBar extends StatelessWidget {
  const DocumentToolbarBar({
    super.key,
    required this.onActionRequested,
    required this.canRender,
    required this.isRendered,
  });

  final ValueChanged<DocumentToolbarAction> onActionRequested;
  final bool canRender;
  final bool isRendered;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 文档工具栏单独拆出，避免后续按钮增加时把文档工作区主文件撑成巨型 build。
    return SectionHeading(
      title: '正文工作区',
      subtitle: '这里保留 Flutter 原生的编辑工作台感，而不是沿用旧宿主的补丁式工具栏。',
      trailing: Wrap(
        spacing: 8,
        children: [
          ToolbarIconButton(
            icon: Icons.notes_outlined,
            tooltip: '结构视图',
            onPressed: () => onActionRequested(DocumentToolbarAction.outline),
          ),
          ToolbarIconButton(
            icon: isRendered
                ? Icons.edit_note_outlined
                : Icons.visibility_outlined,
            tooltip: isRendered ? '返回编辑' : '渲染',
            tone: ToolbarIconTone.accent,
            onPressed: canRender
                ? () => onActionRequested(DocumentToolbarAction.render)
                : null,
          ),
          ToolbarIconButton(
            icon: Icons.save_outlined,
            tooltip: '保存',
            onPressed: () => onActionRequested(DocumentToolbarAction.save),
          ),
          ToolbarIconButton(
            icon: Icons.rate_review_outlined,
            tooltip: '审稿',
            tone: ToolbarIconTone.warm,
            onPressed: () => onActionRequested(DocumentToolbarAction.review),
          ),
        ],
      ),
    );
  }
}
