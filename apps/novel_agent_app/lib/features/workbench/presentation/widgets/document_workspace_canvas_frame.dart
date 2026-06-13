import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'workbench_visual_style.dart';

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
    final panelSurface = context.novelThemeSurfaces.panel;
    final visual = WorkbenchVisualStyle.of(context);
    final normalizedTitle = title.trim().isEmpty ? '未命名正文' : title.trim();
    final normalizedPath = relativePath.trim();
    final compactStatus = status.trim();
    final primaryLabel = normalizedTitle;
    final secondaryLabel =
        normalizedPath.isNotEmpty && normalizedPath != normalizedTitle
        ? normalizedPath
        : '';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: panelSurface.backgroundColor.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(visual.surfaceRadius),
        border: Border.all(
          color: panelSurface.borderColor.withValues(alpha: 0.12),
          width: panelSurface.borderWidth,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          visual.panelPadding.left + 1,
          visual.compactGap,
          visual.panelPadding.right + 1,
          visual.panelPadding.bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 15,
                  height: 15,
                  margin: EdgeInsets.only(right: visual.compactGap),
                  decoration: BoxDecoration(
                    color: panelSurface.backgroundColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: 9,
                    color: panelSurface.mutedForegroundColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    primaryLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: visual.sectionTitleFontSize - 0.1,
                      fontWeight: FontWeight.w700,
                      color: panelSurface.foregroundColor,
                    ),
                  ),
                ),
                if (secondaryLabel.isNotEmpty) ...[
                  SizedBox(width: visual.compactGap + 1),
                  Flexible(
                    child: Text(
                      secondaryLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: visual.metaFontSize,
                        fontWeight: FontWeight.w500,
                        color: panelSurface.mutedForegroundColor,
                      ),
                    ),
                  ),
                ],
                if (compactStatus.isNotEmpty) ...[
                  SizedBox(width: visual.compactGap + 2),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: panelSurface.backgroundColor.withValues(
                        alpha: 0.14,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: panelSurface.borderColor.withValues(alpha: 0.16),
                        width: panelSurface.borderWidth,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        compactStatus,
                        style: TextStyle(
                          fontSize: visual.metaFontSize - 0.1,
                          fontWeight: FontWeight.w500,
                          color: panelSurface.mutedForegroundColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            SizedBox(height: visual.compactGap + 1),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth > 1100
                      ? 1116.0
                      : constraints.maxWidth;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: width,
                      height: constraints.maxHeight,
                      child: body,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
