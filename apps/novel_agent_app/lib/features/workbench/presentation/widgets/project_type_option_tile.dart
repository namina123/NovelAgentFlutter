import 'package:flutter/material.dart';

import '../models/project_type_option_view_data.dart';
import 'project_selection_option_card.dart';

class ProjectTypeOptionTile extends StatelessWidget {
  const ProjectTypeOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ProjectTypeOptionViewData option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 项目类型展示复用共享选择卡片，避免三套近似样式继续各自写死。
    return ProjectSelectionOptionCard(
      title: option.title,
      description: option.description,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}
