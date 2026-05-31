import 'package:flutter/material.dart';

import '../../../../../shared/widgets/panel_surface.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/conversation_opening_state_view_data.dart';
import 'conversation_opening_state_summary.dart';
import 'conversation_supplement_section.dart';

class WorkflowGuideCard extends StatelessWidget {
  const WorkflowGuideCard({
    super.key,
    required this.title,
    required this.description,
    this.openingState,
    this.actionHandler,
    this.supplement,
  });

  final String title;
  final String description;
  final ConversationOpeningStateViewData? openingState;
  final ConversationActionHandler? actionHandler;
  final Widget? supplement;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 工作流引导卡独立后，未来切换不同项目体验 profile 时只需替换这个信息组件。
    return PanelSurface(
      role: PanelSurfaceRole.panel,
      showBorder: false,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (openingState != null && actionHandler != null)
            ConversationOpeningStateSummary(
              state: openingState!,
              actionHandler: actionHandler!,
              eyebrow: title,
              showActionButton: false,
            )
          else ...[
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
          if (supplement != null) ...[
            const SizedBox(height: 10),
            ConversationSupplementSection(child: supplement!),
          ],
        ],
      ),
    );
  }
}
