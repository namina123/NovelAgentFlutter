import 'package:flutter/material.dart';

import '../../application/models/opening_agent_member_summary.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/resource_manager_action_handler.dart';
import '../models/opening_agent_group_option_view_data.dart';
import '../models/project_agent_group_option_view_data.dart';
import '../models/project_agent_group_workspace_view_data.dart';
import 'opening_agent_group_picker.dart';
import 'opening_unsupported_group_panel.dart';
import '../models/opening_unsupported_group_view_data.dart';

class ProjectAgentGroupOverlay extends StatelessWidget {
  const ProjectAgentGroupOverlay({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final ProjectAgentGroupWorkspaceViewData viewData;
  final ResourceManagerActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 项目级组配置浮层是正式配置入口，只承接当前项目默认组的查看与切换，不混入 opening 其他步骤。
    final supportedGroupOptions = viewData.supportedGroups
        .map(
          (group) => OpeningAgentGroupOptionViewData(
            groupId: group.groupId,
            displayName: group.displayName,
            description: group.description,
            isCurrent: group.isCurrent,
            isDegraded: group.isDegraded,
            isStarterGroup: false,
            members: group.members,
          ),
        )
        .toList(growable: false);
    final unsupportedGroupOptions = viewData.unsupportedGroups
        .map(
          (group) => OpeningUnsupportedGroupViewData(
            groupId: group.groupId,
            displayName: group.displayName,
            description: group.description,
            reasonSummary: group.reasonSummary,
            reasonDetails: group.reasonDetails,
          ),
        )
        .toList(growable: false);
    final currentGroup = _currentGroupOf(viewData);
    return Positioned.fill(
      child: ColoredBox(
        color: Colors.black.withValues(alpha: 0.24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 760,
              maxHeight: 720,
              minWidth: 320,
            ),
            child: PanelSurface(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                viewData.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                viewData.description,
                                style: Theme.of(
                                  context,
                                ).textTheme.bodySmall?.copyWith(height: 1.5),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: actionHandler.onProjectAgentGroupDismissed,
                          icon: const Icon(Icons.close_rounded),
                          tooltip: '关闭',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _ProjectAgentGroupStatusCard(viewData: viewData),
                    const SizedBox(height: 12),
                    Text(
                      viewData.selectionHint,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (viewData.hasSelectableGroups)
                              OpeningAgentGroupPicker(
                                options: supportedGroupOptions,
                                currentGroupDisplayName:
                                    viewData.currentGroupLabel,
                                onSelected:
                                    actionHandler.onProjectAgentGroupSelected,
                              )
                            else
                              Text(
                                '当前没有可直接使用的智能体组。',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            if (currentGroup != null) ...[
                              const SizedBox(height: 12),
                              _ProjectAgentGroupMembersPanel(
                                title: '当前组成员',
                                members: currentGroup.members,
                              ),
                            ],
                            if (viewData.unsupportedGroups.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              OpeningUnsupportedGroupPanel(
                                groups: unsupportedGroupOptions,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (viewData.statusMessage.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        viewData.statusMessage,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProjectAgentGroupMembersPanel extends StatelessWidget {
  const _ProjectAgentGroupMembersPanel({
    required this.title,
    required this.members,
  });

  final String title;
  final List<OpeningAgentMemberSummary> members;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.inputDock;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(surface.radius),
        border: Border.all(color: surface.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            if (members.isEmpty)
              Text(
                '当前组还没有可显示的成员。',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.mutedTextColor),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: members
                    .map((member) => _ProjectAgentMemberChip(member: member))
                    .toList(growable: false),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProjectAgentMemberChip extends StatelessWidget {
  const _ProjectAgentMemberChip({required this.member});

  final OpeningAgentMemberSummary member;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.optionTile;
    final label = member.isPrimary
        ? '${member.displayName} · 主智能体'
        : member.displayName;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(surface.radius),
        border: Border.all(
          color: member.isPrimary
              ? colors.lineStrongColor
              : surface.borderColor,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: colors.textColor,
              ),
            ),
            if (member.role.trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                member.role,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.mutedTextColor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProjectAgentGroupStatusCard extends StatelessWidget {
  const _ProjectAgentGroupStatusCard({required this.viewData});

  final ProjectAgentGroupWorkspaceViewData viewData;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.42,
        ),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前项目协作基线',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '智能体组：${viewData.currentGroupLabel}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '主智能体：${viewData.primaryAgentLabel}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (viewData.primaryAgentDescription.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                viewData.primaryAgentDescription,
                style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

ProjectAgentGroupOptionViewData? _currentGroupOf(
  ProjectAgentGroupWorkspaceViewData viewData,
) {
  for (final group in viewData.supportedGroups) {
    if (group.isCurrent) {
      return group;
    }
  }
  return null;
}
