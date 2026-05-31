import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';

class ResourceTreeEmptyState extends StatelessWidget {
  const ResourceTreeEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    // 中文注释: 目录空态独立出来，后续如果要加“从模板创建”之类的壳，不用再塞回目录卡片本身。
    final surface = context.novelThemeSurfaces.panel;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          '当前项目还没有目录内容。',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.5,
            fontWeight: FontWeight.w600,
            color: surface.mutedForegroundColor,
          ),
        ),
      ),
    );
  }
}
