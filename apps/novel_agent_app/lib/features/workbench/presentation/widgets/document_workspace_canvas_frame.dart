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
    this.maxBodyWidth = 1116,
  });

  final String title;
  final String relativePath;
  final String status;
  final Widget body;
  final double? maxBodyWidth;

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
    final outerPadding = maxBodyWidth == null
        ? const EdgeInsets.fromLTRB(4, 3, 4, 4)
        : EdgeInsets.fromLTRB(
            visual.panelPadding.left + 1,
            visual.compactGap,
            visual.panelPadding.right + 1,
            visual.panelPadding.bottom,
          );

    return Padding(
      padding: outerPadding,
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
                  color: panelSurface.backgroundColor.withValues(alpha: 0.06),
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
                Text(
                  compactStatus,
                  style: TextStyle(
                    fontSize: visual.metaFontSize - 0.1,
                    fontWeight: FontWeight.w500,
                    color: panelSurface.mutedForegroundColor,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: visual.compactGap + 1),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width =
                    maxBodyWidth == null || constraints.maxWidth <= maxBodyWidth!
                    ? constraints.maxWidth
                    : maxBodyWidth!;
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
    );
  }
}
