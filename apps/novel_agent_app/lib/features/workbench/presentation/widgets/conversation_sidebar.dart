import 'package:flutter/material.dart';

import '../../application/services/conversation_input_capability_service.dart';
import '../layout/conversation_section_id.dart';
import '../layout/conversation_section_layout.dart';
import '../layout/conversation_section_layout_policy.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/conversation_input_capability_state.dart';
import '../models/conversation_pending_input_preview_view_data.dart';
import '../models/conversation_sub_agent_detail_route_state.dart';
import '../models/sub_agent_run_view_data.dart';
import '../models/user_option_view_data.dart';
import '../models/workbench_conversation_view_data.dart';
import '../services/conversation_empty_state_action_projection_service.dart';
import '../services/conversation_pending_input_preview_service.dart';
import '../services/conversation_status_summary_view_data_service.dart';
import '../services/conversation_sub_agent_detail_route_service.dart';
import 'conversation_composer_panel.dart';
import 'conversation_empty_state_panel.dart';
import 'conversation_fullscreen_host.dart';
import 'conversation_panel_header.dart';
import 'conversation_section_host.dart';
import 'conversation_panel_style.dart';
import 'conversation_timeline.dart';
import 'conversation_pending_input_preview_panel.dart';
import 'primary_action_list.dart';
import 'session_history_panel.dart';
import 'sub_agent_run_detail_view.dart';
import 'transcript_block_renderer_registry.dart';
import 'workflow_guide_card.dart';

class ConversationSidebar extends StatefulWidget {
  const ConversationSidebar({
    super.key,
    required this.viewData,
    required this.actionHandler,
    this.showWorkspaceShortcuts = false,
    this.sectionLayout = ConversationSectionLayoutPolicy.defaultLayout,
  });

  final WorkbenchConversationViewData viewData;
  final ConversationActionHandler actionHandler;
  final bool showWorkspaceShortcuts;
  final ConversationSectionLayout sectionLayout;

  @override
  State<ConversationSidebar> createState() => _ConversationSidebarState();
}

class _ConversationSidebarState extends State<ConversationSidebar> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _composerScrollController = ScrollController();
  final ValueNotifier<String> _pendingPreviewText = ValueNotifier('');
  final ValueNotifier<ConversationSubAgentDetailRouteState> _detailRoute =
      ValueNotifier(const ConversationSubAgentDetailRouteState.idle());
  final ConversationInputCapabilityService _inputCapabilityService =
      ConversationInputCapabilityService();
  final ConversationPendingInputPreviewService _pendingInputPreviewService =
      const ConversationPendingInputPreviewService();
  final ConversationSubAgentDetailRouteService _detailRouteService =
      const ConversationSubAgentDetailRouteService();
  final ConversationEmptyStateActionProjectionService _emptyStateActionService =
      const ConversationEmptyStateActionProjectionService();
  final ConversationStatusSummaryViewDataService _statusSummaryService =
      const ConversationStatusSummaryViewDataService();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncPendingPreviewText);
  }

  @override
  void didUpdateWidget(covariant ConversationSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sanitized = _detailRouteService.sanitize(
      _detailRoute.value,
      widget.viewData.subAgentRuns,
    );
    if (sanitized != _detailRoute.value) {
      _detailRoute.value = sanitized;
    }
  }

  @override
  void dispose() {
    // 中文注释: 会话侧栏拥有自己的输入控制器，因此由本组件负责释放。
    _composerScrollController.dispose();
    _detailRoute.dispose();
    _pendingPreviewText.dispose();
    _controller.removeListener(_syncPendingPreviewText);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 中文注释: 智能体侧栏只承接会话相关信息与输入链路，不进入资源树和正文区的职责边界。
    final style = ConversationPanelStyle.of(context);
    final hasConversation =
        widget.viewData.conversationEntries.isNotEmpty ||
        widget.viewData.pendingOptions.isNotEmpty ||
        widget.viewData.subAgentRuns.isNotEmpty ||
        widget.viewData.isGenerating;
    return Padding(
      padding: style.outerPadding,
      child: ValueListenableBuilder<ConversationSubAgentDetailRouteState>(
        valueListenable: _detailRoute,
        builder: (context, routeState, _) {
          final activeSubAgentRun = _detailRouteService.resolveActiveRun(
            routeState,
            widget.viewData.subAgentRuns,
          );
          return ConversationFullscreenHost(
            isActive: activeSubAgentRun != null,
            fullscreenChild: activeSubAgentRun == null
                ? null
                : SubAgentRunDetailView(
                    run: activeSubAgentRun,
                    onBack: _clearActiveSubAgentRun,
                  ),
            primaryChild: ConversationSectionHost(
              layout: widget.sectionLayout,
              slotGap: style.bodyGap,
              sectionGap: style.sectionGap,
              entries: _buildSectionEntries(
                hasConversation: hasConversation,
                activeSubAgentRunId: routeState.activeRunId,
              ),
            ),
          );
        },
      ),
    );
  }

  List<ConversationSectionEntry> _buildSectionEntries({
    required bool hasConversation,
    required String? activeSubAgentRunId,
  }) {
    final entries = <ConversationSectionEntry>[
      ConversationSectionEntry(
        sectionId: ConversationSectionId.panelHeader,
        child: ConversationPanelHeader(
          agentSelector: widget.viewData.agentSelector,
          showWorkspaceShortcuts: widget.showWorkspaceShortcuts,
          onHistoryRequested: widget.actionHandler.onHistoryRequested,
          onNewSessionRequested: widget.actionHandler.onNewSessionRequested,
          onConversationAgentSelected:
              widget.actionHandler.onConversationAgentSelected,
          onDocumentsRequested:
              widget.actionHandler.onDocumentsWorkspaceRequested,
        ),
      ),
      ConversationSectionEntry(
        sectionId: ConversationSectionId.timeline,
        child: _buildMainBody(hasConversation, activeSubAgentRunId),
      ),
    ];
    if (widget.viewData.isGenerating) {
      entries.add(
        ConversationSectionEntry(
          sectionId: ConversationSectionId.pendingInput,
          child: ValueListenableBuilder<String>(
            valueListenable: _pendingPreviewText,
            builder: (context, _, _) {
              final latestPendingPreview = _pendingPreviewViewData();
              if (latestPendingPreview == null) {
                return const SizedBox.shrink();
              }
              return ConversationPendingInputPreviewPanel(
                viewData: latestPendingPreview,
              );
            },
          ),
        ),
      );
    }
    entries.addAll([
      ConversationSectionEntry(
        sectionId: ConversationSectionId.composer,
        child: ConversationComposerPanel(
          controller: _controller,
          scrollController: _composerScrollController,
          hintText: widget.viewData.composerHint,
          capabilities: _inputCapabilities(),
          viewData: widget.viewData,
          actionHandler: widget.actionHandler,
          onSendRequested: () => _handleSendRequested(_controller.text.trim()),
        ),
      ),
    ]);
    return entries;
  }

  Widget _buildMainBody(bool hasConversation, String? activeSubAgentRunId) {
    // 中文注释: 空态和会话态拆成两种主体布局，避免只有空态时留下一整块无法利用的滚动空白。
    final emptyStateActions = _emptyStateActionService.visibleActions(
      widget.viewData,
    );
    if (!hasConversation && !widget.viewData.showSessionHistory) {
      return ConversationEmptyStatePanel(
        title: widget.viewData.workflowTitle,
        description: widget.viewData.workflowDescription,
        actions: emptyStateActions,
        actionHandler: widget.actionHandler,
        openingState: widget.viewData.openingState,
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
                  lanes: widget.viewData.transcriptLanes,
                  renderContext: TranscriptBlockRenderContext(
                    showToolDetails: _statusSummaryService.showToolDetails(
                      widget.viewData,
                    ),
                    onRetryRequested:
                        widget.actionHandler.onRetryLastFailedRequested,
                    onUserOptionSelected: _handleOptionSelected,
                    onSubAgentSelected: _selectSubAgentRun,
                    activeSubAgentRunId: activeSubAgentRunId,
                  ),
                )
              : WorkflowGuideCard(
                  title: widget.viewData.workflowTitle,
                  description: widget.viewData.workflowDescription,
                  openingState: widget.viewData.openingState,
                  actionHandler: widget.actionHandler,
                ),
        ),
        if (!hasConversation &&
            widget.viewData.openingState == null &&
            emptyStateActions.isNotEmpty) ...[
          const SizedBox(height: 8),
          PrimaryActionList(
            actions: emptyStateActions,
            actionHandler: widget.actionHandler,
          ),
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

  void _syncPendingPreviewText() {
    final next = _controller.text;
    if (_pendingPreviewText.value == next) {
      return;
    }
    _pendingPreviewText.value = next;
  }

  void _selectSubAgentRun(SubAgentRunViewData run) {
    _detailRoute.value = _detailRouteService.selectRun(_detailRoute.value, run);
  }

  void _clearActiveSubAgentRun() {
    _detailRoute.value = _detailRouteService.clear(_detailRoute.value);
  }

  ConversationInputCapabilityState _inputCapabilities() {
    return _inputCapabilityService.resolve(
      context: widget.viewData.inputCapabilityContext.copyWith(
        isGenerating: widget.viewData.isGenerating,
        hasActiveProject: widget.viewData.hasActiveProject,
      ),
    );
  }

  ConversationPendingInputPreviewViewData? _pendingPreviewViewData() {
    return _pendingInputPreviewService.build(
      rawText: _pendingPreviewText.value,
      isGenerating: widget.viewData.isGenerating,
    );
  }
}
