import 'package:flutter/material.dart';

import '../../presentation/models/workbench_project_panel_action_view_data.dart';

class WorkbenchProjectPanelActionPolicyService {
  const WorkbenchProjectPanelActionPolicyService();

  List<WorkbenchProjectPanelActionViewData> primaryActions({
    required bool hasActiveProject,
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
    return const <WorkbenchProjectPanelActionViewData>[
      WorkbenchProjectPanelActionViewData(
        icon: Icons.badge_outlined,
        title: '项目信息',
        description: '查看或调整当前项目基础信息与关键元数据。',
        actionId: WorkbenchProjectPanelActionIds.editProjectInfo,
      ),
      WorkbenchProjectPanelActionViewData(
        icon: Icons.refresh_rounded,
        title: '刷新项目',
        description: '重新读取当前项目资源树、文档与相关状态。',
        actionId: WorkbenchProjectPanelActionIds.refreshProject,
      ),
    ];
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
}

class WorkbenchProjectPanelActionIds {
  static const String openProject = 'open_project';
  static const String createProject = 'create_project';
  static const String editProjectInfo = 'edit_project_info';
  static const String refreshProject = 'refresh_project';
  static const String projectAssets = 'project_assets';
}
