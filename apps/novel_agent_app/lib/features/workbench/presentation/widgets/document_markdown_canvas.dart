import 'package:flutter/material.dart';

import 'document_markdown_preview_surface.dart';
import 'document_text_editor_surface.dart';
import 'document_workspace_canvas_frame.dart';
import 'document_workspace_display_mode.dart';

class DocumentMarkdownCanvas extends StatelessWidget {
  const DocumentMarkdownCanvas({
    super.key,
    required this.title,
    required this.relativePath,
    required this.content,
    required this.status,
    required this.displayMode,
    this.onChanged,
  });

  final String title;
  final String relativePath;
  final String content;
  final String status;
  final DocumentWorkspaceDisplayMode displayMode;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(content).length + 1;
    final characterCount = content.characters.length;
    final isRenderMode = displayMode == DocumentWorkspaceDisplayMode.render;
    final theme = Theme.of(context);
    return DocumentWorkspaceCanvasFrame(
      title: title,
      relativePath: relativePath,
      status: status,
      maxBodyWidth: null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MarkdownCanvasStatusBar(
            modeLabel: isRenderMode ? '渲染' : '编辑',
            secondaryLabel: '$lineCount 行 · $characterCount 字符',
          ),
          const SizedBox(height: 6),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.18),
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.16),
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: isRenderMode
                    ? DocumentMarkdownPreviewSurface(content: content)
                    : DocumentTextEditorSurface(
                        content: content,
                        isReadOnly: onChanged == null,
                        onChanged: onChanged,
                        hintText: '继续编辑 Markdown 源码...',
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkdownCanvasStatusBar extends StatelessWidget {
  const _MarkdownCanvasStatusBar({
    required this.modeLabel,
    required this.secondaryLabel,
  });

  final String modeLabel;
  final String secondaryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Row(
      children: [
        Text(
          modeLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          secondaryLabel,
          style: theme.textTheme.labelSmall?.copyWith(
            color: onSurface.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }
}
