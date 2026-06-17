import 'package:flutter/foundation.dart';

import 'conversation_agent_selector_view_data.dart';
import 'conversation_input_capability_context.dart';
import 'conversation_group_selector_view_data.dart';
import 'tool_preview_mode.dart';
import 'conversation_entry_view_data.dart';
import 'conversation_context_projection_view_data.dart';
import 'conversation_opening_state_view_data.dart';
import 'conversation_transcript_lane_view_data.dart';
import 'opening_panel_view_data.dart';
import 'primary_action_view_data.dart';
import 'retry_request_view_data.dart';
import 'selector_option_view_data.dart';
import 'session_history_entry_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'sub_agent_run_view_data.dart';
import 'transcript_block_view_data.dart';
import 'user_option_view_data.dart';

class WorkbenchConversationViewData {
  const WorkbenchConversationViewData({
    required this.hasActiveProject,
    required this.toolCoreStatus,
    this.toolPreviewMode = ToolPreviewMode.compact,
    required this.modelLabel,
    required this.modelOptions,
    required this.groupSelector,
    this.agentSelector = const ConversationAgentSelectorViewData.initial(),
    required this.inputCapabilityContext,
    required this.contextSummary,
    this.conversationContextProjection,
    required this.workflowTitle,
    required this.workflowDescription,
    required this.primaryActions,
    required this.openingPanel,
    this.openingState,
    required this.composerHint,
    required this.conversationEntries,
    required this.transcriptBlocks,
    required this.transcriptLanes,
    required this.pendingOptions,
    required this.subAgentRuns,
    required this.retryRequest,
    required this.sessionHistoryEntries,
    required this.activeSessionId,
    required this.showSessionHistory,
    this.sessionRestoreResult,
    required this.generationStatus,
    required this.isGenerating,
  });

  final bool hasActiveProject;
  final String toolCoreStatus;
  final String toolPreviewMode;
  final String modelLabel;
  final List<SelectorOptionViewData> modelOptions;
  final ConversationGroupSelectorViewData groupSelector;
  final ConversationAgentSelectorViewData agentSelector;
  final ConversationInputCapabilityContext inputCapabilityContext;
  final String contextSummary;
  final ConversationContextProjectionViewData? conversationContextProjection;
  final String workflowTitle;
  final String workflowDescription;
  final List<PrimaryActionViewData> primaryActions;
  final OpeningPanelViewData? openingPanel;
  final ConversationOpeningStateViewData? openingState;
  final String composerHint;
  final List<ConversationEntryViewData> conversationEntries;
  final List<TranscriptBlockViewData> transcriptBlocks;
  final ConversationTranscriptLaneViewData transcriptLanes;
  final List<UserOptionViewData> pendingOptions;
  final List<SubAgentRunViewData> subAgentRuns;
  final RetryRequestViewData? retryRequest;
  final List<SessionHistoryEntryViewData> sessionHistoryEntries;
  final String activeSessionId;
  final bool showSessionHistory;
  final SessionRestoreResult? sessionRestoreResult;
  final String generationStatus;
  final bool isGenerating;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkbenchConversationViewData &&
            other.hasActiveProject == hasActiveProject &&
            other.toolCoreStatus == toolCoreStatus &&
            other.toolPreviewMode == toolPreviewMode &&
            other.modelLabel == modelLabel &&
            listEquals(other.modelOptions, modelOptions) &&
            other.groupSelector == groupSelector &&
            other.agentSelector == agentSelector &&
            other.inputCapabilityContext == inputCapabilityContext &&
            other.contextSummary == contextSummary &&
            other.conversationContextProjection ==
                conversationContextProjection &&
            other.workflowTitle == workflowTitle &&
            other.workflowDescription == workflowDescription &&
            listEquals(other.primaryActions, primaryActions) &&
            other.openingPanel == openingPanel &&
            other.openingState == openingState &&
            other.composerHint == composerHint &&
            listEquals(other.conversationEntries, conversationEntries) &&
            listEquals(other.transcriptBlocks, transcriptBlocks) &&
            other.transcriptLanes == transcriptLanes &&
            listEquals(other.pendingOptions, pendingOptions) &&
            listEquals(other.subAgentRuns, subAgentRuns) &&
            other.retryRequest == retryRequest &&
            listEquals(other.sessionHistoryEntries, sessionHistoryEntries) &&
            other.activeSessionId == activeSessionId &&
            other.showSessionHistory == showSessionHistory &&
            other.sessionRestoreResult == sessionRestoreResult &&
            other.generationStatus == generationStatus &&
            other.isGenerating == isGenerating;
  }

  @override
  int get hashCode => Object.hashAll([
    toolCoreStatus,
    hasActiveProject,
    toolPreviewMode,
    modelLabel,
    Object.hashAll(modelOptions),
    groupSelector,
    agentSelector,
    inputCapabilityContext,
    contextSummary,
    conversationContextProjection,
    workflowTitle,
    workflowDescription,
    Object.hashAll(primaryActions),
    openingPanel,
    openingState,
    composerHint,
    Object.hashAll(conversationEntries),
    Object.hashAll(transcriptBlocks),
    transcriptLanes,
    Object.hashAll(pendingOptions),
    Object.hashAll(subAgentRuns),
    retryRequest,
    Object.hashAll(sessionHistoryEntries),
    activeSessionId,
    showSessionHistory,
    sessionRestoreResult,
    generationStatus,
    isGenerating,
  ]);
}
