import 'package:flutter/material.dart';

import '../../presentation/models/workbench_project_panel_action_view_data.dart';

class WorkbenchAgentPanelActionPolicyService {
  const WorkbenchAgentPanelActionPolicyService();

  List<WorkbenchProjectPanelActionViewData> workspaceActions({
    required bool hasActiveProject,
  }) {
    if (!hasActiveProject) {
      return const <WorkbenchProjectPanelActionViewData>[
        WorkbenchProjectPanelActionViewData(
          icon: Icons.auto_fix_high_outlined,
          title: '技能装载',
          description: '查看当前项目可用的技能组合。',
          actionId: 'agent_skill_loadout',
        ),
        WorkbenchProjectPanelActionViewData(
          icon: Icons.rule_folder_outlined,
          title: '表达限制',
          description: '查看和调整写作约束方案。',
          actionId: 'project_expression_constraints',
        ),
      ];
    }
    return const <WorkbenchProjectPanelActionViewData>[
      WorkbenchProjectPanelActionViewData(
        icon: Icons.auto_fix_high_outlined,
        title: '技能装载',
        description: '查看当前项目的技能组合。',
        actionId: 'agent_skill_loadout',
      ),
      WorkbenchProjectPanelActionViewData(
        icon: Icons.rule_folder_outlined,
        title: '表达限制',
        description: '查看和调整写作约束方案。',
        actionId: 'project_expression_constraints',
      ),
    ];
  }
}
