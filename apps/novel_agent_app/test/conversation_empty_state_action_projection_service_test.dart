import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_group_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_input_capability_context.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_opening_state_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/opening_panel_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/primary_action_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_transcript_lane_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_conversation_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/services/conversation_empty_state_action_projection_service.dart';

void main() {
  const service = ConversationEmptyStateActionProjectionService();

  test('empty state hides menu actions when no active project is open', () {
    final viewData = WorkbenchConversationViewData(
      hasActiveProject: false,
      toolCoreStatus: '',
      modelLabel: '模型',
      modelOptions: const [],
      groupSelector: const ConversationGroupSelectorViewData(
        currentGroupLabel: '默认组',
        groupOptions: [],
        primaryAgentLabel: '智能体',
        primaryAgentDescription: '',
        canSwitchGroup: false,
      ),
      inputCapabilityContext:
          const ConversationInputCapabilityContext.initial(),
      contextSummary: '',
      workflowTitle: '开始会话',
      workflowDescription: '先打开项目。',
      primaryActions: const [
        PrimaryActionViewData(
          id: 'refresh_project',
          title: '刷新项目',
          description: '刷新默认项目。',
          commandId: 'refresh_project',
        ),
      ],
      openingPanel: null,
      openingState: null,
      composerHint: '输入需求。',
      conversationEntries: const [],
      transcriptBlocks: const [],
      transcriptLanes: const ConversationTranscriptLaneViewData(
        stableHistoryBlocks: [],
        currentRoundToolBlocks: [],
        streamingAppendixBlocks: [],
        footerBlocks: [],
      ),
      pendingOptions: const [],
      subAgentRuns: const [],
      retryRequest: null,
      sessionHistoryEntries: const [],
      activeSessionId: '',
      showSessionHistory: false,
      generationStatus: '',
      isGenerating: false,
    );

    expect(service.visibleActions(viewData), isEmpty);
  });

  test(
    'empty state keeps only the first natural next action for normal flows',
    () {
      final viewData = WorkbenchConversationViewData(
        hasActiveProject: true,
        toolCoreStatus: '',
        modelLabel: '模型',
        modelOptions: const [],
        groupSelector: const ConversationGroupSelectorViewData(
          currentGroupLabel: '默认组',
          groupOptions: [],
          primaryAgentLabel: '智能体',
          primaryAgentDescription: '',
          canSwitchGroup: false,
        ),
        inputCapabilityContext:
            const ConversationInputCapabilityContext.initial(),
        contextSummary: '',
        workflowTitle: '小说工作台',
        workflowDescription: '继续创作。',
        primaryActions: const [
          PrimaryActionViewData(
            id: 'session.goal.smart_opening',
            title: '智能开局',
            description: '第一步。',
            commandId: 'session.goal',
          ),
          PrimaryActionViewData(
            id: 'session.goal.chapter_draft',
            title: '创作章节',
            description: '第二步。',
            commandId: 'session.goal',
          ),
        ],
        openingPanel: null,
        openingState: const ConversationOpeningStateViewData(
          firstPrompt: '先说一句你现在想让智能体做什么。',
          nextStepLabel: '智能开局',
          hasProjectFoundation: false,
          hasResolvedGroup: true,
          missingRequirementTitles: [],
          preferSingleAction: true,
          nextAction: PrimaryActionViewData(
            id: 'session.goal.smart_opening',
            title: '智能开局',
            description: '第一步。',
            commandId: 'session.goal',
          ),
        ),
        composerHint: '输入需求。',
        conversationEntries: const [],
        transcriptBlocks: const [],
        transcriptLanes: const ConversationTranscriptLaneViewData(
          stableHistoryBlocks: [],
          currentRoundToolBlocks: [],
          streamingAppendixBlocks: [],
          footerBlocks: [],
        ),
        pendingOptions: const [],
        subAgentRuns: const [],
        retryRequest: null,
        sessionHistoryEntries: const [],
        activeSessionId: '',
        showSessionHistory: false,
        generationStatus: '',
        isGenerating: false,
      );

      final actions = service.visibleActions(viewData);

      expect(actions, hasLength(1));
      expect(actions.single.title, '智能开局');
    },
  );

  test(
    'empty state hides menu actions when opening state has no next action',
    () {
      final viewData = WorkbenchConversationViewData(
        hasActiveProject: true,
        toolCoreStatus: '',
        modelLabel: '模型',
        modelOptions: const [],
        groupSelector: const ConversationGroupSelectorViewData(
          currentGroupLabel: '默认组',
          groupOptions: [],
          primaryAgentLabel: '智能体',
          primaryAgentDescription: '',
          canSwitchGroup: false,
        ),
        inputCapabilityContext:
            const ConversationInputCapabilityContext.initial(),
        contextSummary: '',
        workflowTitle: '长任务开局',
        workflowDescription: '继续确认。',
        primaryActions: const [
          PrimaryActionViewData(
            id: 'guide.answer.one',
            title: '选项一',
            description: '说明一。',
            commandId: 'guide.answer_mode_guidance',
          ),
          PrimaryActionViewData(
            id: 'guide.answer.two',
            title: '选项二',
            description: '说明二。',
            commandId: 'guide.answer_mode_guidance',
          ),
        ],
        openingPanel: const OpeningPanelViewData(
          title: '项目智能体组',
          summary: '需要选择。',
          currentGroupDisplayName: '默认组',
          selectionHint: '只显示支持项。',
          supportedGroups: [],
          unsupportedGroups: [],
        ),
        openingState: const ConversationOpeningStateViewData(
          firstPrompt: '先确认一个适用于当前项目的智能体组。',
          nextStepLabel: '确认项目智能体组',
          hasProjectFoundation: false,
          hasResolvedGroup: false,
          missingRequirementTitles: ['缺少智能体组'],
          preferSingleAction: false,
        ),
        composerHint: '输入需求。',
        conversationEntries: const [],
        transcriptBlocks: const [],
        transcriptLanes: const ConversationTranscriptLaneViewData(
          stableHistoryBlocks: [],
          currentRoundToolBlocks: [],
          streamingAppendixBlocks: [],
          footerBlocks: [],
        ),
        pendingOptions: const [],
        subAgentRuns: const [],
        retryRequest: null,
        sessionHistoryEntries: const [],
        activeSessionId: '',
        showSessionHistory: false,
        generationStatus: '',
        isGenerating: false,
      );

      expect(service.visibleActions(viewData), isEmpty);
    },
  );

  test('empty state keeps full guided actions only without opening state', () {
    final viewData = WorkbenchConversationViewData(
      hasActiveProject: true,
      toolCoreStatus: '',
      modelLabel: '模型',
      modelOptions: const [],
      groupSelector: const ConversationGroupSelectorViewData(
        currentGroupLabel: '默认组',
        groupOptions: [],
        primaryAgentLabel: '智能体',
        primaryAgentDescription: '',
        canSwitchGroup: false,
      ),
      inputCapabilityContext:
          const ConversationInputCapabilityContext.initial(),
      contextSummary: '',
      workflowTitle: '长任务开局',
      workflowDescription: '继续确认。',
      primaryActions: const [
        PrimaryActionViewData(
          id: 'guide.answer.one',
          title: '选项一',
          description: '说明一。',
          commandId: 'guide.answer_mode_guidance',
        ),
        PrimaryActionViewData(
          id: 'guide.answer.two',
          title: '选项二',
          description: '说明二。',
          commandId: 'guide.answer_mode_guidance',
        ),
      ],
      openingPanel: const OpeningPanelViewData(
        title: '项目智能体组',
        summary: '需要选择。',
        currentGroupDisplayName: '默认组',
        selectionHint: '只显示支持项。',
        supportedGroups: [],
        unsupportedGroups: [],
      ),
      openingState: null,
      composerHint: '输入需求。',
      conversationEntries: const [],
      transcriptBlocks: const [],
      transcriptLanes: const ConversationTranscriptLaneViewData(
        stableHistoryBlocks: [],
        currentRoundToolBlocks: [],
        streamingAppendixBlocks: [],
        footerBlocks: [],
      ),
      pendingOptions: const [],
      subAgentRuns: const [],
      retryRequest: null,
      sessionHistoryEntries: const [],
      activeSessionId: '',
      showSessionHistory: false,
      generationStatus: '',
      isGenerating: false,
    );

    expect(service.visibleActions(viewData), hasLength(2));
  });
}
