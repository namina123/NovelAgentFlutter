import '../../presentation/models/workbench_navigation_panel_id.dart';
import '../../presentation/models/workbench_side_panel_contract.dart';
import '../../presentation/models/workbench_side_panel_entry_kind.dart';

class WorkbenchSidePanelContractService {
  const WorkbenchSidePanelContractService();

  List<WorkbenchSidePanelContract> contracts() {
    return const <WorkbenchSidePanelContract>[
      WorkbenchSidePanelContract(
        panelId: WorkbenchNavigationPanelId.files,
        label: '文件',
        tooltip: '项目文件与资源树',
        objectTitle: '文件',
        summary: '只保留文件操作和资源树，不放项目配置入口。',
        responsibilities: <String>['资源树浏览与文件选择', '新建文件、文件夹、章节与导入', '当前文档保存'],
        allowedEntryKinds: <WorkbenchSidePanelEntryKind>[
          WorkbenchSidePanelEntryKind.fileOperation,
        ],
        disallowedEntryKinds: <WorkbenchSidePanelEntryKind>[
          WorkbenchSidePanelEntryKind.projectScopedConfiguration,
          WorkbenchSidePanelEntryKind.systemCenterEntry,
          WorkbenchSidePanelEntryKind.projectAgnosticEntry,
          WorkbenchSidePanelEntryKind.jumpOnlyEntry,
        ],
      ),
      WorkbenchSidePanelContract(
        panelId: WorkbenchNavigationPanelId.project,
        label: '项目',
        tooltip: '当前项目摘要与协作设置',
        objectTitle: '项目',
        summary: '只保留当前项目摘要、协作设置和少量项目动作。',
        responsibilities: <String>['当前项目摘要', '项目协作设置', '项目内少量必要动作'],
        allowedEntryKinds: <WorkbenchSidePanelEntryKind>[
          WorkbenchSidePanelEntryKind.projectSummary,
          WorkbenchSidePanelEntryKind.projectScopedAction,
          WorkbenchSidePanelEntryKind.projectScopedConfiguration,
        ],
        disallowedEntryKinds: <WorkbenchSidePanelEntryKind>[
          WorkbenchSidePanelEntryKind.fileOperation,
          WorkbenchSidePanelEntryKind.longTaskSummary,
          WorkbenchSidePanelEntryKind.longTaskStationEntry,
          WorkbenchSidePanelEntryKind.systemCenterEntry,
          WorkbenchSidePanelEntryKind.projectAgnosticEntry,
          WorkbenchSidePanelEntryKind.jumpOnlyEntry,
        ],
      ),
      WorkbenchSidePanelContract(
        panelId: WorkbenchNavigationPanelId.agent,
        label: '智能体',
        tooltip: '当前会话智能体与项目协作设置',
        objectTitle: '智能体',
        summary: '只保留当前会话智能体摘要与项目协作设置，不重复整套独立页面。',
        responsibilities: <String>['当前会话智能体摘要', '项目协作设置', '默认组配置入口'],
        allowedEntryKinds: <WorkbenchSidePanelEntryKind>[
          WorkbenchSidePanelEntryKind.conversationAgentSummary,
          WorkbenchSidePanelEntryKind.projectScopedConfiguration,
        ],
        disallowedEntryKinds: <WorkbenchSidePanelEntryKind>[
          WorkbenchSidePanelEntryKind.fileOperation,
          WorkbenchSidePanelEntryKind.projectScopedAction,
          WorkbenchSidePanelEntryKind.longTaskSummary,
          WorkbenchSidePanelEntryKind.longTaskStationEntry,
          WorkbenchSidePanelEntryKind.systemCenterEntry,
          WorkbenchSidePanelEntryKind.projectAgnosticEntry,
          WorkbenchSidePanelEntryKind.jumpOnlyEntry,
        ],
      ),
    ];
  }

  WorkbenchSidePanelContract contractOf(WorkbenchNavigationPanelId panelId) {
    for (final contract in contracts()) {
      if (contract.panelId == panelId) {
        return contract;
      }
    }
    return contracts().first;
  }
}
