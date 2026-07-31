import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

class ResourceTreeEmptyState extends StatelessWidget {
  const ResourceTreeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    // 中文注释: 目录空态继续保持轻量，避免在空项目里出现一张存在感过强的提示卡。
    final surface = context.novelThemeSurfaces.panel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: surface.backgroundColor.withValues(alpha: 0.42),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: surface.borderColor.withValues(alpha: 0.34),
                ),
              ),
              child: Icon(
                Icons.folder_open_outlined,
                size: 18,
                color: surface.mutedForegroundColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '当前项目还没有目录内容。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                fontWeight: FontWeight.w600,
                color: surface.mutedForegroundColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '从上方新建、导入，或创建章节后会在这里出现。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                height: 1.55,
                fontWeight: FontWeight.w500,
                color: surface.mutedForegroundColor.withValues(alpha: 0.86),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
