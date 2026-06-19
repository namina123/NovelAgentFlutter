import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
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
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.panel;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: 0.58),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: surface.borderColor.withValues(alpha: 0.68),
          width: AppChrome.borderWidth,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow.trim().isNotEmpty) ...[
            Text(
              eyebrow,
              style: TextStyle(
                color: colors.mutedTextColor,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            state.firstPrompt,
            style: TextStyle(
              color: surface.foregroundColor,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
          if (state.nextStepLabel.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              '下一步：${state.nextStepLabel}',
              style: TextStyle(
                color: colors.textColor,
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (state.hasMissingRequirements) ...[
            const SizedBox(height: 8),
            Text(
              '还需补齐：${state.missingRequirementTitles.join('、')}',
              style: TextStyle(
                color: colors.mutedTextColor,
                fontSize: 11.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
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
      ),
    );
  }
}
