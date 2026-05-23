import 'package:flutter/material.dart';

import '../contracts/conversation_action_handler.dart';
import '../models/user_option_view_data.dart';
import '../models/workbench_view_data.dart';
import 'conversation_empty_state_panel.dart';
import 'conversation_secondary_actions_row.dart';
import 'conversation_timeline.dart';
import 'composer_panel.dart';
import 'context_status_badge.dart';
import 'conversation_toolbar.dart';
import 'primary_action_list.dart';
import 'session_history_panel.dart';
import 'selector_field.dart';
import 'sub_agent_activity_panel.dart';
import 'user_option_panel.dart';
import 'workflow_guide_card.dart';

class ConversationSidebar extends StatefulWidget {
  const ConversationSidebar({
    super.key,
    required this.viewData,
    required this.actionHandler,
    this.showWorkspaceShortcuts = false,
  });

  final WorkbenchViewData viewData;
  final ConversationActionHandler actionHandler;
  final bool showWorkspaceShortcuts;

  @override
  State<ConversationSidebar> createState() => _ConversationSidebarState();
}

class _ConversationSidebarState extends State<ConversationSidebar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    // 中文注释: 会话侧栏拥有自己的输入控制器，因此由本组件负责释放。
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 智能体侧栏只承接会话相关信息与输入链路，不进入资源树和正文区的职责边界。
    final hasConversation =
        widget.viewData.conversationEntries.isNotEmpty ||
        widget.viewData.pendingOptions.isNotEmpty ||
        widget.viewData.subAgentRuns.isNotEmpty ||
        widget.viewData.isGenerating;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConversationToolbar(
            onQuickThemeRequested: widget.actionHandler.onQuickThemeRequested,
            onScreenModeRequested: widget.actionHandler.onScreenModeRequested,
            onHistoryRequested: widget.actionHandler.onHistoryRequested,
            onNewSessionRequested: widget.actionHandler.onNewSessionRequested,
          ),
          if (widget.showWorkspaceShortcuts) ...[
            const SizedBox(height: 8),
            ConversationSecondaryActionsRow(
              onDocumentsRequested:
                  widget.actionHandler.onDocumentsWorkspaceRequested,
              onSettingsRequested:
                  widget.actionHandler.onConversationSettingsRequested,
            ),
          ],
          const SizedBox(height: 8),
          ContextStatusBadge(summary: widget.viewData.contextSummary),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SelectorField(
                  label: '模型',
                  value: widget.viewData.modelLabel,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SelectorField(
                  label: '智能体',
                  value: widget.viewData.agentLabel,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(child: _buildMainBody(hasConversation)),
          const SizedBox(height: 8),
          ComposerPanel(
            controller: _controller,
            hintText: widget.viewData.composerHint,
            onOptimizeRequested: widget.actionHandler.onOptimizeRequested,
            onToolOptionsRequested: widget.actionHandler.onToolOptionsRequested,
            onSendRequested: _handleSendRequested,
          ),
        ],
      ),
    );
  }

  Widget _buildMainBody(bool hasConversation) {
    // 中文注释: 空态和会话态拆成两种主体布局，避免只有空态时留下一整块无法利用的滚动空白。
    if (!hasConversation && !widget.viewData.showSessionHistory) {
      return ConversationEmptyStatePanel(
        title: widget.viewData.workflowTitle,
        description: widget.viewData.workflowDescription,
        actions: widget.viewData.primaryActions,
        actionHandler: widget.actionHandler,
        onSettingsRequested:
            widget.actionHandler.onConversationSettingsRequested,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.viewData.showSessionHistory) ...[
          SessionHistoryPanel(
            entries: widget.viewData.sessionHistoryEntries,
            onSelected: widget.actionHandler.onSessionHistorySelected,
          ),
          const SizedBox(height: 10),
        ],
        Expanded(
          child: hasConversation
              ? ConversationTimeline(
                  entries: widget.viewData.conversationEntries,
                  isGenerating: widget.viewData.isGenerating,
                )
              : WorkflowGuideCard(
                  title: widget.viewData.workflowTitle,
                  description: widget.viewData.workflowDescription,
                  onSettingsRequested:
                      widget.actionHandler.onConversationSettingsRequested,
                ),
        ),
        if (!hasConversation) ...[
          const SizedBox(height: 8),
          PrimaryActionList(
            actions: widget.viewData.primaryActions,
            actionHandler: widget.actionHandler,
          ),
        ],
        if (widget.viewData.pendingOptions.isNotEmpty) ...[
          const SizedBox(height: 8),
          UserOptionPanel(
            options: widget.viewData.pendingOptions,
            onSelected: _handleOptionSelected,
          ),
        ],
        if (widget.viewData.subAgentRuns.isNotEmpty) ...[
          const SizedBox(height: 8),
          SubAgentActivityPanel(runs: widget.viewData.subAgentRuns),
        ],
      ],
    );
  }

  void _handleSendRequested(String text) {
    // 中文注释: 侧栏只负责清理输入框和转发文本，不直接知道控制器如何调度模型与工具。
    if (text.trim().isEmpty) {
      return;
    }
    widget.actionHandler.onSendRequested(text);
    _controller.clear();
  }

  void _handleOptionSelected(UserOptionViewData option) {
    // 中文注释: 选项点击统一上抛成会话动作，避免 UI 组件自行拼接后续 prompt。
    widget.actionHandler.onUserOptionSelected(option);
  }
}
