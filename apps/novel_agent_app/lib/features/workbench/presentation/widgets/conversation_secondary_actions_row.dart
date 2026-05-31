import 'package:flutter/material.dart';

import '../../../../../shared/widgets/action_button.dart';

class ConversationSecondaryActionsRow extends StatelessWidget {
  const ConversationSecondaryActionsRow({
    super.key,
    required this.onDocumentsRequested,
  });

  final VoidCallback onDocumentsRequested;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 窄屏工作台补充入口独立成行，后续改按钮数量和顺序时不会波及会话主体。
    return ActionButton(
      label: '文档',
      icon: Icons.description_outlined,
      tone: ActionButtonTone.neutral,
      expanded: true,
      onPressed: onDocumentsRequested,
    );
  }
}
