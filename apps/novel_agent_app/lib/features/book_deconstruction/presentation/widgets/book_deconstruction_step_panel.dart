import 'package:flutter/material.dart';

import '../../presentation/contracts/book_deconstruction_action_handler.dart';
import '../models/book_deconstruction_view_data.dart';

class BookDeconstructionStepPanel extends StatelessWidget {
  const BookDeconstructionStepPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final BookDeconstructionViewData viewData;
  final BookDeconstructionActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text('向导步骤', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        ...viewData.steps.map((step) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () =>
                  actionHandler.onBookDeconstructionStepSelected(step.id),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: step.isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).dividerColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(step.title, style: textTheme.titleSmall),
                        ),
                        if (step.isComplete)
                          Icon(
                            Icons.check_circle_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(step.description, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        Text('当前状态', style: textTheme.titleSmall),
        const SizedBox(height: 8),
        Text(
          '已选应用 ${viewData.selectedItemCount}/${viewData.totalItemCount}',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 6),
        Text(
          '源文稿 ${viewData.sourceContent.trim().length} 字',
          style: textTheme.bodySmall,
        ),
        if (viewData.confirmedPreviewPath.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '预演纪要：${viewData.confirmedPreviewPath}',
            style: textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
