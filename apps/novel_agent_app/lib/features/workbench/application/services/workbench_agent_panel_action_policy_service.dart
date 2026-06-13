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
          description: '打开项目后，可为当前智能体查看和整理项目内的技能组合。',
          actionId: 'agent_skill_loadout',
        ),
        WorkbenchProjectPanelActionViewData(
          icon: Icons.rule_folder_outlined,
          title: '表达限制',
          description: '打开项目后，可进入项目级写作约束系统，查看内置或自定义表达限制方案，并按当前智能体定向绑定。',
          actionId: 'project_expression_constraints',
        ),
      ];
    }
    return const <WorkbenchProjectPanelActionViewData>[
      WorkbenchProjectPanelActionViewData(
        icon: Icons.auto_fix_high_outlined,
        title: '技能装载',
        description: '查看当前智能体在本项目中的技能组合、补充技能和禁用项。',
        actionId: 'agent_skill_loadout',
      ),
      WorkbenchProjectPanelActionViewData(
        icon: Icons.rule_folder_outlined,
        title: '表达限制',
        description: '进入项目级写作约束系统，管理内置或自定义表达限制方案，并按当前智能体进一步定向绑定。',
        actionId: 'project_expression_constraints',
      ),
    ];
  }
}
