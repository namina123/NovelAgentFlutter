import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'document_workspace_canvas_frame.dart';

class DocumentMarkdownCanvas extends StatelessWidget {
  const DocumentMarkdownCanvas({
    super.key,
    required this.title,
    required this.relativePath,
    required this.content,
    required this.status,
  });

  final String title;
  final String relativePath;
  final String content;
  final String status;

  @override
  Widget build(BuildContext context) {
    // 中文注释: Markdown 渲染视图单独拆出，避免编辑器和渲染器在一个组件里互相缠绕。
    final surface = context.novelThemeSurfaces.panel;
    return DocumentWorkspaceCanvasFrame(
      title: title,
      relativePath: relativePath,
      status: status,
      body: Markdown(
        data: content,
        selectable: true,
        padding: EdgeInsets.zero,
        styleSheet: MarkdownStyleSheet(
          p: TextStyle(
            fontSize: 15,
            height: 1.7,
            color: surface.foregroundColor,
          ),
          h1: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: surface.foregroundColor,
          ),
          h2: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: surface.foregroundColor,
          ),
          blockquote: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: surface.mutedForegroundColor,
          ),
          code: TextStyle(
            fontSize: 13,
            color: surface.highlightForegroundColor,
          ),
        ),
      ),
    );
  }
}
