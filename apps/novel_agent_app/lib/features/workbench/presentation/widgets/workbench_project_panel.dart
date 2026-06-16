import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../application/services/workbench_project_panel_action_policy_service.dart';
import '../contracts/workbench_project_panel_action_handler.dart';
import '../models/workbench_project_panel_action_view_data.dart';
import '../models/workbench_project_panel_view_data.dart';
import 'project_long_task_summary_panel.dart';
import 'project_panel_action_tile.dart';
import 'workbench_desktop_style.dart';
import 'workbench_visual_style.dart';

class WorkbenchProjectPanel extends StatelessWidget {
  const WorkbenchProjectPanel({
    super.key,
    required this.viewData,
    required this.resourceHandler,
    this.onOpenLongTaskStationRequested,
  });

  final WorkbenchProjectPanelViewData viewData;
  final WorkbenchProjectPanelActionHandler resourceHandler;
  final VoidCallback? onOpenLongTaskStationRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 项目面板继续收敛到“当前工程概况 + 命令入口”，更像 IDE 的侧栏概览而不是设置页。
    final style = WorkbenchDesktopStyle.of(context);
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    return SingleChildScrollView(
      padding: visual.panelPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelOverviewBlock(
            title: viewData.projectName.trim().isEmpty
                ? '尚未打开项目'
                : viewData.projectName,
            subtitle: viewData.projectSubtitle,
            badges: [
              if (viewData.workflowTitle.trim().isNotEmpty)
                viewData.workflowTitle,
              if (viewData.modelLabel.trim().isNotEmpty) viewData.modelLabel,
            ],
          ),
          SizedBox(height: style.headerGap),
          _ProjectPanelSection(
            title: '项目摘要',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProjectPanelMetaLine(
                  label: '工作流',
                  value: viewData.workflowTitle,
                ),
                const SizedBox(height: 8),
                _ProjectPanelMetaLine(label: '模型', value: viewData.modelLabel),
                const SizedBox(height: 8),
                _ProjectPanelMetaLine(
                  label: '智能体组',
                  value: viewData.agentGroupLabel,
                ),
                const SizedBox(height: 8),
                _ProjectPanelMetaLine(
                  label: '主智能体',
                  value: viewData.primaryAgentLabel,
                ),
                if (viewData.workflowDescription.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    viewData.workflowDescription,
                    style: TextStyle(
                      fontSize: visual.bodyFontSize,
                      height: visual.bodyLineHeight,
                      color: surface.mutedForegroundColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (viewData.projectLongTaskSummary != null) ...[
            SizedBox(height: style.sectionGap),
            _ProjectPanelSection(
              title: '长任务现场',
              child: ProjectLongTaskSummaryPanel(
                summary: viewData.projectLongTaskSummary!,
                onOpenStationRequested: onOpenLongTaskStationRequested,
              ),
            ),
          ],
          SizedBox(height: style.sectionGap),
          _ProjectPanelSection(
            title: viewData.hasActiveProject ? '当前项目动作' : '开始项目',
            child: _ProjectPanelActionList(
              actions: viewData.primaryActions,
              onAction: _handleAction,
            ),
          ),
          SizedBox(height: style.sectionGap),
          _ProjectPanelSection(
            title: '当前协作摘要',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewData.projectAgentGroupPanel.summary,
                  style: TextStyle(
                    fontSize: visual.bodyFontSize,
                    height: visual.bodyLineHeight,
                    color: surface.mutedForegroundColor,
                  ),
                ),
                const SizedBox(height: 10),
                ProjectPanelActionTile(
                  icon: Icons.group_work_outlined,
                  title: '协作设置',
                  description:
                      viewData.projectAgentGroupPanel.actionDescription,
                  onPressed: resourceHandler.onProjectAgentGroupRequested,
                ),
              ],
            ),
          ),
          if (viewData.assetActions.isNotEmpty) ...[
            SizedBox(height: style.sectionGap),
            _ProjectPanelSection(
              title: '项目资料',
              child: _ProjectPanelActionList(
                actions: viewData.assetActions,
                onAction: _handleAction,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _handleAction(WorkbenchProjectPanelActionViewData action) {
    switch (action.actionId) {
      case WorkbenchProjectPanelActionIds.openProject:
        resourceHandler.onOpenProjectRequested();
        return;
      case WorkbenchProjectPanelActionIds.createProject:
        resourceHandler.onCreateProjectRequested();
        return;
      case WorkbenchProjectPanelActionIds.editProjectInfo:
        resourceHandler.onEditProjectInfoRequested();
        return;
      case WorkbenchProjectPanelActionIds.transitionProjectType:
        resourceHandler.onProjectTypeTransitionRequested();
        return;
      case WorkbenchProjectPanelActionIds.refreshProject:
        resourceHandler.onRefreshFilesRequested();
        return;
      case WorkbenchProjectPanelActionIds.projectAssets:
        resourceHandler.onProjectAssetsRequested();
        return;
    }
  }
}

class _ProjectPanelSection extends StatelessWidget {
  const _ProjectPanelSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: visual.compactLabelFontSize,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.24,
            color: surface.mutedForegroundColor,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _PanelOverviewBlock extends StatelessWidget {
  const _PanelOverviewBlock({
    required this.title,
    required this.subtitle,
    required this.badges,
  });

  final String title;
  final String subtitle;
  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    final visibleBadges = badges
        .map((badge) => badge.trim())
        .where((badge) => badge.isNotEmpty)
        .toList(growable: false);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 9),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: surface.borderColor.withValues(alpha: 0.16),
          width: surface.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: visual.titleFontSize,
              height: visual.titleLineHeight,
              fontWeight: FontWeight.w800,
              color: surface.foregroundColor,
            ),
          ),
          if (subtitle.trim().isNotEmpty) ...[
            SizedBox(height: visual.microGap),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: visual.metaFontSize,
                height: visual.bodyLineHeight,
                color: surface.mutedForegroundColor,
              ),
            ),
          ],
          if (visibleBadges.isNotEmpty) ...[
            SizedBox(height: visual.compactGap + 1),
            Wrap(
              spacing: visual.microGap + 2,
              runSpacing: visual.microGap + 2,
              children: [
                for (final badge in visibleBadges)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: surface.backgroundColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: visual.metaFontSize,
                        fontWeight: FontWeight.w700,
                        color: surface.mutedForegroundColor,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ProjectPanelMetaLine extends StatelessWidget {
  const _ProjectPanelMetaLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: visual.metaFontSize,
            fontWeight: FontWeight.w700,
            color: surface.mutedForegroundColor,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value.trim().isEmpty ? '未设置' : value,
          style: TextStyle(
            fontSize: visual.sectionTitleFontSize,
            fontWeight: FontWeight.w800,
            color: surface.foregroundColor,
          ),
        ),
      ],
    );
  }
}

class _ProjectPanelActionList extends StatelessWidget {
  const _ProjectPanelActionList({
    required this.actions,
    required this.onAction,
  });

  final List<WorkbenchProjectPanelActionViewData> actions;
  final ValueChanged<WorkbenchProjectPanelActionViewData> onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: actions
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final action = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == actions.length - 1 ? 0 : 8,
              ),
              child: ProjectPanelActionTile(
                icon: action.icon,
                title: action.title,
                description: action.description,
                onPressed: () => onAction(action),
                isEnabled: action.isEnabled,
                disabledReason: action.disabledReason,
              ),
            );
          })
          .toList(growable: false),
    );
  }
}
