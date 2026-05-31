import 'package:flutter/material.dart';

import '../models/conversation_agent_selector_view_data.dart';
import 'conversation_agent_header_strip.dart';
import 'conversation_secondary_actions_row.dart';
import 'conversation_toolbar.dart';

class ConversationPanelHeader extends StatelessWidget {
  const ConversationPanelHeader({
    super.key,
    required this.agentSelector,
    required this.showWorkspaceShortcuts,
    required this.onHistoryRequested,
    required this.onNewSessionRequested,
    required this.onConversationAgentSelected,
    required this.onDocumentsRequested,
  });

  final ConversationAgentSelectorViewData agentSelector;
  final bool showWorkspaceShortcuts;
  final VoidCallback onHistoryRequested;
  final VoidCallback onNewSessionRequested;
  final ValueChanged<String> onConversationAgentSelected;
  final VoidCallback onDocumentsRequested;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ConversationToolbar(
          title: '会话',
          onHistoryRequested: onHistoryRequested,
          onNewSessionRequested: onNewSessionRequested,
        ),
        const SizedBox(height: 10),
        ConversationAgentHeaderStrip(
          agentSelector: agentSelector,
          onSelected: onConversationAgentSelected,
        ),
        if (showWorkspaceShortcuts) ...[
          const SizedBox(height: 10),
          ConversationSecondaryActionsRow(
            onDocumentsRequested: onDocumentsRequested,
          ),
        ],
      ],
    );
  }
}
