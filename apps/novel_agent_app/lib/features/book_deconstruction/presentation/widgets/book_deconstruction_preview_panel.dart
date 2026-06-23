import 'package:flutter/material.dart';

import '../../application/models/book_deconstruction_operation_kind.dart' show BookDeconstructionOperationKind;
import '../../presentation/contracts/book_deconstruction_action_handler.dart';
import '../models/book_deconstruction_plan_group_view_data.dart';
import '../models/book_deconstruction_plan_item_view_data.dart';
import '../models/book_deconstruction_preview_section_view_data.dart';
import '../models/book_deconstruction_view_data.dart';

/// 步骤②的拆书结果展示：纯净分章正文 + 拟应用的章纲条目（可勾选）。
/// 不含续写路线（在步骤④）与确认按钮（在步骤④）。
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
    if (viewData.isLoading &&
        viewData.operationKind ==
            BookDeconstructionOperationKind.splittingChapters &&
        viewData.previewSections.isEmpty &&
        viewData.planGroups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text('正在拆书（分章 + 去噪）…', style: textTheme.bodyMedium),
          ],
        ),
      );
    }
    if (viewData.previewSections.isEmpty && viewData.planGroups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          '导入源文稿后点"拆书"，这里展示纯净的分章结果与拟应用的章纲条目。',
          style: textTheme.bodySmall,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('拆书结果（分章）', style: textTheme.titleSmall)),
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
        ...viewData.previewSections.map((section) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _PreviewSection(section: section),
          );
        }),
        ...viewData.planGroups.map(
          (group) => _PlanGroupSection(group: group, actionHandler: actionHandler),
        ),
        const SizedBox(height: 8),
        Text(
          '已选 ${viewData.selectedItemCount}/${viewData.totalItemCount} 项',
          style: textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _PreviewSection extends StatelessWidget {
  const _PreviewSection({required this.section});

  final BookDeconstructionPreviewSectionViewData section;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
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
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: textTheme.bodyLarge),
                  if (item.caption.trim().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(item.caption, style: textTheme.bodySmall),
                  ],
                  if (item.summary.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(item.summary, style: textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
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
      padding: const EdgeInsets.only(bottom: 14),
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
