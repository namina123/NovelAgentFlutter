import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../contracts/agent_ecosystem_action_handler.dart';
import '../models/project_skill_loadout_view_data.dart';

class ProjectSkillLoadoutDetailPanel extends StatelessWidget {
  const ProjectSkillLoadoutDetailPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
    required this.projectAvailable,
  });

  final ProjectSkillLoadoutDetailViewData? viewData;
  final AgentEcosystemActionHandler actionHandler;
  final bool projectAvailable;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    // 中文注释: 项目技能装载详情区独立成专用面板，避免把复选、历史恢复和显式保存逻辑硬塞进通用详情卡。
    final detail = viewData;
    if (detail == null) {
      return PanelSurface(
        child: SectionHeading(
          title: '项目技能装载',
          subtitle: projectAvailable ? '请选择一个智能体。' : '请先创建或打开项目。',
        ),
      );
    }
    return PanelSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeading(
            title: detail.agentName,
            subtitle: detail.agentDescription,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _metaChip(context, '来源', detail.sourceLabel),
              _metaChip(context, '摘要', detail.summary),
              _metaChip(
                context,
                '状态',
                detail.hasPendingChanges ? '有未应用改动' : '已与保存状态一致',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _availabilityGate(
                ActionButton(
                  label: '应用装载',
                  icon: Icons.save_outlined,
                  onPressed: () => actionHandler
                      .onProjectSkillLoadoutApplyRequested(detail.agentId),
                ),
              ),
              _availabilityGate(
                ActionButton(
                  label: '回到已保存',
                  icon: Icons.undo_rounded,
                  tone: ActionButtonTone.neutral,
                  onPressed: () => actionHandler
                      .onProjectSkillLoadoutResetRequested(detail.agentId),
                ),
              ),
              _availabilityGate(
                ActionButton(
                  label: '表达限制',
                  icon: Icons.rule_folder_outlined,
                  tone: ActionButtonTone.neutral,
                  onPressed:
                      actionHandler.onProjectExpressionConstraintsRequested,
                ),
              ),
              _availabilityGate(
                ActionButton(
                  label: '另存为技能组',
                  icon: Icons.bookmark_add_outlined,
                  tone: ActionButtonTone.warm,
                  onPressed: () =>
                      _showSaveAsGroupDialog(context, detail.agentId),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: context.novelThemeSurfaces.inputDock.backgroundColor
                  .withValues(alpha: 0.48),
              borderRadius: BorderRadius.circular(
                context.novelThemeSurfaces.inputDock.radius,
              ),
              border: Border.all(
                color: context.novelThemeSurfaces.inputDock.borderColor,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: colors.mutedTextColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      detail.expressionConstraintSummary,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: colors.mutedTextColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (detail.permissionBoundarySummary.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.novelThemeSurfaces.inputDock.backgroundColor
                    .withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(
                  context.novelThemeSurfaces.inputDock.radius,
                ),
                border: Border.all(
                  color: context.novelThemeSurfaces.inputDock.borderColor,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 18,
                      color: colors.mutedTextColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail.permissionBoundarySummary,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: colors.mutedTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (detail.issues.isNotEmpty) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: context.novelThemeSurfaces.inputDock.backgroundColor
                    .withValues(alpha: 0.48),
                borderRadius: BorderRadius.circular(
                  context.novelThemeSurfaces.inputDock.radius,
                ),
                border: Border.all(
                  color: colors.warmStrongColor.withValues(alpha: 0.45),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '装载提示',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: colors.textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final issue in detail.issues) ...[
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
                      if (issue != detail.issues.last)
                        const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _sectionCard(
                    context,
                    title: '技能组',
                    child: _selectionList(
                      context,
                      items: detail.skillGroups,
                      onChanged: projectAvailable
                          ? (item, selected) => actionHandler
                                .onProjectSkillLoadoutSkillGroupToggled(
                                  detail.agentId,
                                  item.id,
                                  selected,
                                )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    context,
                    title: '额外技能',
                    child: _selectionList(
                      context,
                      items: detail.extraSkills,
                      onChanged: projectAvailable
                          ? (item, selected) => actionHandler
                                .onProjectSkillLoadoutExtraSkillToggled(
                                  detail.agentId,
                                  item.id,
                                  selected,
                                )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    context,
                    title: '最终技能',
                    child: Column(
                      children: detail.resolvedSkills
                          .map(
                            (skill) => CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              value: skill.enabled,
                              title: Text(
                                skill.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: skill.isUnavailable
                                      ? colors.warmStrongColor
                                      : colors.textColor,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    skill.sourceSummary,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.mutedTextColor,
                                    ),
                                  ),
                                  if (skill.statusLabel.trim().isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        skill.statusLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: skill.isUnavailable
                                              ? colors.warmStrongColor
                                              : colors.mutedTextColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              secondary: Icon(
                                skill.isUnavailable
                                    ? Icons.error_outline_rounded
                                    : (skill.enabled
                                          ? Icons.check_circle_outline_rounded
                                          : Icons.pause_circle_outline_rounded),
                                color: skill.isUnavailable
                                    ? colors.warmStrongColor
                                    : (skill.enabled
                                          ? colors.lineStrongColor
                                          : colors.mutedTextColor),
                              ),
                              onChanged: projectAvailable
                                  ? (value) => actionHandler
                                        .onProjectSkillLoadoutDisabledSkillToggled(
                                          detail.agentId,
                                          skill.id,
                                          !(value ?? false),
                                        )
                                  : null,
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    context,
                    title: '历史快照',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '这里保存的是当前草稿的阶段快照；“回到已保存”只回到当前项目已保存装载，“另存为技能组”则会生成可复用的资产。',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.mutedTextColor,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _availabilityGate(
                          ActionButton(
                            label: '保存当前快照',
                            icon: Icons.history_toggle_off_rounded,
                            tone: ActionButtonTone.neutral,
                            onPressed: () => _showHistoryCaptureDialog(
                              context,
                              detail.agentId,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        if (detail.historyEntries.isEmpty)
                          Text(
                            '当前还没有这个智能体的技能装载历史快照。',
                            style: TextStyle(
                              fontSize: 13,
                              color: colors.mutedTextColor,
                            ),
                          )
                        else
                          Column(
                            children: detail.historyEntries
                                .map(
                                  (entry) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(
                                      entry.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: colors.textColor,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${entry.subtitle}\n${entry.summary}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.mutedTextColor,
                                      ),
                                    ),
                                    trailing: ActionButton(
                                      label: '恢复这次快照',
                                      icon: Icons.history_rounded,
                                      tone: ActionButtonTone.neutral,
                                      onPressed: () => actionHandler
                                          .onProjectSkillLoadoutHistoryRestoreRequested(
                                            detail.agentId,
                                            entry.id,
                                          ),
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _selectionList(
    BuildContext context, {
    required List<ProjectSkillLoadoutSelectableItemViewData> items,
    required void Function(
      ProjectSkillLoadoutSelectableItemViewData item,
      bool selected,
    )?
    onChanged,
  }) {
    final colors = context.novelThemeColors;
    return Column(
      children: items
          .map(
            (item) => CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: item.selected,
              title: Text(
                item.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.textColor,
                ),
              ),
              subtitle: Text(
                item.subtitle,
                style: TextStyle(fontSize: 12, color: colors.mutedTextColor),
              ),
              onChanged: onChanged == null
                  ? null
                  : (value) => onChanged(item, value ?? false),
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final surface = context.novelThemeSurfaces.optionTile;
    final colors = context.novelThemeColors;
    return Material(
      color: surface.backgroundColor.withValues(alpha: 0.52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(surface.radius),
        side: BorderSide(color: surface.borderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: colors.textColor,
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _metaChip(BuildContext context, String label, String value) {
    final surface = context.novelThemeSurfaces.inputDock;
    final colors = context.novelThemeColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: surface.borderColor, width: 1),
      ),
      child: Text(
        '$label：$value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.textColor,
        ),
      ),
    );
  }

  Widget _availabilityGate(Widget child) {
    if (projectAvailable) {
      return child;
    }
    return IgnorePointer(
      ignoring: true,
      child: Opacity(opacity: 0.45, child: child),
    );
  }

  Future<void> _showHistoryCaptureDialog(
    BuildContext context,
    String agentId,
  ) async {
    final controller = TextEditingController(text: '$agentId 装载快照');
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('保存历史快照'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: '快照标题'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
    if ((title ?? '').trim().isEmpty) {
      return;
    }
    actionHandler.onProjectSkillLoadoutHistoryCaptureRequested(
      agentId,
      title!.trim(),
    );
  }

  Future<void> _showSaveAsGroupDialog(
    BuildContext context,
    String agentId,
  ) async {
    final idController = TextEditingController(text: '${agentId}_loadout');
    final nameController = TextEditingController(text: '$agentId 项目技能组');
    final descriptionController = TextEditingController();
    final request =
        await showDialog<({String id, String name, String description})>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('另存为技能组'),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: idController,
                      decoration: const InputDecoration(labelText: '技能组 ID'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: '显示名称'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        alignLabelWithHint: true,
                        labelText: '说明',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('取消'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop((
                      id: idController.text.trim(),
                      name: nameController.text.trim(),
                      description: descriptionController.text.trim(),
                    ));
                  },
                  child: const Text('保存'),
                ),
              ],
            );
          },
        );
    if (request == null || request.id.trim().isEmpty) {
      return;
    }
    actionHandler.onProjectSkillLoadoutSaveAsGroupRequested(
      agentId,
      request.id.trim(),
      request.name.trim(),
      request.description.trim(),
    );
  }
}
