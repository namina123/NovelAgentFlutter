import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/compact_action_grid.dart';

class ResourceUtilityStrip extends StatelessWidget {
  const ResourceUtilityStrip({
    super.key,
    required this.onAgentEcosystemRequested,
    required this.onTasksRequested,
    required this.onReviewsRequested,
    required this.onTemplatesRequested,
  });

  final VoidCallback onAgentEcosystemRequested;
  final VoidCallback onTasksRequested;
  final VoidCallback onReviewsRequested;
  final VoidCallback onTemplatesRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 工作区快捷入口独立出来，避免资源面板把跨页面跳转和文件树职责缠在一起。
    return CompactActionGrid(
      children: [
        ActionButton(
          label: '智能体',
          icon: Icons.groups_2_outlined,
          compact: true,
          onPressed: onAgentEcosystemRequested,
        ),
        ActionButton(
          label: '任务',
          icon: Icons.checklist_rounded,
          tone: ActionButtonTone.neutral,
          compact: true,
          onPressed: onTasksRequested,
        ),
        ActionButton(
          label: '审稿',
          icon: Icons.warning_amber_rounded,
          tone: ActionButtonTone.warm,
          compact: true,
          onPressed: onReviewsRequested,
        ),
        ActionButton(
          label: '模板',
          icon: Icons.copy_all_outlined,
          tone: ActionButtonTone.neutral,
          compact: true,
          onPressed: onTemplatesRequested,
        ),
      ],
    );
  }
}
