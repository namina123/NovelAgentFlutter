import 'package:flutter/material.dart';

import 'document_text_editor_surface.dart';
import 'document_workspace_canvas_frame.dart';

class DocumentContentCanvas extends StatelessWidget {
  const DocumentContentCanvas({
    super.key,
    required this.title,
    required this.relativePath,
    required this.content,
    required this.status,
    required this.onChanged,
    this.isReadOnly = false,
  });

  final String title;
  final String relativePath;
  final String content;
  final String status;
  final ValueChanged<String> onChanged;
  final bool isReadOnly;

  @override
  Widget build(BuildContext context) {
    final lineCount = '\n'.allMatches(content).length + 1;
    final characterCount = content.characters.length;
    final theme = Theme.of(context);
    return DocumentWorkspaceCanvasFrame(
      title: title,
      relativePath: relativePath,
      status: status,
      maxBodyWidth: null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CanvasStatusBar(
            modeLabel: isReadOnly ? '只读' : '编辑',
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
                child: DocumentTextEditorSurface(
                  content: content,
                  isReadOnly: isReadOnly,
                  onChanged: isReadOnly ? null : onChanged,
                  hintText: '开始编写当前文档...',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasStatusBar extends StatelessWidget {
  const _CanvasStatusBar({
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
