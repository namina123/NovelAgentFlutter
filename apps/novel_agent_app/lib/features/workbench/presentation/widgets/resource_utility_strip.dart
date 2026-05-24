import 'package:flutter/material.dart';

import '../../../../../shared/widgets/toolbar_icon_button.dart';

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
    // 中文注释: 底部快捷入口也保持工具条形态，缩小对目录主视区的侵占。
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ToolbarIconButton(
          icon: Icons.groups_2_outlined,
          tooltip: '智能体生态',
          onPressed: onAgentEcosystemRequested,
        ),
        ToolbarIconButton(
          icon: Icons.checklist_rounded,
          tooltip: '任务中心',
          onPressed: onTasksRequested,
        ),
        ToolbarIconButton(
          icon: Icons.warning_amber_rounded,
          tooltip: '审稿中心',
          tone: ToolbarIconTone.warm,
          onPressed: onReviewsRequested,
        ),
        ToolbarIconButton(
          icon: Icons.copy_all_outlined,
          tooltip: '提示词模板',
          onPressed: onTemplatesRequested,
        ),
      ],
    );
  }
}
