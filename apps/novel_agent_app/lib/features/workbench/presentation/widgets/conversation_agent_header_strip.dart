import 'package:flutter/material.dart';

import '../models/conversation_agent_selector_view_data.dart';
import 'selector_field.dart';

class ConversationAgentHeaderStrip extends StatelessWidget {
  const ConversationAgentHeaderStrip({
    super.key,
    required this.agentSelector,
    required this.onSelected,
    this.minimal = false,
  });

  final ConversationAgentSelectorViewData agentSelector;
  final ValueChanged<String> onSelected;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    return SelectorField(
      key: const ValueKey<String>('conversation_header_agent_selector'),
      label: '智能体',
      value: agentSelector.currentAgentLabel,
      options: agentSelector.agentOptions,
      enabled: agentSelector.canSwitchAgent,
      onSelected: onSelected,
      showLabel: !minimal,
    );
  }
}
