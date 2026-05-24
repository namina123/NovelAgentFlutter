import 'package:flutter/material.dart';

import '../../../../../shared/widgets/toolbar_icon_button.dart';

class ProjectActionGroup extends StatelessWidget {
  const ProjectActionGroup({
    super.key,
    required this.onCreateProjectRequested,
    required this.onOpenProjectRequested,
    required this.onEditProjectInfoRequested,
    required this.onRefreshRequested,
  });

  final VoidCallback onCreateProjectRequested;
  final VoidCallback onOpenProjectRequested;
  final VoidCallback onEditProjectInfoRequested;
  final VoidCallback onRefreshRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 项目级动作压成小型工具条，给资源树留出主视区而不是堆一大片大按钮。
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ToolbarIconButton(
          icon: Icons.add_business_outlined,
          tooltip: '新建项目',
          tone: ToolbarIconTone.warm,
          onPressed: onCreateProjectRequested,
        ),
        ToolbarIconButton(
          icon: Icons.folder_open_outlined,
          tooltip: '打开项目',
          onPressed: onOpenProjectRequested,
        ),
        ToolbarIconButton(
          icon: Icons.badge_outlined,
          tooltip: '项目信息',
          onPressed: onEditProjectInfoRequested,
        ),
        ToolbarIconButton(
          icon: Icons.refresh_rounded,
          tooltip: '刷新项目',
          onPressed: onRefreshRequested,
        ),
      ],
    );
  }
}
