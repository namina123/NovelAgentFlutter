import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'document_workspace_canvas_frame.dart';
import 'workbench_visual_style.dart';

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
    final surface = context.novelThemeSurfaces.panel;
    final colors = context.novelThemeColors;
    final visual = WorkbenchVisualStyle.of(context);
    return DocumentWorkspaceCanvasFrame(
      title: headline,
      relativePath: '',
      status: '等待打开资源',
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: surface.backgroundColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(visual.surfaceRadius + 2),
          border: Border.all(
            color: surface.borderColor.withValues(alpha: 0.14),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: surface.backgroundColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      size: 12,
                      color: colors.mutedTextColor,
                    ),
                  ),
                  SizedBox(width: visual.compactGap + 1),
                  Text(
                    'Document editor',
                    style: TextStyle(
                      fontSize: visual.compactLabelFontSize,
                      fontWeight: FontWeight.w800,
                      color: colors.mutedTextColor,
                    ),
                  ),
                  SizedBox(width: visual.sectionGap + 1),
                  Container(
                    width: 1,
                    height: 12,
                    color: surface.borderColor.withValues(alpha: 0.14),
                  ),
                  SizedBox(width: visual.sectionGap + 1),
                  Text(
                    '无活动文档',
                    style: TextStyle(
                      fontSize: visual.metaFontSize,
                      fontWeight: FontWeight.w700,
                      color: colors.mutedTextColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.hourglass_empty_outlined,
                    size: 12,
                    color: colors.mutedTextColor,
                  ),
                  SizedBox(width: visual.compactGap),
                  Text(
                    '等待资源',
                    style: TextStyle(
                      fontSize: visual.metaFontSize,
                      fontWeight: FontWeight.w700,
                      color: colors.mutedTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 1,
              color: surface.borderColor.withValues(alpha: 0.1),
            ),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(46, 78, 46, 42),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: surface.highlightBackgroundColor
                                    .withValues(alpha: 0.24),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.edit_note_rounded,
                                size: 22,
                                color: surface.highlightForegroundColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.accentSoftColor.withValues(
                                  alpha: 0.24,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '创作画布',
                                style: TextStyle(
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.w800,
                                  color: colors.lineStrongColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: visual.headerGap + 12),
                        Text(
                          headline,
                          style: TextStyle(
                            fontSize: 24,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: surface.foregroundColor,
                          ),
                        ),
                        SizedBox(height: visual.sectionGap + 4),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 14.4,
                            height: 1.72,
                            fontWeight: FontWeight.w600,
                            color: surface.mutedForegroundColor,
                          ),
                        ),
                        SizedBox(height: visual.headerGap + 10),
                        Container(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                          decoration: BoxDecoration(
                            color: surface.backgroundColor.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: surface.borderColor.withValues(
                                alpha: 0.12,
                              ),
                            ),
                          ),
                          child: Text(
                            '从左侧资源区打开现有文档，或先在右侧会话区生成内容后再保存到项目目录。',
                            style: TextStyle(
                              fontSize: 12.8,
                              height: 1.62,
                              fontWeight: FontWeight.w600,
                              color: colors.mutedTextColor,
                            ),
                          ),
                        ),
                      ],
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
