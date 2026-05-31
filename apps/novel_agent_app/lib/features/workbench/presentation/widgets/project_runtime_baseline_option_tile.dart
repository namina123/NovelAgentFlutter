import 'package:flutter/material.dart';

import '../models/project_runtime_baseline_option_view_data.dart';
import 'project_selection_option_card.dart';

class ProjectRuntimeBaselineOptionTile extends StatelessWidget {
  const ProjectRuntimeBaselineOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ProjectRuntimeBaselineOptionViewData option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 运行基准展示复用共享选择卡片，保证三种选择列表在主题和可读性上统一。
    return ProjectSelectionOptionCard(
      title: option.title,
      description: option.description,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}
