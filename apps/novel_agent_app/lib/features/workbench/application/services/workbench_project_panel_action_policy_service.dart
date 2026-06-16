import 'package:flutter/material.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

import '../../presentation/models/workbench_project_panel_action_view_data.dart';

class WorkbenchProjectPanelActionPolicyService {
  const WorkbenchProjectPanelActionPolicyService();

  List<WorkbenchProjectPanelActionViewData> primaryActions({
    required bool hasActiveProject,
    String projectTypeId = '',
    required EntryAvailabilityDecision projectTypeTransitionAvailability,
  }) {
    if (!hasActiveProject) {
      return const <WorkbenchProjectPanelActionViewData>[
        WorkbenchProjectPanelActionViewData(
          icon: Icons.folder_open_outlined,
          title: '打开项目',
          description: '进入已有项目并继续当前协作上下文。',
          actionId: WorkbenchProjectPanelActionIds.openProject,
        ),
        WorkbenchProjectPanelActionViewData(
          icon: Icons.add_business_outlined,
          title: '新建项目',
          description: '创建一个新的项目工作区并开始协作。',
          actionId: WorkbenchProjectPanelActionIds.createProject,
        ),
      ];
    }
    final actions = <WorkbenchProjectPanelActionViewData>[
      const WorkbenchProjectPanelActionViewData(
        icon: Icons.badge_outlined,
        title: '项目信息',
        description: '查看或调整当前项目基础信息与关键元数据。',
        actionId: WorkbenchProjectPanelActionIds.editProjectInfo,
      ),
      ..._projectTypeTransitionAction(
        projectTypeId,
        projectTypeTransitionAvailability,
      ),
      const WorkbenchProjectPanelActionViewData(
        icon: Icons.refresh_rounded,
        title: '刷新项目',
        description: '重新读取当前项目资源树、文档与相关状态。',
        actionId: WorkbenchProjectPanelActionIds.refreshProject,
      ),
    ];
    return List<WorkbenchProjectPanelActionViewData>.unmodifiable(actions);
  }

  List<WorkbenchProjectPanelActionViewData> assetActions({
    required bool hasActiveProject,
  }) {
    if (!hasActiveProject) {
      return const <WorkbenchProjectPanelActionViewData>[];
    }
    return const <WorkbenchProjectPanelActionViewData>[
      WorkbenchProjectPanelActionViewData(
        icon: Icons.auto_awesome_mosaic_outlined,
        title: '项目资产',
        description: '查看和整理当前项目的风格、表达限制、伏笔、时间线与关系。',
        actionId: WorkbenchProjectPanelActionIds.projectAssets,
      ),
    ];
  }

  List<WorkbenchProjectPanelActionViewData> _projectTypeTransitionAction(
    String projectTypeId,
    EntryAvailabilityDecision projectTypeTransitionAvailability,
  ) {
    // 中文注释: 类型互转入口只对 first phase 的写作类型开放，知识库与其他项目类型不应露出错误入口。
    final normalizedProjectTypeId = projectTypeId.trim();
    if (normalizedProjectTypeId != 'novel' &&
        normalizedProjectTypeId != 'long_novel') {
      return const <WorkbenchProjectPanelActionViewData>[];
    }
    if (projectTypeTransitionAvailability.isHidden) {
      return const <WorkbenchProjectPanelActionViewData>[];
    }
    final description = normalizedProjectTypeId == 'novel'
        ? '将当前普通小说切换为长篇长任务，存储策略保持不变。'
        : '将当前长篇长任务切回普通小说，存储策略保持不变。';
    return <WorkbenchProjectPanelActionViewData>[
      WorkbenchProjectPanelActionViewData(
        icon: Icons.compare_arrows_rounded,
        title: '项目类型转换',
        description: description,
        actionId: WorkbenchProjectPanelActionIds.transitionProjectType,
        isEnabled: projectTypeTransitionAvailability.isAvailable,
        disabledReason: projectTypeTransitionAvailability.userReason,
      ),
    ];
  }
}

class WorkbenchProjectPanelActionIds {
  static const String openProject = 'open_project';
  static const String createProject = 'create_project';
  static const String editProjectInfo = 'edit_project_info';
  static const String transitionProjectType = 'transition_project_type';
  static const String refreshProject = 'refresh_project';
  static const String projectAssets = 'project_assets';
}
