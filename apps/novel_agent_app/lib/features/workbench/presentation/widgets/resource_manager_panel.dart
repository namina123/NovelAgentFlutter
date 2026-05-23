import 'package:flutter/material.dart';

import '../contracts/resource_manager_action_handler.dart';
import '../models/workbench_view_data.dart';
import 'file_tool_group.dart';
import 'project_action_group.dart';
import 'resource_manager_header.dart';
import 'resource_tree_card.dart';
import 'resource_utility_strip.dart';

class ResourceManagerPanel extends StatelessWidget {
  const ResourceManagerPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final WorkbenchViewData viewData;
  final ResourceManagerActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 资源面板只处理项目入口、文件树和工作区快捷入口，不承接文档和会话逻辑。
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ResourceManagerHeader(
            title: viewData.projectName,
            subtitle: viewData.projectSubtitle,
            onSettingsPressed: actionHandler.onModelSettingsRequested,
          ),
          const SizedBox(height: 10),
          ProjectActionGroup(
            onCreateProjectRequested: actionHandler.onCreateProjectRequested,
            onOpenProjectRequested: actionHandler.onOpenProjectRequested,
            onEditProjectInfoRequested:
                actionHandler.onEditProjectInfoRequested,
            onRefreshRequested: actionHandler.onRefreshFilesRequested,
          ),
          const SizedBox(height: 8),
          FileToolGroup(
            onCreateFileRequested: actionHandler.onCreateFileRequested,
            onCreateFolderRequested: actionHandler.onCreateFolderRequested,
            onImportRequested: actionHandler.onImportRequested,
            onCreateChapterRequested: actionHandler.onCreateChapterRequested,
            onSaveCurrentRequested: actionHandler.onSaveCurrentRequested,
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ResourceTreeCard(
              entries: viewData.resourceEntries,
              onEntrySelected: actionHandler.onResourceEntrySelected,
            ),
          ),
          const SizedBox(height: 8),
          ResourceUtilityStrip(
            onAgentEcosystemRequested: actionHandler.onAgentEcosystemRequested,
            onTasksRequested: actionHandler.onTasksRequested,
            onReviewsRequested: actionHandler.onReviewsRequested,
            onTemplatesRequested: actionHandler.onTemplatesRequested,
          ),
        ],
      ),
    );
  }
}
