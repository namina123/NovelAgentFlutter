import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/conversation_agent_selector_view_data.dart';
import 'selector_field.dart';

class ConversationAgentHeaderStrip extends StatelessWidget {
  const ConversationAgentHeaderStrip({
    super.key,
    required this.agentSelector,
    required this.onSelected,
  });

  final ConversationAgentSelectorViewData agentSelector;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.sidebar;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '当前会话智能体',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: surface.mutedForegroundColor,
          ),
        ),
        const SizedBox(height: 6),
        SelectorField(
          key: const ValueKey<String>('conversation_header_agent_selector'),
          label: '智能体',
          value: agentSelector.currentAgentLabel,
          options: agentSelector.agentOptions,
          enabled: agentSelector.canSwitchAgent,
          onSelected: onSelected,
        ),
      ],
    );
  }
}
