import 'package:flutter/material.dart';

import '../contracts/workbench_file_panel_action_handler.dart';
import '../models/workbench_resource_view_data.dart';
import 'file_tool_group.dart';
import 'resource_information_section.dart';
import 'resource_manager_header.dart';
import 'resource_panel_section.dart';
import 'resource_tree_card.dart';
import 'workbench_visual_style.dart';

class ResourceManagerPanel extends StatelessWidget {
  const ResourceManagerPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final WorkbenchResourceViewData viewData;
  final WorkbenchFilePanelActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 文件面板统一改成单一 CustomScrollView，让高度收缩时不再切换滚动语义。
    final visual = WorkbenchVisualStyle.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 300 ? 8.0 : 12.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            10,
          ),
          child: CustomScrollView(
            key: const ValueKey<String>('resource_manager_scroll_view'),
            slivers: [
              SliverToBoxAdapter(
                child: ResourceManagerHeader(
                  title: viewData.projectName,
                  subtitle: viewData.projectSubtitle,
                ),
              ),
              SliverToBoxAdapter(child: SizedBox(height: visual.headerGap)),
              SliverToBoxAdapter(
                child: ResourcePanelSection(
                  title: '文件',
                  emphasized: true,
                  child: FileToolGroup(
                    onCreateFileRequested: actionHandler.onCreateFileRequested,
                    onCreateFolderRequested:
                        actionHandler.onCreateFolderRequested,
                    onImportRequested: actionHandler.onImportRequested,
                    onCreateChapterRequested:
                        actionHandler.onCreateChapterRequested,
                    onSaveCurrentRequested:
                        actionHandler.onSaveCurrentRequested,
                  ),
                ),
              ),
              if (viewData.informationViewData.hasContent) ...[
                SliverToBoxAdapter(child: SizedBox(height: visual.sectionGap)),
                SliverToBoxAdapter(
                  child: ResourceInformationSection(
                    viewData: viewData.informationViewData,
                    actionHandler: actionHandler,
                  ),
                ),
              ],
              SliverToBoxAdapter(child: SizedBox(height: visual.sectionGap)),
              SliverToBoxAdapter(
                child: ResourceTreeCard(
                  entries: viewData.resourceEntries,
                  onEntrySelected: actionHandler.onResourceEntrySelected,
                  embeddedInScrollView: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
