import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_palette.dart';

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.84)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: AppChrome.surfaceBorderRadius,
        border: Border.all(
          color: isDark ? theme.colorScheme.outline : AppPalette.line,
          width: AppChrome.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _DocumentMarkdownHeader(
              title: title,
              relativePath: relativePath,
              status: status,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Markdown(
              data: content,
              selectable: true,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentMarkdownHeader extends StatelessWidget {
  const _DocumentMarkdownHeader({
    required this.title,
    required this.relativePath,
    required this.status,
  });

  final String title;
  final String relativePath;
  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.trim().isEmpty ? '未命名草稿' : title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: isDark ? theme.colorScheme.onSurface : AppPalette.text,
          ),
        ),
        if (relativePath.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            relativePath,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.72)
                  : AppPalette.mutedText,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          status,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? theme.colorScheme.primary : AppPalette.lineStrong,
          ),
        ),
      ],
    );
  }
}
