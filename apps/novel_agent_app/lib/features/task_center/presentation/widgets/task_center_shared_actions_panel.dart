import 'package:flutter/material.dart';

import '../../../../../app/theme/app_palette.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../../../../../shared/widgets/panel_surface.dart';
import '../../../../../shared/widgets/section_heading.dart';
import '../models/task_center_action_group_view_data.dart';
import '../models/task_center_contract_action_view_data.dart';

class TaskCenterSharedActionsPanel extends StatelessWidget {
  const TaskCenterSharedActionsPanel({
    super.key,
    required this.groups,
    required this.onActionRequested,
  });

  final List<TaskCenterActionGroupViewData> groups;
  final ValueChanged<TaskCenterContractActionViewData> onActionRequested;

  @override
  Widget build(BuildContext context) {
    return PanelSurface(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeading(
            title: '上下文动作',
            subtitle: '只展示当前选中任务已经生成的共享收口动作。',
          ),
          const SizedBox(height: 10),
          if (groups.isEmpty)
            const Text(
              '当前任务还没有可用的检查点或修订收口动作。',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppPalette.mutedText,
              ),
            )
          else
            Column(
              children: groups
                  .map(
                    (group) => _ActionGroupSection(
                      group: group,
                      onActionRequested: onActionRequested,
                    ),
                  )
                  .toList(growable: false),
            ),
        ],
      ),
    );
  }
}

class _ActionGroupSection extends StatelessWidget {
  const _ActionGroupSection({
    required this.group,
    required this.onActionRequested,
  });

  final TaskCenterActionGroupViewData group;
  final ValueChanged<TaskCenterContractActionViewData> onActionRequested;

  @override
  Widget build(BuildContext context) {
    final disabledActions = group.actions
        .where((action) => !action.enabled)
        .toList(growable: false);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppPalette.text,
            ),
          ),
          if (group.summary.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              group.summary,
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppPalette.mutedText,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.actions
                .where((action) => action.enabled)
                .map(
                  (action) => ActionButton(
                    label: action.isRecommended
                        ? '${action.label}（推荐）'
                        : action.label,
                    compact: true,
                    tone: _tone(action.tone),
                    onPressed: () => onActionRequested(action),
                  ),
                )
                .toList(growable: false),
          ),
          if (disabledActions.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...disabledActions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '- ${action.label}：${action.disabledReason.trim().isEmpty ? action.note : action.disabledReason}',
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.45,
                    color: AppPalette.mutedText,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  ActionButtonTone _tone(String tone) {
    switch (tone.trim()) {
      case 'success':
        return ActionButtonTone.accent;
      case 'warm':
        return ActionButtonTone.warm;
      case 'danger':
        return ActionButtonTone.danger;
      case 'accent':
        return ActionButtonTone.accent;
      default:
        return ActionButtonTone.neutral;
    }
  }
}
