import 'package:flutter/material.dart';

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
    // 中文注释: 输入区动作行只承接按钮布局和显隐，不把发送、停止、附件逻辑堆回文本框组件。
    return LayoutBuilder(
      builder: (context, constraints) {
        final actionButtons = <Widget>[];
        void appendAction(Widget child) {
          if (actionButtons.isNotEmpty) {
            actionButtons.add(const SizedBox(width: 8));
          }
          actionButtons.add(child);
        }

        if (capabilities.showOptimizeAction) {
          appendAction(
            Expanded(
              child: ActionButton(
                label: '优化',
                icon: Icons.auto_fix_high_outlined,
                tone: ActionButtonTone.warm,
                compact: true,
                expanded: true,
                onPressed: actionHandler.onOptimizeRequested,
              ),
            ),
          );
        }
        if (capabilities.showToolOptionsAction) {
          appendAction(
            Expanded(
              child: ActionButton(
                label: '工具',
                icon: Icons.tune_outlined,
                tone: ActionButtonTone.neutral,
                compact: true,
                expanded: true,
                onPressed: actionHandler.onToolOptionsRequested,
              ),
            ),
          );
        }
        if (capabilities.showAttachmentEntry) {
          appendAction(
            Expanded(
              child: ActionButton(
                label: '附件',
                icon: Icons.attach_file_rounded,
                tone: ActionButtonTone.neutral,
                compact: true,
                expanded: true,
                onPressed: actionHandler.onAttachmentRequested,
              ),
            ),
          );
        }
        final reasoningToggle = capabilities.showReasoningToggle
            ? ConversationReasoningToggleChip(
                enabled: capabilities.reasoningEnabled,
                onChanged: actionHandler.onReasoningToggleChanged,
              )
            : null;
        final sendButton = SizedBox(width: 112, child: _buildSendButton());
        final trailingChildren = <Widget>[];
        if (reasoningToggle != null) {
          trailingChildren.add(reasoningToggle);
          trailingChildren.add(const SizedBox(width: 8));
        }
        trailingChildren.add(sendButton);
        final trailingGroup = Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: trailingChildren,
        );
        if (actionButtons.isEmpty) {
          return Align(alignment: Alignment.centerRight, child: trailingGroup);
        }
        final useCompactStack = constraints.maxWidth < 360;
        if (useCompactStack) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: actionButtons),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: trailingGroup),
            ],
          );
        }
        return Row(
          children: [
            Expanded(child: Row(children: actionButtons)),
            const SizedBox(width: 8),
            trailingGroup,
          ],
        );
      },
    );
  }

  Widget _buildSendButton() {
    final button = ActionButton(
      label: capabilities.showStopAction ? '停止' : capabilities.submitLabel,
      icon: capabilities.showStopAction
          ? Icons.stop_circle_outlined
          : Icons.send_rounded,
      tone: capabilities.showStopAction
          ? ActionButtonTone.danger
          : ActionButtonTone.accent,
      compact: true,
      expanded: true,
      onPressed: capabilities.showStopAction
          ? actionHandler.onStopRequested
          : onSendRequested,
    );
    if (capabilities.showStopAction || capabilities.canSendAction) {
      return button;
    }
    return IgnorePointer(child: Opacity(opacity: 0.52, child: button));
  }
}
