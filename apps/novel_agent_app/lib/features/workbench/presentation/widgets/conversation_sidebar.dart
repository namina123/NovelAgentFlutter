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
import '../models/conversation_status_summary_item_view_data.dart';
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
  // 中文注释: 用 session+项目存在性组合指纹判定"进入了新对话上下文"，
  // 比单看 sessionId 更稳——覆盖空 sessionId 的新项目加载，也避免把 A 的未发文本带到 B。
  String _lastConversationFingerprint = '';
  // 中文注释: 用户关掉"未配置模型"banner 后临时记住，直到下一次切换对话上下文再恢复提示。
  bool _modelBannerDismissed = false;
  // 中文注释: 状态条已折叠的条目 id（如归档压缩明细）——让带箭头的 chip 真能收起。
  final Set<String> _collapsedStatusItemIds = <String>{};

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncPendingPreviewText);
    _detailRoute.addListener(_syncForegroundBackHandler);
    _lastConversationFingerprint = _conversationFingerprint();
  }

  String _conversationFingerprint() =>
      '${widget.viewData.activeSessionId}|${widget.viewData.hasActiveProject ? 1 : 0}';

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
    // 中文注释: subAgentRuns 变化（如运行完成/移除）即便没改 _detailRoute 也可能改变"是否有全屏"，
    // 这里补一次同步，确保返回键接管与当前全屏态一致。
    _syncForegroundBackHandler();
    // 中文注释: 指纹变化=进入新对话上下文：清空草稿 + 重置 banner 关闭态。
    final fingerprint = _conversationFingerprint();
    if (fingerprint != _lastConversationFingerprint) {
      _lastConversationFingerprint = fingerprint;
      _modelBannerDismissed = false;
      if (_controller.text.isNotEmpty) {
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    // 中文注释: 会话侧栏拥有自己的输入控制器，因此由本组件负责释放。
    _composerScrollController.dispose();
    // 中文注释: 释放前先取消返回键接管，避免壳层持有指向已销毁侧栏的回调。
    widget.actionHandler.setForegroundBackHandler(null);
    _detailRoute.removeListener(_syncForegroundBackHandler);
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
          historyOpen: widget.viewData.showSessionHistory,
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
          collapsedItemIds: _collapsedStatusItemIds,
          onItemToggle: (id) {
            setState(() {
              if (_collapsedStatusItemIds.contains(id)) {
                _collapsedStatusItemIds.remove(id);
              } else {
                _collapsedStatusItemIds.add(id);
              }
            });
          },
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
                // 中文注释: 待发送草稿就是输入框当前文本——清空即清输入框并同步预览，
                // 让用户快速丢弃误排队的草稿，而不必手选整段删除。
                onClear: () {
                  _controller.clear();
                  _pendingPreviewText.value = '';
                },
              );
            },
          ),
        ),
      );
    }
    entries.addAll([
      ConversationSectionEntry(
        sectionId: ConversationSectionId.composer,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 中文注释: 有项目但未配置写作模型时，在输入区上方提示并给出"去设置"入口，
            // 否则用户只能盲发、撞到一句不可见的错误。用户可临时关闭，切换对话上下文后恢复。
            // 额外要求"不在加载中"——加载期间 modelOptions 可能瞬时为空，避免 banner 闪一下又消失。
            if (widget.viewData.hasActiveProject &&
                widget.viewData.modelOptions.isEmpty &&
                !widget.viewData.generationStatus.contains('正在加载'))
              // 中文注释: 关掉大 banner 后保留一行紧凑提示，否则发送按钮置灰却没有任何就近
              // 说明，用户会以为按钮坏了。紧凑提示无关闭键——它就是用户接受"已知此事"后的常态提示。
              _modelBannerDismissed
                  ? _ModelConfigHint(
                      onSettingsRequested:
                          widget.actionHandler.onConversationSettingsRequested,
                    )
                  : _ModelConfigBanner(
                      onSettingsRequested:
                          widget.actionHandler.onConversationSettingsRequested,
                      onDismiss: () =>
                          setState(() => _modelBannerDismissed = true),
                    ),
            ConversationComposerPanel(
              controller: _controller,
              scrollController: _composerScrollController,
              hintText: widget.viewData.composerHint,
              capabilities: _inputCapabilities(),
              viewData: widget.viewData,
              actionHandler: widget.actionHandler,
              onSendRequested: () =>
                  _handleSendRequested(_controller.text.trim()),
            ),
          ],
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
    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: hasConversation
                  ? ConversationTimeline(
                      lanes: widget.viewData.transcriptLanes,
                      restoreResult: widget.viewData.sessionRestoreResult,
                      renderContext: TranscriptBlockRenderContext(
                        showToolDetails: _statusSummaryService.showToolDetails(
                          widget.viewData,
                        ),
                        onRetryRequested:
                            widget.actionHandler.onRetryLastFailedRequested,
                        onUserOptionSelected: _handleOptionSelected,
                        onSubAgentSelected: _selectSubAgentRun,
                        activeSubAgentRunId: activeSubAgentRunId,
                        // 中文注释: 占位卡的「停止」复用 _inputCapabilities().showStopAction 闸门——
                        // 与输入栏的停止同源（部分操作不可取消时两者都不出现），不绕过闸门。
                        onStopRequested: _inputCapabilities().showStopAction
                            ? widget.actionHandler.onStopRequested
                            : null,
                      ),
                    )
                  : WorkflowGuideCard(
                      title: widget.viewData.workflowTitle,
                      description: widget.viewData.workflowDescription,
                      actions: emptyStateActions,
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
        ),
        if (widget.viewData.showSessionHistory &&
            widget.viewData.sessionHistoryEntries.isNotEmpty)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: widget.actionHandler.onHistoryRequested,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: isMinimalSurface ? 8 : 16,
                    top: 2,
                    right: isMinimalSurface ? 2 : 6,
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {},
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMinimalSurface ? 420 : 336,
                        minWidth: isMinimalSurface ? 220 : 280,
                      ),
                      child: SessionHistoryPanel(
                        entries: widget.viewData.sessionHistoryEntries,
                        onSelected:
                            widget.actionHandler.onSessionHistorySelected,
                        onDismiss: widget.actionHandler.onHistoryRequested,
                        floating: true,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        else if (widget.viewData.showSessionHistory)
          // 中文注释: 历史按钮已点亮但还没有任何会话时，给一行占位提示——否则按钮高亮却什么都不弹，
          // 新用户会以为按钮坏了。
          Positioned(
            top: 2,
            right: isMinimalSurface ? 2 : 6,
            child: GestureDetector(
              onTap: widget.actionHandler.onHistoryRequested,
              child: _SessionHistoryEmptyHint(
                onTapDismiss: widget.actionHandler.onHistoryRequested,
              ),
            ),
          ),
      ],
    );
  }

  void _handleSendRequested(String text) {
    // 中文注释: 侧栏只负责清理输入框和转发文本，不直接知道控制器如何调度模型与工具。
    // 不在这里静默吞掉空文本——交给控制器的 _sendPrompt 统一给出"请输入创作需求"提示，避免按钮看起来像死的。
    // 只有在"大概率会被接受"时才清空输入（有项目且有可用模型）；否则保留草稿，
    // 让用户看到拒绝提示后能修改重发，而不是整段文本被清掉丢失。
    final likelyAccepted = widget.viewData.hasActiveProject &&
        widget.viewData.modelOptions.isNotEmpty;
    widget.actionHandler.onSendRequested(text);
    if (likelyAccepted) {
      _controller.clear();
    }
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

  // 中文注释: 把"当前是否有子智能体全屏"同步给壳层返回键接管注册表：全屏打开时注册关闭回调，
  // 关闭/无全屏时取消注册。这样 Android 返回键会先关闭全屏，而不是弹"退出应用"。
  void _syncForegroundBackHandler() {
    final activeRun = _detailRouteService.resolveActiveRun(
      _detailRoute.value,
      widget.viewData.subAgentRuns,
    );
    widget.actionHandler.setForegroundBackHandler(
      activeRun == null ? null : _clearActiveSubAgentRun,
    );
  }

  void _clearActiveSubAgentRun() {
    _detailRoute.value = _detailRouteService.clear(_detailRoute.value);
  }

  ConversationInputCapabilityState _inputCapabilities() {
    final resolved = _inputCapabilityService.resolve(
      context: widget.viewData.inputCapabilityContext.copyWith(
        isGenerating: widget.viewData.isGenerating,
        hasActiveProject: widget.viewData.hasActiveProject,
      ),
    );
    // 中文注释: 有项目但未配置可用模型时也置灰发送——否则用户盲发只会撞到一句错误。
    final hasUsableModel = widget.viewData.modelOptions.isNotEmpty;
    // 中文注释: 模式引导阶段若不允许自由文本(只能选选项)，发送也应置灰——
    // 此时 composerHint 会是"这一阶段请先从下面的选项里选一个。"(由 guide 服务固定产出)。
    // 用文案判定避免给大 view-data 模型加字段；phrase 改了最坏只是回到原行为(可发但被拒)。
    final modeGuidanceBlocksFreeText =
        widget.viewData.composerHint.contains('先从下面的选项');
    final blocked = !hasUsableModel || modeGuidanceBlocksFreeText;
    return blocked ? resolved.copyWith(canSendAction: false) : resolved;
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
    required this.collapsedItemIds,
    required this.onItemToggle,
  });

  final WorkbenchConversationViewData viewData;
  final ConversationStatusSummaryViewData statusSummary;
  final bool minimal;
  // 中文注释: 用户已折叠的状态条目 id——让"归档压缩"等带展开箭头的 chip 真能收起/展开，
  // 而不是画了箭头却点击无反应。
  final Set<String> collapsedItemIds;
  final ValueChanged<String> onItemToggle;

  ConversationStatusSummaryViewData get _displaySummary =>
      ConversationStatusSummaryViewData(
        items: statusSummary.items
            .map(
              (item) => ConversationStatusSummaryItemViewData(
                id: item.id,
                kind: item.kind,
                label: item.label,
                summary: item.summary,
                detail: item.detail,
                isHighlighted: item.isHighlighted,
                isInteractive: item.isInteractive,
                isExpanded: item.isExpanded && !collapsedItemIds.contains(item.id),
                isBusy: item.isBusy,
              ),
            )
            .toList(growable: false),
      );

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
              viewData: _displaySummary,
              onItemPressed: onItemToggle,
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
            viewData: _displaySummary,
            onItemPressed: onItemToggle,
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

class _ModelConfigBanner extends StatelessWidget {
  const _ModelConfigBanner({
    required this.onSettingsRequested,
    required this.onDismiss,
  });

  final VoidCallback onSettingsRequested;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    // 中文注释: 提醒先配置写作模型，并提供直达「设置」的入口（此前对话区没有任何设置入口）。
    // 配色沿用 Novel 主题 token(warm)，不脱节到 Material 默认 colorScheme；并允许用户临时关闭。
    final colors = context.novelThemeColors;
    final tint = colors.warmColor;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.tips_and_updates_outlined, size: 16, color: tint),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '尚未配置写作模型，发送前请先到「设置 → 接口/模型」配置。',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.warmStrongColor,
                height: 1.4,
              ),
            ),
          ),
          TextButton(
            onPressed: onSettingsRequested,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('去设置'),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded, size: 16, color: tint),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            tooltip: '暂时关闭',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ModelConfigHint extends StatelessWidget {
  // 中文注释: 大 banner 被用户关掉后留下的紧凑一行提示，就近解释发送按钮为何置灰。
  // 无关闭键：这是用户接受"已知模型未配置"后的稳态提示，避免按钮看起来像坏了。
  const _ModelConfigHint({required this.onSettingsRequested});

  final VoidCallback onSettingsRequested;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    final muted = colors.mutedTextColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 13, color: muted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '未配置写作模型，发送暂不可用。',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: muted,
                height: 1.35,
              ),
            ),
          ),
          TextButton(
            onPressed: onSettingsRequested,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              minimumSize: const Size(0, 26),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text('去设置', style: TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryEmptyHint extends StatelessWidget {
  // 中文注释: 历史开关已打开但没有会话时的占位提示，避免开关高亮却无任何反馈。
  const _SessionHistoryEmptyHint({required this.onTapDismiss});

  final VoidCallback onTapDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = context.novelThemeColors;
    return Material(
      color: colors.panelBackground.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(minWidth: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.lineColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off, size: 14, color: colors.mutedTextColor),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '还没有历史会话。开始一次对话后，这里会出现可切换的会话记录。',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: colors.mutedTextColor,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onTapDismiss,
              child: Icon(Icons.close_rounded, size: 14, color: colors.mutedTextColor),
            ),
          ],
        ),
      ),
    );
  }
}
