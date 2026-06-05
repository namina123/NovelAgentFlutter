import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../application/services/workbench_project_panel_action_policy_service.dart';
import '../contracts/workbench_project_panel_action_handler.dart';
import '../models/workbench_project_panel_action_view_data.dart';
import '../models/workbench_project_panel_view_data.dart';
import 'project_panel_action_tile.dart';
import 'workbench_desktop_style.dart';
import 'workbench_visual_style.dart';

class WorkbenchProjectPanel extends StatelessWidget {
  const WorkbenchProjectPanel({
    super.key,
    required this.viewData,
    required this.resourceHandler,
  });

  final WorkbenchProjectPanelViewData viewData;
  final WorkbenchProjectPanelActionHandler resourceHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 项目面板只承接当前项目的资料、规则和配置入口，不再混入会话设置或额外中心导航。
    final style = WorkbenchDesktopStyle.of(context);
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    return SingleChildScrollView(
      padding: visual.panelPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '项目',
            style: TextStyle(
              fontSize: visual.titleFontSize,
              height: visual.titleLineHeight,
              fontWeight: FontWeight.w800,
              color: surface.foregroundColor,
            ),
          ),
          SizedBox(height: visual.microGap),
          Text(
            viewData.projectName.trim().isEmpty
                ? '尚未打开项目'
                : viewData.projectName,
            style: TextStyle(
              fontSize: visual.sectionTitleFontSize,
              fontWeight: FontWeight.w600,
              color: surface.mutedForegroundColor,
            ),
          ),
          SizedBox(height: style.headerGap),
          _ProjectPanelSection(
            title: '项目摘要',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (viewData.projectSubtitle.trim().isNotEmpty) ...[
                  Text(
                    viewData.projectSubtitle,
                    style: TextStyle(
                      fontSize: visual.bodyFontSize,
                      height: visual.bodyLineHeight,
                      fontWeight: FontWeight.w600,
                      color: surface.mutedForegroundColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
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
          SizedBox(height: style.sectionGap),
          _ProjectPanelSection(
            title: viewData.hasActiveProject ? '当前项目动作' : '开始项目',
            child: Column(
              children: viewData.primaryActions
                  .map(
                    (action) => ProjectPanelActionTile(
                      icon: action.icon,
                      title: action.title,
                      description: action.description,
                      onPressed: () => _handleAction(action),
                    ),
                  )
                  .toList(growable: false),
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
              child: Column(
                children: viewData.assetActions
                    .map(
                      (action) => ProjectPanelActionTile(
                        icon: action.icon,
                        title: action.title,
                        description: action.description,
                        onPressed: () => _handleAction(action),
                      ),
                    )
                    .toList(growable: false),
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
            fontWeight: FontWeight.w700,
            color: surface.mutedForegroundColor,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
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
            fontWeight: FontWeight.w700,
            color: surface.foregroundColor,
          ),
        ),
      ],
    );
  }
}
