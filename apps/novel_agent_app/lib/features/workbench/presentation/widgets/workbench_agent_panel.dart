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
          _AgentOverviewBlock(
            title: viewData.currentAgentLabel.trim().isEmpty
                ? '协作'
                : viewData.currentAgentLabel,
            subtitle: viewData.projectName.trim().isEmpty
                ? '尚未打开项目'
                : viewData.projectName,
            badges: [
              if (viewData.currentGroupLabel.trim().isNotEmpty)
                viewData.currentGroupLabel,
              if (viewData.primaryAgentLabel.trim().isNotEmpty)
                viewData.primaryAgentLabel,
            ],
          ),
          SizedBox(height: style.headerGap),
          ResourcePanelSection(
            title: '协作概览',
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
                  showDescription: false,
                  onPressed: viewData.projectAgentGroupPanel.canConfigure
                      ? resourceHandler.onProjectAgentGroupRequested
                      : resourceHandler.onOpenProjectRequested,
                ),
              ],
            ),
          ),
          SizedBox(height: style.sectionGap),
          ResourcePanelSection(
            title: '当前分工',
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
            title: '工作入口',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: viewData.agentWorkspaceActions
                  .asMap()
                  .entries
                  .map(
                    (entry) => Padding(
                      padding: EdgeInsets.only(
                        bottom:
                            entry.key ==
                                viewData.agentWorkspaceActions.length - 1
                            ? 0
                            : 8,
                      ),
                      child: ProjectPanelActionTile(
                        icon: entry.value.icon,
                        title: entry.value.title,
                        description: entry.value.description,
                        showDescription: false,
                        onPressed: _handlerForAction(entry.value.actionId),
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
            fontWeight: FontWeight.w800,
            color: surface.foregroundColor,
          ),
        ),
      ],
    );
  }
}

class _AgentOverviewBlock extends StatelessWidget {
  const _AgentOverviewBlock({
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
