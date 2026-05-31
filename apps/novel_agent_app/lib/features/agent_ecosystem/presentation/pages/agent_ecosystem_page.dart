import 'package:flutter/material.dart';

import '../../../../../app/layout/adaptive_page_frame.dart';
import '../contracts/agent_ecosystem_action_handler.dart';
import '../models/agent_ecosystem_view_data.dart';
import '../widgets/agent_ecosystem_header.dart';
import '../widgets/ecosystem_browser_panel.dart';
import '../widgets/ecosystem_detail_panel.dart';
import '../widgets/ecosystem_editor_overlay.dart';
import '../widgets/ecosystem_import_overlay.dart';
import '../widgets/project_skill_loadout_detail_panel.dart';

class AgentEcosystemPage extends StatelessWidget {
  const AgentEcosystemPage({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final AgentEcosystemViewData viewData;
  final AgentEcosystemActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 生态页只组装头部、浏览区和详情区，具体导入与新建逻辑全部留给外层接口。
    final selected = _selectedEntry();

    return AdaptivePageFrame(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AgentEcosystemHeader(
                onBackRequested: actionHandler.onAgentEcosystemBackRequested,
              ),
              const SizedBox(height: 18),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 1080) {
                      return Column(
                        children: [
                          Expanded(
                            child: EcosystemBrowserPanel(
                              tabs: viewData.tabs,
                              activeTabId: viewData.activeTabId,
                              entries: viewData.entries,
                              statusMessage: viewData.statusMessage,
                              onRefreshRequested:
                                  actionHandler.onEcosystemRefreshRequested,
                              onImportPackageRequested: actionHandler
                                  .onImportEcosystemPackageRequested,
                              onGenerateIndexRequested:
                                  actionHandler.onGenerateIndexRequested,
                              onTabSelected:
                                  actionHandler.onEcosystemTabSelected,
                              onEntrySelected:
                                  actionHandler.onEcosystemEntrySelected,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(height: 280, child: _buildDetail(selected)),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: EcosystemBrowserPanel(
                            tabs: viewData.tabs,
                            activeTabId: viewData.activeTabId,
                            entries: viewData.entries,
                            statusMessage: viewData.statusMessage,
                            onRefreshRequested:
                                actionHandler.onEcosystemRefreshRequested,
                            onImportPackageRequested:
                                actionHandler.onImportEcosystemPackageRequested,
                            onGenerateIndexRequested:
                                actionHandler.onGenerateIndexRequested,
                            onTabSelected: actionHandler.onEcosystemTabSelected,
                            onEntrySelected:
                                actionHandler.onEcosystemEntrySelected,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(flex: 4, child: _buildDetail(selected)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          if (viewData.importCommand != null)
            EcosystemImportOverlay(
              viewData: viewData.importCommand!,
              actionHandler: actionHandler,
            ),
          if (viewData.editorViewData != null)
            EcosystemEditorOverlay(
              viewData: viewData.editorViewData!,
              actionHandler: actionHandler,
            ),
        ],
      ),
    );
  }

  EcosystemEntryViewData? _selectedEntry() {
    // 中文注释: 生态页在空列表状态下返回空选择，避免刚启动或尚未载入时因为 first 调用直接崩溃。
    for (final entry in viewData.entries) {
      if (entry.isSelected) {
        return entry;
      }
    }
    return viewData.entries.isEmpty ? null : viewData.entries.first;
  }

  Widget _buildDetail(EcosystemEntryViewData? entry) {
    // 中文注释: 详情区在没有条目时显示空态，保持页面结构稳定并保留创建入口。
    if (viewData.activeTabId == 'skill-loadouts') {
      return ProjectSkillLoadoutDetailPanel(
        viewData: viewData.projectSkillLoadoutViewData?.detail,
        actionHandler: actionHandler,
        projectAvailable:
            viewData.projectSkillLoadoutViewData?.projectAvailable ?? false,
      );
    }
    if (entry == null) {
      return EcosystemDetailPanel.empty(
        onCreateAgentRequested: actionHandler.onCreateAgentRequested,
        onCreateSkillRequested: actionHandler.onCreateSkillRequested,
        onCreateSkillGroupRequested: actionHandler.onCreateSkillGroupRequested,
        onCreateAgentGroupRequested: actionHandler.onCreateAgentGroupRequested,
      );
    }
    return EcosystemDetailPanel(
      entry: entry,
      onEditRequested: () {
        actionHandler.onEditEcosystemEntryRequested(entry.id);
      },
      onOpenSourceRequested: () {
        actionHandler.onOpenEcosystemEntrySourceRequested(entry.id);
      },
      onCreateAgentRequested: actionHandler.onCreateAgentRequested,
      onCreateSkillRequested: actionHandler.onCreateSkillRequested,
      onCreateSkillGroupRequested: actionHandler.onCreateSkillGroupRequested,
      onCreateAgentGroupRequested: actionHandler.onCreateAgentGroupRequested,
    );
  }
}
