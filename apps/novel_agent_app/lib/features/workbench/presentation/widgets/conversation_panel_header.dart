import 'package:flutter/material.dart';

import '../../../../../app/theme/app_chrome.dart';
import '../../../../../shared/theme/novel_theme_context.dart';
import '../models/conversation_agent_selector_view_data.dart';
import 'conversation_agent_header_strip.dart';
import 'conversation_panel_style.dart';
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
    this.minimal = false,
  });

  final ConversationAgentSelectorViewData agentSelector;
  final bool showWorkspaceShortcuts;
  final VoidCallback onHistoryRequested;
  final VoidCallback onNewSessionRequested;
  final ValueChanged<String> onConversationAgentSelected;
  final VoidCallback onDocumentsRequested;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final surface = context.novelThemeSurfaces.panel;
    final style = ConversationPanelStyle.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.backgroundColor.withValues(alpha: minimal ? 0.02 : 0.04),
        borderRadius: BorderRadius.circular(style.sectionRadius),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          minimal ? 0 : 2,
          minimal ? 0 : 2,
          minimal ? 0 : 2,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConversationToolbar(
              title: '会话',
              onHistoryRequested: onHistoryRequested,
              onNewSessionRequested: onNewSessionRequested,
              minimal: minimal,
            ),
            SizedBox(height: style.gap(-1, min: 2)),
            ConversationAgentHeaderStrip(
              agentSelector: agentSelector,
              onSelected: onConversationAgentSelected,
              minimal: minimal,
            ),
            if (showWorkspaceShortcuts && !minimal) ...[
              SizedBox(height: style.gap(-0.75, min: 3)),
              Container(
                height: AppChrome.borderWidth,
                color: surface.borderColor.withValues(alpha: 0.08),
              ),
              SizedBox(height: style.gap(-0.75, min: 3)),
              ConversationSecondaryActionsRow(
                onDocumentsRequested: onDocumentsRequested,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
