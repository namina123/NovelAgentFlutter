import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../../../../shared/widgets/action_button.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/conversation_input_capability_state.dart';
import 'conversation_reasoning_toggle_chip.dart';

class ConversationInputActionRow extends StatelessWidget {
  const ConversationInputActionRow({
    super.key,
    required this.capabilities,
    required this.actionHandler,
    required this.onSendRequested,
  });

  final ConversationInputCapabilityState capabilities;
  final ConversationActionHandler actionHandler;
  final VoidCallback onSendRequested;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final surface = context.novelThemeSurfaces.inputDock;
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionButtons = <Widget>[];
        void appendAction(Widget child) {
          actionButtons.add(child);
        }

        if (capabilities.showOptimizeAction) {
          appendAction(
            ActionButton(
              label: '优化',
              icon: Icons.auto_fix_high_outlined,
              tone: ActionButtonTone.warm,
              compact: true,
              onPressed: actionHandler.onOptimizeRequested,
            ),
          );
        }
        if (capabilities.showToolOptionsAction) {
          appendAction(
            ActionButton(
              label: '工具',
              icon: Icons.tune_outlined,
              tone: ActionButtonTone.neutral,
              compact: true,
              onPressed: actionHandler.onToolOptionsRequested,
            ),
          );
        }
        if (capabilities.showAttachmentEntry) {
          appendAction(
            ActionButton(
              label: '附件',
              icon: Icons.attach_file_rounded,
              tone: ActionButtonTone.neutral,
              compact: true,
              onPressed: actionHandler.onAttachmentRequested,
            ),
          );
        }
        final reasoningToggle = capabilities.showReasoningToggle
            ? ConversationReasoningToggleChip(
                enabled: capabilities.reasoningEnabled,
                onChanged: actionHandler.onReasoningToggleChanged,
              )
            : null;
        final sendButton = SizedBox(width: 104, child: _buildSendButton());
        final trailingChildren = <Widget>[];
        if (reasoningToggle != null) {
          trailingChildren.add(reasoningToggle);
          trailingChildren.add(const SizedBox(width: 8));
        }
        trailingChildren.add(sendButton);
        final showStatusLabel = capabilities.showStopAction;
        final statusLabel = Text(
          '生成中',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10.4,
            fontWeight: FontWeight.w600,
            color: colors.mutedTextColor,
          ),
        );
        final statusPill = DecoratedBox(
          decoration: BoxDecoration(
            color: surface.backgroundColor.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: surface.borderColor.withValues(alpha: 0.18),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: statusLabel,
          ),
        );
        final trailingGroup = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: trailingChildren,
        );
        if (actionButtons.isEmpty) {
          return Row(
            children: [
              if (showStatusLabel) statusPill else const Spacer(),
              if (!showStatusLabel) const Spacer(),
              if (showStatusLabel) const SizedBox(width: 8),
              trailingGroup,
            ],
          );
        }
        final actionsWrap = Wrap(
          spacing: 6,
          runSpacing: 6,
          children: actionButtons,
        );
        final useCompactStack = constraints.maxWidth < 405;
        if (useCompactStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  if (showStatusLabel) statusPill else const Spacer(),
                  if (showStatusLabel) const SizedBox(width: 8),
                  trailingGroup,
                ],
              ),
              const SizedBox(height: 6),
              actionsWrap,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [if (showStatusLabel) statusPill, ...actionButtons],
              ),
            ),
            const SizedBox(width: 8),
            trailingGroup,
          ],
        );
      },
    );
  }

  Widget _buildSendButton() {
    final isStop = capabilities.showStopAction;
    final canSend = isStop || capabilities.canSendAction;
    return ActionButton(
      label: isStop ? '停止' : capabilities.submitLabel,
      icon: isStop ? Icons.stop_circle_outlined : Icons.send_rounded,
      tone: isStop ? ActionButtonTone.danger : ActionButtonTone.accent,
      compact: true,
      expanded: true,
      emphasized: !isStop,
      disabled: !canSend,
      onPressed: isStop ? actionHandler.onStopRequested : onSendRequested,
    );
  }
}
