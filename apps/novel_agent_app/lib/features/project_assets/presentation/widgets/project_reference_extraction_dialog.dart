import 'package:flutter/material.dart';

import '../../application/controllers/project_assets_controller.dart';
import '../models/project_reference_extraction_strategy_picker_view_data.dart';

Future<void> showProjectReferenceExtractionDialog(
  BuildContext context,
  ProjectAssetsController controller,
  ProjectReferenceExtractionStrategyPickerViewData picker,
) async {
  var selectedProfileId = picker.selectedProfileId;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('知识提取'),
            content: SizedBox(
              width: 560,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    picker.summary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (picker.sourceHint.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      picker.sourceHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: RadioGroup<String>(
                        groupValue: selectedProfileId,
                        onChanged: (value) {
                          if (value == null) {
                            return;
                          }
                          setState(() => selectedProfileId = value);
                        },
                        child: Column(
                          children: picker.options
                              .map(
                                (option) => RadioListTile<String>(
                                  value: option.profileId,
                                  contentPadding: EdgeInsets.zero,
                                  title: Row(
                                    children: [
                                      Expanded(child: Text(option.displayName)),
                                      if (option.badgeLabel.isNotEmpty)
                                        _StrategyBadge(
                                          label: option.badgeLabel,
                                        ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(option.summary),
                                        const SizedBox(height: 4),
                                        Text('候选：${option.proposalCountLabel}'),
                                        Text('类型：${option.entryKindsLabel}'),
                                        Text('审核：${option.reviewPolicyLabel}'),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ),
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
                onPressed: selectedProfileId.trim().isEmpty
                    ? null
                    : () {
                        controller.onProjectAssetsExtractReferenceRequested(
                          strategyProfileId: selectedProfileId,
                        );
                        Navigator.of(dialogContext).pop();
                      },
                child: Text(picker.confirmButtonLabel),
              ),
            ],
          );
        },
      );
    },
  );
}

class _StrategyBadge extends StatelessWidget {
  const _StrategyBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
