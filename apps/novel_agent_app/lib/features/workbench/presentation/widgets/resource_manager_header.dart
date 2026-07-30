import 'package:flutter/material.dart';

import '../../../../../app/theme/theme_surface_spec.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import 'workbench_visual_style.dart';

class ResourceManagerHeader extends StatelessWidget {
  const ResourceManagerHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.itemCount,
    required this.directoryCount,
    required this.fileCount,
  });

  final String title;
  final String subtitle;
  final int itemCount;
  final int directoryCount;
  final int fileCount;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    final normalizedTitle = title.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '文件',
                    style: TextStyle(
                      fontSize: visual.metaFontSize,
                      fontWeight: FontWeight.w800,
                      color: surface.mutedForegroundColor,
                      letterSpacing: 0.08,
                    ),
                  ),
                  SizedBox(height: visual.microGap + 1),
                  if (normalizedTitle.isNotEmpty)
                    Text(
                      normalizedTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: visual.titleFontSize - 0.6,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                        color: surface.foregroundColor,
                      ),
                    ),
                  if (subtitle.trim().isNotEmpty) ...[
                    SizedBox(
                      height: normalizedTitle.isNotEmpty ? visual.microGap : 0,
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: visual.metaFontSize,
                        height: visual.bodyLineHeight,
                        fontWeight: FontWeight.w500,
                        color: surface.mutedForegroundColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(width: visual.compactGap),
            LayoutBuilder(
              builder: (context, constraints) {
                // 中文注释: 侧栏很窄时（如三栏 204px），只留总项数 chip，把空间还给标题，
                // 目录/文档两个统计 chip 等宽度够再显示。
                final showStatChips = constraints.maxWidth >= 188;
                return Wrap(
                  spacing: visual.microGap,
                  runSpacing: visual.microGap,
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: surface.backgroundColor.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$itemCount 项',
                        style: TextStyle(
                          fontSize: visual.metaFontSize - 0.1,
                          fontWeight: FontWeight.w700,
                          color: surface.mutedForegroundColor,
                        ),
                      ),
                    ),
                    if (showStatChips)
                      _ExplorerStatChip(
                        label: '目录',
                        value: '$directoryCount',
                        surface: surface,
                      ),
                    if (showStatChips)
                      _ExplorerStatChip(
                        // 中文注释: 与资料库面板标题「文件」一致，避免「文档/文件」混用。
                        label: '文件',
                        value: '$fileCount',
                        surface: surface,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _ExplorerStatChip extends StatelessWidget {
  const _ExplorerStatChip({
    required this.label,
    required this.value,
    required this.surface,
  });

  final String label;
  final String value;
  final ThemeSurfaceSpec surface;

  @override
  Widget build(BuildContext context) {
    final visual = WorkbenchVisualStyle.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: visual.metaFontSize,
              fontWeight: FontWeight.w700,
              color: surface.mutedForegroundColor,
            ),
          ),
          SizedBox(width: visual.compactGap - 1),
          Text(
            value,
            style: TextStyle(
              fontSize: visual.compactLabelFontSize + 0.1,
              fontWeight: FontWeight.w800,
              color: surface.foregroundColor,
            ),
          ),
        ],
      ),
    );
  }
}
