import 'package:flutter/material.dart';

import '../models/project_knowledge_base_branch_option_view_data.dart';
import 'project_selection_option_card.dart';

class ProjectKnowledgeBaseBranchOptionTile extends StatelessWidget {
  const ProjectKnowledgeBaseBranchOptionTile({
    super.key,
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final ProjectKnowledgeBaseBranchOptionViewData option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ProjectSelectionOptionCard(
      title: option.title,
      description: option.description,
      isSelected: isSelected,
      onTap: onTap,
    );
  }
}
