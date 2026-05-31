import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import 'workbench_desktop_style.dart';
import 'workbench_visual_style.dart';

class ResourceManagerHeader extends StatelessWidget {
  const ResourceManagerHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 文件面板头部只保留项目识别信息，不再混入错误的模型设置入口。
    final style = WorkbenchDesktopStyle.of(context);
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: visual.titleFontSize,
            height: visual.titleLineHeight,
            fontWeight: FontWeight.w800,
            color: style.foregroundColor,
          ),
        ),
        if (subtitle.trim().isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: visual.bodyFontSize,
              height: visual.bodyLineHeight,
              fontWeight: FontWeight.w600,
              color: surface.mutedForegroundColor,
            ),
          ),
        ],
      ],
    );
  }
}
