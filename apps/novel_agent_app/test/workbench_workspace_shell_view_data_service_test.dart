import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/services/workbench_workspace_shell_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_agent_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_group_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_input_capability_context.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_transcript_lane_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/project_long_task_summary_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_canvas_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_conversation_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/workbench_resource_view_data.dart';

void main() {
  const service = WorkbenchWorkspaceShellViewDataService();

  test(
    'keeps project group summary sourced from project-level group selector',
    () {
      final viewData = service.build(
        resource: const WorkbenchResourceViewData(
          projectName: '星港档案',
          projectSubtitle: '长篇科幻项目',
          resourceEntries: [],
          projectLongTaskSummary: ProjectLongTaskSummaryViewData(
            title: '长任务运行',
            summary: '运行中 1 · 待处理 1 · 共 2 条',
            isLoading: false,
            totalCount: 2,
            activeCount: 1,
            attentionCount: 1,
            runs: <ProjectLongTaskRunSummaryViewData>[
              ProjectLongTaskRunSummaryViewData(
                id: 'run_1',
                title: '连续不断的长任务',
                subtitle: '按大纲自动推进',
                statusLabel: '等待人工处理',
                taskLabel: '第 10 章返工',
                recentActivityLabel: '5 分钟前',
                requiresAttention: true,
                isActive: false,
                diagnosisLabel: '需要人工处理',
              ),
            ],
          ),
        ),
        canvas: const WorkbenchCanvasViewData(
          documents: [],
          activeDocumentTitle: '',
          activeDocumentPath: '',
          activeDocumentBody: '',
          activeDocumentDirty: false,
          activeDocumentCanRender: false,
          isActiveDocumentRendered: false,
          isDocumentsWorkspaceVisible: false,
          generationStatus: '',
        ),
        conversation: const WorkbenchConversationViewData(
          hasActiveProject: true,
          toolCoreStatus: '',
          modelLabel: 'GPT-4.1',
          modelOptions: <SelectorOptionViewData>[],
          groupSelector: ConversationGroupSelectorViewData(
            currentGroupLabel: '长篇总控组',
            groupOptions: <SelectorOptionViewData>[],
            primaryAgentLabel: '综合创作智能体',
            primaryAgentDescription: '负责统筹当前长篇协作。',
            canSwitchGroup: true,
          ),
          agentSelector: ConversationAgentSelectorViewData(
            currentAgentLabel: '审阅智能体',
            currentAgentId: 'reviewer',
            currentAgentDescription: '负责当前会话的审阅与修订建议',
            agentOptions: <SelectorOptionViewData>[],
            canSwitchAgent: true,
          ),
          inputCapabilityContext: ConversationInputCapabilityContext.initial(),
          contextSummary: '当前会话摘要',
          workflowTitle: '继续创作',
          workflowDescription: '围绕当前会话推进正文。',
          primaryActions: [],
          openingPanel: null,
          composerHint: '输入需求',
          conversationEntries: [],
          transcriptBlocks: [],
          transcriptLanes: ConversationTranscriptLaneViewData(
            stableHistoryBlocks: [],
            currentRoundToolBlocks: [],
            streamingAppendixBlocks: [],
            footerBlocks: [],
          ),
          pendingOptions: [],
          subAgentRuns: [],
          retryRequest: null,
          sessionHistoryEntries: [],
          activeSessionId: 'session-1',
          showSessionHistory: false,
          generationStatus: '',
          isGenerating: false,
        ),
      );

      expect(viewData.agentGroupLabel, '长篇总控组');
      expect(viewData.primaryAgentLabel, '综合创作智能体');
      expect(viewData.projectAgentGroupPanel.currentGroupLabel, '长篇总控组');
      expect(viewData.projectAgentGroupPanel.primaryAgentLabel, '综合创作智能体');
      expect(
        viewData.projectAgentGroupPanel.actionDescription,
        '查看当前项目协作摘要，并按需调整默认协作组。',
      );
      expect(viewData.projectLongTaskSummary, isNotNull);
      expect(viewData.projectLongTaskSummary!.runs.single.diagnosisLabel, '需要人工处理');
    },
  );
}
