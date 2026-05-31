import 'package:flutter/material.dart';

import '../../../../shared/widgets/action_button.dart';
import '../contracts/inspiration_workbench_action_handler.dart';
import '../models/inspiration_workbench_long_task_launch_view_data.dart';

class InspirationLongTaskLaunchPanel extends StatelessWidget {
  const InspirationLongTaskLaunchPanel({
    super.key,
    required this.viewData,
    required this.actionHandler,
  });

  final InspirationWorkbenchLongTaskLaunchViewData viewData;
  final InspirationWorkbenchActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    if (!viewData.isVisible) {
      return const SizedBox.shrink();
    }
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            viewData.title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            viewData.description,
            style: textTheme.bodySmall,
          ),
          if (viewData.guidancePath.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            SelectableText(
              viewData.guidancePath,
              style: textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
          ],
          if (viewData.canLaunch) ...[
            const SizedBox(height: 10),
            ActionButton(
              label: viewData.actionLabel,
              icon: Icons.play_arrow_rounded,
              tone: ActionButtonTone.warm,
              compact: true,
              onPressed:
                  actionHandler.onInspirationWorkbenchLongTaskLaunchRequested,
            ),
          ],
        ],
      ),
    );
  }
}
