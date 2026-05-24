import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../models/agent_ecosystem_view_data.dart';

class EcosystemDetailPanel extends StatelessWidget {
  const EcosystemDetailPanel({
    super.key,
    required this.entry,
    this.onOpenSourceRequested,
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
  final VoidCallback onCreateAgentRequested;
  final VoidCallback onCreateSkillRequested;
  final VoidCallback onCreateSkillGroupRequested;
  final VoidCallback onCreateAgentGroupRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 生态详情和新建入口独立成 pane，避免把列表浏览和自定义入口全部塞进同一块。
    return PanelSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(title: entry.title, subtitle: entry.description),
          const SizedBox(height: 18),
          _buildInfoCard('条目标识', entry.subtitle),
          const SizedBox(height: 12),
          _buildInfoCard('条目类型', _kindLabel(entry.kind)),
          const SizedBox(height: 12),
          _buildInfoCard('来源', entry.badge),
          if (entry.projectRelativePath.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoCard('项目路径', entry.projectRelativePath),
          ],
          if (entry.sourcePath.trim().isNotEmpty &&
              entry.sourcePath.trim() != entry.projectRelativePath.trim()) ...[
            const SizedBox(height: 12),
            _buildInfoCard('源文件', entry.sourcePath),
          ],
          if (entry.isEditable && onOpenSourceRequested != null) ...[
            const SizedBox(height: 14),
            ActionButton(
              label: '打开源文件',
              icon: Icons.edit_note_outlined,
              tone: ActionButtonTone.neutral,
              expanded: true,
              onPressed: onOpenSourceRequested!,
            ),
          ],
          const SizedBox(height: 22),
          const Text(
            '自定义与导入',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppPalette.text,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ActionButton(
                label: '+ 智能体',
                icon: Icons.smart_toy_outlined,
                onPressed: onCreateAgentRequested,
              ),
              ActionButton(
                label: '+ 技能',
                icon: Icons.auto_fix_high_outlined,
                tone: ActionButtonTone.warm,
                onPressed: onCreateSkillRequested,
              ),
              ActionButton(
                label: '+ 技能组',
                icon: Icons.hub_outlined,
                onPressed: onCreateSkillGroupRequested,
              ),
              ActionButton(
                label: '+ 智能体组',
                icon: Icons.group_work_outlined,
                onPressed: onCreateAgentGroupRequested,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    // 中文注释: 详情字段统一封装，后续切换为真实编辑表单时只改这一层。
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.line, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppPalette.mutedText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppPalette.text,
              ),
            ),
          ],
        ),
      ),
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
