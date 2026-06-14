import 'package:flutter/material.dart';

import '../../../../../shared/theme/novel_theme_context.dart';
import '../../application/models/conversation_tool_lifecycle_status.dart';
import '../../application/services/conversation_input_capability_service.dart';
import '../layout/conversation_section_id.dart';
import '../layout/conversation_section_layout.dart';
import '../layout/conversation_section_layout_policy.dart';
import '../contracts/conversation_action_handler.dart';
import '../models/conversation_input_capability_state.dart';
import '../models/conversation_opening_state_view_data.dart';
import '../models/conversation_pending_input_preview_view_data.dart';
import '../models/conversation_entry_view_data.dart';
import '../models/conversation_status_summary_view_data.dart';
import '../models/conversation_sub_agent_detail_route_state.dart';
import '../models/primary_action_view_data.dart';
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
import 'context_status_badge.dart';
import 'conversation_panel_header.dart';
import 'conversation_panel_status_group.dart';
import 'conversation_runtime_status_strip.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final style = ConversationPanelStyle.of(context);
        final panelSurface = context.novelThemeSurfaces.panel;
        final sidebarSurface = context.novelThemeSurfaces.sidebar;
        final isMinimalSurface = constraints.maxWidth <= 430;
        final hasConversation =
            widget.viewData.conversationEntries.isNotEmpty ||
            widget.viewData.pendingOptions.isNotEmpty ||
            widget.viewData.subAgentRuns.isNotEmpty ||
            widget.viewData.isGenerating;
        final statusSummary = _statusSummaryService.build(
          viewData: widget.viewData,
        );
        return Padding(
          padding: EdgeInsets.fromLTRB(
            style.outerPadding.left,
            isMinimalSurface ? 4 : style.outerPadding.top,
            style.outerPadding.right,
            isMinimalSurface ? 4 : style.outerPadding.bottom,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: panelSurface.backgroundColor.withValues(
                alpha: isMinimalSurface ? 0.08 : 0.14,
              ),
              gradient: isMinimalSurface
                  ? null
                  : LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        panelSurface.backgroundColor.withValues(alpha: 0.18),
                        sidebarSurface.backgroundColor.withValues(alpha: 0.08),
                      ],
                    ),
              borderRadius: BorderRadius.circular(
                isMinimalSurface
                    ? style.sectionRadius
                    : style.sectionRadius + 2,
              ),
              border: isMinimalSurface
                  ? null
                  : Border(
                      top: BorderSide(
                        color: panelSurface.borderColor.withValues(alpha: 0.12),
                      ),
                    ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                style.surfacePadding.left,
                isMinimalSurface ? 4 : style.surfacePadding.top,
                style.surfacePadding.right,
                isMinimalSurface ? 4 : style.surfacePadding.bottom,
              ),
              child:
                  ValueListenableBuilder<ConversationSubAgentDetailRouteState>(
                    valueListenable: _detailRoute,
                    builder: (context, routeState, _) {
                      final activeSubAgentRun = _detailRouteService
                          .resolveActiveRun(
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
                            statusSummary: statusSummary,
                            isMinimalSurface: isMinimalSurface,
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
        );
      },
    );
  }

  List<ConversationSectionEntry> _buildSectionEntries({
    required bool hasConversation,
    required String? activeSubAgentRunId,
    required ConversationStatusSummaryViewData statusSummary,
    required bool isMinimalSurface,
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
          minimal: isMinimalSurface,
        ),
      ),
      ConversationSectionEntry(
        sectionId: ConversationSectionId.runtimeStatus,
        child: _ConversationStatusDeck(
          viewData: widget.viewData,
          statusSummary: statusSummary,
          minimal: isMinimalSurface,
        ),
      ),
      ConversationSectionEntry(
        sectionId: ConversationSectionId.timeline,
        child: _buildMainBody(
          hasConversation,
          activeSubAgentRunId,
          isMinimalSurface,
        ),
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

  Widget _buildMainBody(
    bool hasConversation,
    String? activeSubAgentRunId,
    bool isMinimalSurface,
  ) {
    final emptyStateActions = _emptyStateActionService.visibleActions(
      widget.viewData,
    );
    if (!hasConversation && !widget.viewData.showSessionHistory) {
      if (isMinimalSurface) {
        return _MinimalConversationEmptyState(
          title: widget.viewData.workflowTitle,
          description: widget.viewData.workflowDescription,
          openingState: widget.viewData.openingState,
          actions: emptyStateActions,
          actionHandler: widget.actionHandler,
        );
      }
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
          SizedBox(height: ConversationPanelStyle.of(context).bodyGap),
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
          SizedBox(height: ConversationPanelStyle.of(context).sectionGap),
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

class _ConversationStatusDeck extends StatelessWidget {
  const _ConversationStatusDeck({
    required this.viewData,
    required this.statusSummary,
    required this.minimal,
  });

  final WorkbenchConversationViewData viewData;
  final ConversationStatusSummaryViewData statusSummary;
  final bool minimal;

  @override
  Widget build(BuildContext context) {
    final runtimeText = _runtimeText();
    final runtimeStatus = _runtimeStatus();
    final cleanRuntimeText = runtimeText.trim();
    final contextProjection = viewData.conversationContextProjection;
    if (statusSummary.items.isEmpty &&
        cleanRuntimeText.isEmpty &&
        contextProjection == null) {
      return const SizedBox.shrink();
    }
    if (minimal) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (contextProjection != null) ...[
            ContextStatusBadge(projection: contextProjection),
            SizedBox(
              height: ConversationPanelStyle.of(context).gap(-0.75, min: 4),
            ),
          ],
          if (statusSummary.items.isNotEmpty) ...[
            ConversationPanelStatusGroup(
              viewData: statusSummary,
              onItemPressed: (_) {},
            ),
            if (cleanRuntimeText.isNotEmpty)
              SizedBox(
                height: ConversationPanelStyle.of(context).gap(-0.5, min: 3),
              ),
          ],
          if (cleanRuntimeText.isNotEmpty)
            ConversationRuntimeStatusStrip(
              text: cleanRuntimeText,
              status: runtimeStatus,
            ),
        ],
      );
    }
    final style = ConversationPanelStyle.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (contextProjection != null) ...[
          ContextStatusBadge(projection: contextProjection),
          SizedBox(height: style.gap(-0.8, min: 4)),
        ],
        if (statusSummary.items.isNotEmpty) ...[
          ConversationPanelStatusGroup(
            viewData: statusSummary,
            onItemPressed: (_) {},
          ),
        ],
        if (cleanRuntimeText.isNotEmpty) ...[
          if (statusSummary.items.isNotEmpty)
            SizedBox(height: style.gap(-0.5, min: 3)),
          ConversationRuntimeStatusStrip(
            text: cleanRuntimeText,
            status: runtimeStatus,
          ),
        ],
      ],
    );
  }

  String _runtimeText() {
    final toolText = viewData.toolCoreStatus.trim();
    if (toolText.isNotEmpty) {
      return toolText;
    }
    return viewData.generationStatus.trim();
  }

  ConversationToolLifecycleStatus _runtimeStatus() {
    if (viewData.pendingOptions.isNotEmpty) {
      return ConversationToolLifecycleStatus.pendingConfirmation;
    }
    final latestToolStatus = _latestToolLifecycleStatus();
    if (latestToolStatus != null) {
      return latestToolStatus;
    }
    if (viewData.retryRequest != null) {
      return ConversationToolLifecycleStatus.failed;
    }
    if (viewData.isGenerating) {
      return ConversationToolLifecycleStatus.running;
    }
    return ConversationToolLifecycleStatus.completed;
  }

  ConversationToolLifecycleStatus? _latestToolLifecycleStatus() {
    for (final entry in viewData.conversationEntries.reversed) {
      if (entry.kind != ConversationEntryKind.tool ||
          entry.toolLifecycleStatus == null) {
        continue;
      }
      return entry.toolLifecycleStatus;
    }
    return null;
  }
}

class _MinimalConversationEmptyState extends StatelessWidget {
  const _MinimalConversationEmptyState({
    required this.title,
    required this.description,
    required this.openingState,
    required this.actions,
    required this.actionHandler,
  });

  final String title;
  final String description;
  final ConversationOpeningStateViewData? openingState;
  final List<PrimaryActionViewData> actions;
  final ConversationActionHandler actionHandler;

  @override
  Widget build(BuildContext context) {
    final style = ConversationPanelStyle.of(context);
    final theme = context.novelThemeColors;
    final prompt = openingState?.firstPrompt.trim().isNotEmpty == true
        ? openingState!.firstPrompt.trim()
        : description.trim();
    final visibleActions =
        openingState?.preferSingleAction == true &&
            openingState?.nextAction != null
        ? [openingState!.nextAction!]
        : actions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: style.titleFontSize - 0.4,
            fontWeight: FontWeight.w800,
            color: theme.textColor,
          ),
        ),
        if (prompt.isNotEmpty) ...[
          SizedBox(height: style.gap(-1.2, min: 6)),
          Text(
            prompt,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: style.bodyFontSize,
              height: style.bodyLineHeight,
              fontWeight: FontWeight.w500,
              color: theme.mutedTextColor,
            ),
          ),
        ],
        if (visibleActions.isNotEmpty) ...[
          SizedBox(height: style.gap(2.5, min: 10)),
          PrimaryActionList(
            actions: visibleActions,
            actionHandler: actionHandler,
          ),
        ],
      ],
    );
  }
}
