import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/compact_action_grid.dart';

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
    // 中文注释: 项目级动作单独封装，确保资源面板不会因为按钮矩阵变复杂而继续膨胀。
    return CompactActionGrid(
      columnCount: 3,
      spacing: 8,
      childAspectRatio: 2.35,
      children: [
        ActionButton(
          label: '新建项目',
          icon: Icons.add_business_outlined,
          tone: ActionButtonTone.warm,
          compact: true,
          onPressed: onCreateProjectRequested,
        ),
        ActionButton(
          label: '打开项目',
          icon: Icons.folder_open_outlined,
          compact: true,
          onPressed: onOpenProjectRequested,
        ),
        ActionButton(
          label: '项目信息',
          icon: Icons.badge_outlined,
          tone: ActionButtonTone.neutral,
          compact: true,
          labelMaxLines: 2,
          onPressed: onEditProjectInfoRequested,
        ),
        ActionButton(
          label: '刷新',
          icon: Icons.refresh_rounded,
          tone: ActionButtonTone.neutral,
          compact: true,
          onPressed: onRefreshRequested,
        ),
      ],
    );
  }
}
