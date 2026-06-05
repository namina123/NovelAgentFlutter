import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../models/agent_ecosystem_view_data.dart';

class EcosystemDetailPanel extends StatelessWidget {
  const EcosystemDetailPanel({
    super.key,
    required this.entry,
    this.onOpenSourceRequested,
    this.onEditRequested,
    required this.onCreateAgentRequested,
    required this.onCreateSkillRequested,
    required this.onCreateSkillGroupRequested,
    required this.onCreateAgentGroupRequested,
  });

  factory EcosystemDetailPanel.empty({
    Key? key,
    required VoidCallback onCreateAgentRequested,
    required VoidCallback onCreateSkillRequested,
    required VoidCallback onCreateSkillGroupRequested,
    required VoidCallback onCreateAgentGroupRequested,
  }) {
    return EcosystemDetailPanel(
      key: key,
      entry: const EcosystemEntryViewData(
        id: '',
        kind: 'agents',
        title: '尚未载入条目',
        subtitle: '等待扫描内置与项目内生态包',
        badge: '空',
        description: '这里会展示当前智能体、技能或分组的详细信息。',
        sourcePath: '',
        projectRelativePath: '',
        isEditable: false,
      ),
      onCreateAgentRequested: onCreateAgentRequested,
      onCreateSkillRequested: onCreateSkillRequested,
      onCreateSkillGroupRequested: onCreateSkillGroupRequested,
      onCreateAgentGroupRequested: onCreateAgentGroupRequested,
    );
  }

  final EcosystemEntryViewData entry;
  final VoidCallback? onOpenSourceRequested;
  final VoidCallback? onEditRequested;
  final VoidCallback onCreateAgentRequested;
  final VoidCallback onCreateSkillRequested;
  final VoidCallback onCreateSkillGroupRequested;
  final VoidCallback onCreateAgentGroupRequested;

  @override
  Widget build(BuildContext context) {
    final metadata = _buildMetadataItems();
    final summary = entry.description.trim();
    final identifier = entry.subtitle.trim();
    final actionButtons = _buildEntryActionButtons();
    final createButtons = _buildCreateActionButtons();
    final colors = context.novelThemeColors;

    // 中文注释: 生态详情和新建入口独立成 pane，避免把列表浏览和自定义入口全部塞进同一块。
    return PanelSurface(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeading(
              title: entry.title,
              subtitle: identifier.isEmpty ? null : identifier,
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                summary,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: colors.mutedTextColor,
                ),
              ),
            ],
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildMetadataPanel(context, metadata),
            ],
            if (entry.memberLabels.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildMemberPanel(context),
            ],
            if (entry.permissionBoundarySummary.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildCalloutPanel(
                context,
                title: '权限边界',
                icon: Icons.shield_outlined,
                body: entry.permissionBoundarySummary,
              ),
            ],
            if (entry.validationIssues.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildIssuePanel(context),
            ],
            if (actionButtons.isNotEmpty) ...[
              const SizedBox(height: 14),
              _buildActionSection(
                context,
                title: '当前操作',
                actions: actionButtons,
              ),
            ],
            const SizedBox(height: 14),
            _buildActionSection(context, title: '新建条目', actions: createButtons),
          ],
        ),
      ),
    );
  }

  List<EcosystemMetadataRow> _buildMetadataItems() {
    if (entry.metadataRows.isNotEmpty) {
      return entry.metadataRows;
    }
    final items = <EcosystemMetadataRow>[
      EcosystemMetadataRow(label: '类型', value: _kindLabel(entry.kind)),
      EcosystemMetadataRow(label: '来源', value: entry.badge),
    ];
    final projectRelativePath = entry.projectRelativePath.trim();
    final sourcePath = entry.sourcePath.trim();
    if (projectRelativePath.isNotEmpty) {
      items.add(
        EcosystemMetadataRow(label: '项目内路径', value: projectRelativePath),
      );
    }
    if (sourcePath.isNotEmpty && sourcePath != projectRelativePath) {
      items.add(EcosystemMetadataRow(label: '源文件', value: sourcePath));
    }
    return items;
  }

  List<Widget> _buildEntryActionButtons() {
    final actions = <Widget>[];
    if (entry.isEditable && onEditRequested != null) {
      actions.add(
        ActionButton(
          label: entry.canDuplicateBuiltin ? '复制为项目草案' : '编辑条目',
          icon: Icons.edit_outlined,
          compact: true,
          onPressed: onEditRequested!,
        ),
      );
    }
    if (entry.projectRelativePath.trim().isNotEmpty &&
        onOpenSourceRequested != null) {
      actions.add(
        ActionButton(
          label: '打开源文件',
          icon: Icons.description_outlined,
          tone: ActionButtonTone.neutral,
          compact: true,
          onPressed: onOpenSourceRequested!,
        ),
      );
    }
    return actions;
  }

  List<Widget> _buildCreateActionButtons() {
    return [
      ActionButton(
        label: '新建智能体',
        icon: Icons.smart_toy_outlined,
        compact: true,
        onPressed: onCreateAgentRequested,
      ),
      ActionButton(
        label: '新建技能',
        icon: Icons.auto_fix_high_outlined,
        tone: ActionButtonTone.warm,
        compact: true,
        onPressed: onCreateSkillRequested,
      ),
      ActionButton(
        label: '新建技能组',
        icon: Icons.hub_outlined,
        compact: true,
        onPressed: onCreateSkillGroupRequested,
      ),
      ActionButton(
        label: '新建智能体组',
        icon: Icons.group_work_outlined,
        compact: true,
        onPressed: onCreateAgentGroupRequested,
      ),
    ];
  }

  Widget _buildMetadataPanel(
    BuildContext context,
    List<EcosystemMetadataRow> items,
  ) {
    // 中文注释: 详情元信息收束到一个紧凑区块，避免每个字段都长成单独卡片。
    final surface = context.novelThemeSurfaces.optionTile;
    final colors = context.novelThemeColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(surface.radius),
        border: Border.all(color: surface.borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < items.length; index++) ...[
              _buildMetadataRow(
                context,
                items[index].label,
                items[index].value,
              ),
              if (index != items.length - 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    color: colors.lineColor.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(BuildContext context, String label, String value) {
    final colors = context.novelThemeColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.mutedTextColor,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textColor,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberPanel(BuildContext context) {
    final surface = context.novelThemeSurfaces.inputDock;
    final colors = context.novelThemeColors;
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
              '组内成员',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: entry.memberLabels
                  .map(
                    (member) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: surface.backgroundColor.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(surface.radius),
                        border: Border.all(color: surface.borderColor),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Text(
                          member,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.textColor,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalloutPanel(
    BuildContext context, {
    required String title,
    required IconData icon,
    required String body,
  }) {
    final surface = context.novelThemeSurfaces.inputDock;
    final colors = context.novelThemeColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(surface.radius),
        border: Border.all(color: surface.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: colors.mutedTextColor),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: colors.textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: colors.mutedTextColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuePanel(BuildContext context) {
    final surface = context.novelThemeSurfaces.inputDock;
    final colors = context.novelThemeColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(surface.radius),
        border: Border.all(
          color: colors.warmStrongColor.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '配置提示',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 8),
            for (final issue in entry.validationIssues) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 16,
                    color: colors.warmStrongColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      issue,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: colors.mutedTextColor,
                      ),
                    ),
                  ),
                ],
              ),
              if (issue != entry.validationIssues.last)
                const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionSection(
    BuildContext context, {
    required String title,
    required List<Widget> actions,
  }) {
    final colors = context.novelThemeColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: colors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: actions),
      ],
    );
  }

  String _kindLabel(String kind) {
    // 中文注释: 条目类型标签统一映射为中文，避免展示层直接暴露内部 tab id。
    switch (kind) {
      case 'skills':
        return '技能';
      case 'skill-groups':
        return '技能组';
      case 'agent-groups':
        return '智能体组';
      case 'agents':
      default:
        return '智能体';
    }
  }
}
