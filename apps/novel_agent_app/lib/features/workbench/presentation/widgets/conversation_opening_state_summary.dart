import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/conversation_opening_state_view_data.dart';

class ConversationOpeningStateSummary extends StatelessWidget {
  const ConversationOpeningStateSummary({
    super.key,
    required this.state,
    required this.actionHandler,
    this.eyebrow = '',
    this.showActionButton = true,
  });

  final ConversationOpeningStateViewData state;
  final ConversationActionHandler actionHandler;
  final String eyebrow;
  final bool showActionButton;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow.trim().isNotEmpty) ...[
          Text(
            eyebrow,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          state.firstPrompt,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.35,
          ),
        ),
        if (state.nextStepLabel.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '下一步：${state.nextStepLabel}',
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
        if (state.hasMissingRequirements) ...[
          const SizedBox(height: 8),
          Text(
            '当前还缺：${state.missingRequirementTitles.join('、')}',
            style: theme.textTheme.bodySmall?.copyWith(height: 1.45),
          ),
        ],
        if (showActionButton && state.nextAction != null) ...[
          const SizedBox(height: 10),
          ActionButton(
            label: state.nextAction!.title,
            expanded: true,
            compact: true,
            onPressed: () =>
                actionHandler.onPrimaryActionRequested(state.nextAction!.id),
          ),
        ],
      ],
    );
  }
}
