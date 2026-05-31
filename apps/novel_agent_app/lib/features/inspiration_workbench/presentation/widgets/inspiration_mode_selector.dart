import 'package:flutter/material.dart';

import '../contracts/inspiration_workbench_action_handler.dart';
import '../models/inspiration_workbench_view_data.dart';

class InspirationModeSelector extends StatelessWidget {
  const InspirationModeSelector({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final InspirationWorkbenchViewData viewData;
  final InspirationWorkbenchActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 模式选择和模式说明集中在这里，避免编辑面板再承担模式导航职责。
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '灵感模式',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: viewData.modeOptions.map((mode) {
            return ChoiceChip(
              label: Text(mode.title),
              selected: mode.isSelected,
              onSelected: (_) =>
                  actionHandler.onInspirationWorkbenchModeSelected(mode.id),
            );
          }).toList(),
        ),
        if (viewData.selectedModeDescription.trim().isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            viewData.selectedModeDescription,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
