import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

class DocumentWorkspaceCanvasFrame extends StatelessWidget {
  const DocumentWorkspaceCanvasFrame({
    super.key,
    required this.body,
    required this.title,
    required this.relativePath,
    required this.status,
  });

  final String title;
  final String relativePath;
  final String status;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 文档画布外框统一后，编辑态、渲染态和空态只需关心内容差异，不再重复写一套容器样式。
    final panelSurface = context.novelThemeSurfaces.panel;
    final toolSurface = context.novelThemeSurfaces.toolRow;
    final normalizedTitle = title.trim().isEmpty ? '未命名正文' : title.trim();
    final normalizedPath = relativePath.trim();
    final compactStatus = status.trim();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelSurface.backgroundColor.withValues(alpha: 0.78),
        border: Border.all(
          color: panelSurface.borderColor,
          width: panelSurface.borderWidth,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        normalizedTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: panelSurface.foregroundColor,
                        ),
                      ),
                      if (normalizedPath.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          normalizedPath,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: panelSurface.mutedForegroundColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (compactStatus.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  _DocumentStatusChip(
                    label: compactStatus,
                    backgroundColor: toolSurface.highlightBackgroundColor,
                    borderColor: toolSurface.highlightBorderColor,
                    foregroundColor: toolSurface.highlightForegroundColor,
                    borderWidth: toolSurface.borderWidth,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              thickness: panelSurface.borderWidth,
              color: panelSurface.borderColor.withValues(alpha: 0.72),
            ),
            const SizedBox(height: 14),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }
}

class _DocumentStatusChip extends StatelessWidget {
  const _DocumentStatusChip({
    required this.label,
    required this.backgroundColor,
    required this.borderColor,
    required this.foregroundColor,
    required this.borderWidth,
  });

  final String label;
  final Color backgroundColor;
  final Color borderColor;
  final Color foregroundColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 160),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
          height: 1.1,
        ),
      ),
    );
  }
}
