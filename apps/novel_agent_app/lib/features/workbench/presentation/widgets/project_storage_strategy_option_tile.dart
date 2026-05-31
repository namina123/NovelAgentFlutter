import 'package:flutter/material.dart';

import '../models/project_storage_strategy_option_view_data.dart';
import 'project_selection_option_card.dart';

class ProjectStorageStrategyOptionTile extends StatelessWidget {
  const ProjectStorageStrategyOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ProjectStorageStrategyOptionViewData option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 存储策略展示复用共享选择卡片，减少主题切换时的散落硬编码。
    return ProjectSelectionOptionCard(
      title: option.title,
      description: option.description,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}
