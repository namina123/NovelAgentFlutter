import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../contracts/workbench_project_panel_action_handler.dart';
import '../models/workbench_agent_panel_view_data.dart';
import 'project_panel_action_tile.dart';
import 'resource_panel_section.dart';
import 'workbench_desktop_style.dart';
import 'workbench_visual_style.dart';

class WorkbenchAgentPanel extends StatelessWidget {
  const WorkbenchAgentPanel({
    super.key,
    required this.viewData,
    required this.resourceHandler,
  });

  final WorkbenchAgentPanelViewData viewData;
  final WorkbenchProjectPanelActionHandler resourceHandler;

  @override
  Widget build(BuildContext context) {
    final style = WorkbenchDesktopStyle.of(context);
    final surface = context.novelThemeSurfaces.sidebar;
    final visual = WorkbenchVisualStyle.of(context);
    return SingleChildScrollView(
      padding: visual.panelPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '协作',
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
          ResourcePanelSection(
            title: '当前协作摘要',
            emphasized: true,
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
                  onPressed: viewData.projectAgentGroupPanel.canConfigure
                      ? resourceHandler.onProjectAgentGroupRequested
                      : resourceHandler.onOpenProjectRequested,
                ),
              ],
            ),
          ),
          SizedBox(height: style.sectionGap),
          ResourcePanelSection(
            title: '当前会话分工',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AgentFact(label: '当前智能体', value: viewData.currentAgentLabel),
                const SizedBox(height: 8),
                _AgentFact(label: '项目基线组', value: viewData.currentGroupLabel),
                const SizedBox(height: 8),
                _AgentFact(label: '组主智能体', value: viewData.primaryAgentLabel),
                if (viewData.currentAgentDescription.trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    viewData.currentAgentDescription,
                    style: TextStyle(
                      fontSize: visual.bodyFontSize,
                      height: visual.bodyLineHeight,
                      fontWeight: FontWeight.w600,
                      color: surface.mutedForegroundColor,
                    ),
                  ),
                ],
                if (viewData.canSwitchAgent &&
                    viewData.currentAgentOptionCount > 1) ...[
                  const SizedBox(height: 8),
                  Text(
                    '当前项目已接入 ${viewData.currentAgentOptionCount} 个可供会话使用的智能体。',
                    style: TextStyle(
                      fontSize: visual.metaFontSize,
                      height: visual.bodyLineHeight,
                      fontWeight: FontWeight.w600,
                      color: surface.mutedForegroundColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: style.sectionGap),
          ResourcePanelSection(
            title: '智能体工作入口',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: viewData.agentWorkspaceActions
                  .map(
                    (action) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ProjectPanelActionTile(
                        icon: action.icon,
                        title: action.title,
                        description: action.description,
                        onPressed: _handlerForAction(action.actionId),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
        ],
      ),
    );
  }

  VoidCallback _handlerForAction(String actionId) {
    return switch (actionId) {
      'agent_skill_loadout' =>
        resourceHandler.onCurrentAgentSkillLoadoutRequested,
      'project_expression_constraints' =>
        resourceHandler.onCurrentAgentExpressionConstraintsRequested,
      _ => resourceHandler.onOpenProjectRequested,
    };
  }
}

class _AgentFact extends StatelessWidget {
  const _AgentFact({required this.label, required this.value});

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
