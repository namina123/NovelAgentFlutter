import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../app/theme/app_typography.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import 'document_workspace_canvas_frame.dart';
import 'workbench_visual_style.dart';

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
    final surface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    final lineCount = '\n'.allMatches(content).length + 1;
    final characterCount = content.characters.length;
    final styleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: TextStyle(fontSize: 17, height: 1.96, color: surface.foregroundColor),
      pPadding: EdgeInsets.zero,
      a: TextStyle(
        fontSize: 15.4,
        fontWeight: FontWeight.w600,
        color: colors.accentColor,
      ),
      strong: TextStyle(
        fontWeight: FontWeight.w800,
        color: surface.foregroundColor,
      ),
      em: TextStyle(
        fontStyle: FontStyle.italic,
        color: surface.foregroundColor.withValues(alpha: 0.92),
      ),
      h1: TextStyle(
        fontSize: 30,
        height: 1.22,
        fontWeight: FontWeight.w800,
        color: surface.foregroundColor,
      ),
      h2: TextStyle(
        fontSize: 24,
        height: 1.28,
        fontWeight: FontWeight.w800,
        color: surface.foregroundColor,
      ),
      h3: TextStyle(
        fontSize: 19.5,
        height: 1.34,
        fontWeight: FontWeight.w700,
        color: surface.foregroundColor,
      ),
      h4: TextStyle(
        fontSize: 16.5,
        height: 1.36,
        fontWeight: FontWeight.w700,
        color: surface.foregroundColor.withValues(alpha: 0.94),
      ),
      h1Padding: const EdgeInsets.only(top: 8, bottom: 16),
      h2Padding: const EdgeInsets.only(top: 16, bottom: 10),
      h3Padding: const EdgeInsets.only(top: 13, bottom: 8),
      h4Padding: const EdgeInsets.only(top: 10, bottom: 6),
      blockSpacing: 22,
      listIndent: 24,
      listBullet: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: colors.accentColor.withValues(alpha: 0.9),
      ),
      listBulletPadding: const EdgeInsets.only(right: 10),
      blockquote: TextStyle(
        fontSize: 14.2,
        height: 1.78,
        color: surface.mutedForegroundColor,
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      blockquoteDecoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: surface.borderColor.withValues(alpha: 0.22),
          width: AppChrome.borderWidth,
        ),
      ),
      code: TextStyle(
        fontSize: 13,
        fontFamily: 'Consolas',
        color: surface.highlightForegroundColor,
      ),
      codeblockPadding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      codeblockDecoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: surface.borderColor.withValues(alpha: 0.24),
          width: AppChrome.borderWidth,
        ),
      ),
      tableHead: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w800,
        color: surface.foregroundColor,
      ),
      tableBody: TextStyle(
        fontSize: 13.8,
        height: 1.64,
        color: surface.foregroundColor.withValues(alpha: 0.94),
      ),
      tableHeadAlign: TextAlign.left,
      tablePadding: const EdgeInsets.only(top: 6, bottom: 10),
      tableBorder: TableBorder.all(
        color: surface.borderColor.withValues(alpha: 0.34),
        width: AppChrome.borderWidth,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),
      tableCellsDecoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.18),
      ),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: surface.borderColor.withValues(alpha: 0.36),
            width: 1,
          ),
        ),
      ),
    );
    final normalizedStyleSheet = styleSheet.copyWith(
      code: AppTypography.applyMonospaceFallback(styleSheet.code!),
      tableBody: AppTypography.applyMonospaceFallback(styleSheet.tableBody!),
    );
    return DocumentWorkspaceCanvasFrame(
      title: title,
      relativePath: relativePath,
      status: status,
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: surface.backgroundColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(visual.surfaceRadius + 1),
          border: Border.all(
            color: surface.borderColor.withValues(alpha: 0.1),
            width: AppChrome.borderWidth,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Wrap(
                spacing: 10,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '预览',
                    style: TextStyle(
                      fontSize: visual.compactLabelFontSize,
                      fontWeight: FontWeight.w800,
                      color: colors.mutedTextColor,
                    ),
                  ),
                  _PreviewMetaLabel(label: '$lineCount 行'),
                  _PreviewMetaLabel(label: '$characterCount 字符'),
                  _PreviewMetaLabel(label: '只读预览', emphasized: true),
                ],
              ),
            ),
            Container(
              height: 1,
              color: surface.borderColor.withValues(alpha: 0.08),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: surface.backgroundColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: surface.borderColor.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Markdown(
                      data: content,
                      selectable: true,
                      padding: const EdgeInsets.fromLTRB(34, 28, 34, 42),
                      styleSheet: normalizedStyleSheet,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewMetaLabel extends StatelessWidget {
  const _PreviewMetaLabel({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized
            ? colors.accentSoftColor.withValues(alpha: 0.24)
            : surface.backgroundColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: visual.metaFontSize,
          fontWeight: FontWeight.w700,
          color: emphasized ? colors.lineStrongColor : colors.mutedTextColor,
        ),
      ),
    );
  }
}
