import 'package:flutter/material.dart';

import '../../presentation/contracts/book_deconstruction_action_handler.dart';
import '../models/book_deconstruction_continuity_view_data.dart';
import '../models/book_deconstruction_information_bridge_view_data.dart';
import '../models/book_deconstruction_followup_group_view_data.dart';
import '../models/book_deconstruction_followup_option_view_data.dart';
import '../models/book_deconstruction_plan_group_view_data.dart';
import '../models/book_deconstruction_plan_item_view_data.dart';
import '../models/book_deconstruction_view_data.dart';

class BookDeconstructionPreviewPanel extends StatelessWidget {
  const BookDeconstructionPreviewPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final BookDeconstructionViewData viewData;
  final BookDeconstructionActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    if (viewData.previewSections.isEmpty && viewData.planGroups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            '导入源文稿后，先生成结构化预览。这里会展示前提、章节骨架和拟应用条目。',
            style: textTheme.bodyMedium,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(child: Text('结构化预览与拟应用条目', style: textTheme.titleSmall)),
              TextButton(
                onPressed: actionHandler.onBookDeconstructionSelectAllRequested,
                child: const Text('全选'),
              ),
              TextButton(
                onPressed:
                    actionHandler.onBookDeconstructionClearSelectionRequested,
                child: const Text('清空'),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (viewData.continuity != null) ...[
                _ContinuitySummarySection(
                  continuity: viewData.continuity!,
                  actionHandler: actionHandler,
                ),
                const SizedBox(height: 16),
              ],
              if (viewData.informationBridge != null) ...[
                _InformationBridgeSection(bridge: viewData.informationBridge!),
                const SizedBox(height: 16),
              ],
              ...viewData.previewSections.map((section) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.title, style: textTheme.titleSmall),
                      const SizedBox(height: 4),
                      Text(section.description, style: textTheme.bodySmall),
                      const SizedBox(height: 8),
                      ...section.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.title, style: textTheme.bodyLarge),
                                if (item.caption.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    item.caption,
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                                if (item.summary.trim().isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    item.summary,
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
              ...viewData.planGroups.map(
                (group) => _PlanGroupSection(
                  group: group,
                  actionHandler: actionHandler,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '已选 ${viewData.selectedItemCount}/${viewData.totalItemCount} 项',
                style: textTheme.bodyMedium,
              ),
              if (viewData.confirmedPreviewPath.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  '预演纪要：${viewData.confirmedPreviewPath}',
                  style: textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: viewData.canConfirmSelection
                    ? actionHandler.onBookDeconstructionConfirmRequested
                    : null,
                icon: const Icon(Icons.assignment_turned_in_outlined),
                label: const Text('确认当前应用前选择'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: viewData.canCreateDerivedProject
                    ? actionHandler.onBookDeconstructionCreateDerivedProjectRequested
                    : null,
                icon: const Icon(Icons.fork_right_outlined),
                label: const Text('派生并打开项目'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InformationBridgeSection extends StatelessWidget {
  const _InformationBridgeSection({required this.bridge});

  final BookDeconstructionInformationBridgeViewData bridge;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('后续用途与共享资料', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(bridge.summary, style: textTheme.bodySmall),
        const SizedBox(height: 10),
        ...bridge.followupRoutes.map(
          (route) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(route.title, style: textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(route.summary, style: textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(route.statusLabel, style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text('本次已生成的可复用资料', style: textTheme.titleSmall),
        const SizedBox(height: 6),
        ...bridge.assetStatuses.map(
          (item) => Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.title} · ${item.count}',
                  style: textTheme.bodyLarge,
                ),
                const SizedBox(height: 4),
                Text(item.statusLabel, style: textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(item.summary, style: textTheme.bodySmall),
              ],
            ),
          ),
        ),
        Text(bridge.reuseSummary, style: textTheme.bodySmall),
      ],
    );
  }
}

class _ContinuitySummarySection extends StatelessWidget {
  const _ContinuitySummarySection({
    required this.continuity,
    required this.actionHandler,
  });

  final BookDeconstructionContinuityViewData continuity;
  final BookDeconstructionActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('续写基座与后续方案', style: textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(continuity.summary, style: textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('默认导向：${continuity.preferredDirectionLabel}'),
              const SizedBox(height: 4),
              Text('推荐基座：${continuity.highlightedBuildTierLabel}'),
              const SizedBox(height: 4),
              Text('默认高亮：${continuity.highlightedRouteTitle}'),
              const SizedBox(height: 4),
              Text('当前选择：${continuity.selectedRouteTitle}'),
              const SizedBox(height: 8),
              Text(
                '作用域提示 ${continuity.scopeHintCount} · 身份映射 ${continuity.identityMappingCount} · 机制提示 ${continuity.mechanicHintCount}',
                style: textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        ...continuity.followupGroups.map(_buildGroup),
      ],
    );
  }

  Widget _buildGroup(BookDeconstructionFollowupGroupViewData group) {
    return Builder(
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(group.title, style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(group.description, style: textTheme.bodySmall),
              const SizedBox(height: 8),
              if (group.options.isEmpty)
                Text('当前暂无可用路线。', style: textTheme.bodySmall)
              else
                ...group.options.map(
                  (option) => _buildOption(option, group.title),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption(
    BookDeconstructionFollowupOptionViewData option,
    String groupTitle,
  ) {
    return Builder(
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: ValueKey('book_deconstruction_followup_option_${option.id}'),
              onTap: () {
                actionHandler.onBookDeconstructionFollowupOptionSelected(
                  option.id,
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: option.isSelected || option.isHighlighted
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 12),
                      child: Icon(
                        option.isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 20,
                        color: option.isSelected || option.isHighlighted
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).disabledColor,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            option.isSelected
                                ? '${option.title} · 已选择'
                                : option.isHighlighted
                                ? '${option.title} · 当前默认'
                                : option.title,
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(option.summary, style: textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(
                            '推荐基座：${option.buildTierLabel}',
                            style: textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text('分组：$groupTitle', style: textTheme.bodySmall),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlanGroupSection extends StatelessWidget {
  const _PlanGroupSection({required this.group, required this.actionHandler});

  final BookDeconstructionPlanGroupViewData group;
  final BookDeconstructionActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(group.title, style: textTheme.titleSmall),
          const SizedBox(height: 4),
          Text(group.description, style: textTheme.bodySmall),
          const SizedBox(height: 8),
          ...group.items.map(
            (item) => _PlanItemTile(item: item, actionHandler: actionHandler),
          ),
        ],
      ),
    );
  }
}

class _PlanItemTile extends StatelessWidget {
  const _PlanItemTile({required this.item, required this.actionHandler});

  final BookDeconstructionPlanItemViewData item;
  final BookDeconstructionActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      value: item.isSelected,
      onChanged: (selected) {
        actionHandler.onBookDeconstructionPlanItemSelectionChanged(
          itemId: item.id,
          selected: selected ?? false,
        );
      },
      title: Text(item.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.summary.trim().isNotEmpty) Text(item.summary),
          Text('${item.relativePathHint} · ${item.actionLabel}'),
        ],
      ),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
