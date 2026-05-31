import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'document_workspace_canvas_frame.dart';

class DocumentEmptyCanvas extends StatelessWidget {
  const DocumentEmptyCanvas({
    super.key,
    this.headline = '打开或新建文档',
    this.message = '从资源区打开文件，或先在会话栏生成新内容后保存到项目目录。',
  });

  final String headline;
  final String message;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 编辑画布占位独立出来，后续换成真正编辑器时只替换这一层。
    final surface = context.novelThemeSurfaces.panel;
    return DocumentWorkspaceCanvasFrame(
      title: headline,
      relativePath: '',
      status: '等待打开资源',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_note_rounded,
                size: 54,
                color: surface.highlightForegroundColor,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                  color: surface.mutedForegroundColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
