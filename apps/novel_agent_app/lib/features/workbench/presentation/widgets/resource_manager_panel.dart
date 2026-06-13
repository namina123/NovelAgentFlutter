import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../contracts/pending_research_action_handler.dart';
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
    this.pendingResearchActionHandler,
  });

  final WorkbenchResourceViewData viewData;
  final WorkbenchFilePanelActionHandler actionHandler;
  final PendingResearchActionHandler? pendingResearchActionHandler;

  @override
  Widget build(BuildContext context) {
    final visual = WorkbenchVisualStyle.of(context);
    final entries = viewData.resourceEntries;
    final directoryCount = entries.where((entry) => entry.isDirectory).length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = constraints.maxWidth < 300 ? 6.0 : 10.0;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            6,
            horizontalPadding,
            4,
          ),
          child: CustomScrollView(
            key: const ValueKey<String>('resource_manager_scroll_view'),
            slivers: [
              SliverToBoxAdapter(
                child: ResourceManagerHeader(
                  title: viewData.projectName,
                  subtitle: viewData.projectSubtitle,
                  itemCount: entries.length,
                  directoryCount: directoryCount,
                  fileCount: entries.length - directoryCount,
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(height: visual.compactGap + 2),
              ),
              SliverToBoxAdapter(
                child: _ResourceInlineTools(
                  itemCount: entries.length,
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
                SliverToBoxAdapter(
                  child: SizedBox(height: visual.compactGap + 2),
                ),
                SliverToBoxAdapter(
                  child: ResourceInformationSection(
                    viewData: viewData.informationViewData,
                    actionHandler: actionHandler,
                    pendingResearchActionHandler: pendingResearchActionHandler,
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: SizedBox(height: visual.compactGap + 1),
              ),
              SliverToBoxAdapter(
                child: ResourcePanelSection(
                  title: '浏览',
                  trailing: Text(
                    '$directoryCount 个分组',
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  padding: const EdgeInsets.fromLTRB(0, 2, 0, 0),
                  emphasized: false,
                  child: ResourceTreeCard(
                    entries: entries,
                    onEntrySelected: actionHandler.onResourceEntrySelected,
                    embeddedInScrollView: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ResourceInlineTools extends StatelessWidget {
  const _ResourceInlineTools({required this.itemCount, required this.child});

  final int itemCount;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 188;
        final inset = compact ? 3.0 : 8.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: surface.backgroundColor.withValues(
              alpha: compact ? 0.02 : 0.04,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(inset, inset, inset, inset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 3 : 0),
                  child: Text(
                    '快速操作',
                    style: TextStyle(
                      fontSize: visual.compactLabelFontSize,
                      fontWeight: FontWeight.w800,
                      color: surface.mutedForegroundColor,
                      letterSpacing: 0.08,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 4 : visual.microGap + 3),
                child,
              ],
            ),
          ),
        );
      },
    );
  }
}
