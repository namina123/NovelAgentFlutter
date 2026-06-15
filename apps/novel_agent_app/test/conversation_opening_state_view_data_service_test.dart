import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_opening_maturity_assessment.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_opening_maturity_stage.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_opening_state_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/primary_action_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'continue-ready grounded state suppresses stale opening missing requirements',
    () {
      final service = ConversationOpeningStateViewDataService();
      final state = service.build(
        projectType: 'long_novel',
        maturity: const ProjectOpeningMaturityAssessment(
          stage: ProjectOpeningMaturityStage.continueReady,
          summary: '当前项目已经有可继续推进的长篇基础。',
          authoredFoundationFileCount: 3,
          narrativeFileCount: 1,
        ),
        primaryActions: const <PrimaryActionViewData>[
          PrimaryActionViewData(
            id: 'opening.launch_long_task',
            title: '启动长任务',
            description: '继续或恢复正式长任务链。',
            commandId: 'opening.launch_long_task',
          ),
        ],
        projection: _projectionWithStaleMissingSeed(),
        preferredNextAction: const PrimaryActionViewData(
          id: 'opening.launch_long_task',
          title: '启动长任务',
          description: '继续或恢复正式长任务链。',
          commandId: 'opening.launch_long_task',
        ),
        firstPromptOverride: '直接描述当前要继续推进的章节、场景或设定即可。',
        nextStepLabelOverride: '启动长任务',
        preferSingleAction: true,
      );

      expect(state.hasProjectFoundation, isTrue);
      expect(state.missingRequirementTitles, isEmpty);
      expect(state.nextStepLabel, '启动长任务');
      expect(state.preferSingleAction, isTrue);
    },
  );

  test(
    'opening-in-progress state still surfaces unresolved missing requirements',
    () {
      final service = ConversationOpeningStateViewDataService();
      final state = service.build(
        projectType: 'long_novel',
        maturity: const ProjectOpeningMaturityAssessment(
          stage: ProjectOpeningMaturityStage.openingInProgress,
          summary: '当前仍需补充少量开局信息。',
          authoredFoundationFileCount: 2,
          narrativeFileCount: 1,
        ),
        primaryActions: const <PrimaryActionViewData>[
          PrimaryActionViewData(
            id: 'opening.launch_long_task',
            title: '启动长任务',
            description: '继续补齐开局缺口。',
            commandId: 'opening.launch_long_task',
          ),
        ],
        projection: _projectionWithStaleMissingSeed(),
      );

      expect(state.hasProjectFoundation, isTrue);
      expect(state.missingRequirementTitles, ['灵感种子']);
      expect(state.firstPrompt, '先用少量选项把这部长篇的开局信息收束清楚。');
      expect(state.nextStepLabel, '按步骤补齐关键信息');
    },
  );
}

OpeningSessionProjection _projectionWithStaleMissingSeed() {
  return OpeningSessionProjection(
    projectTypeId: 'long_novel',
    currentGroupId: 'starter_long_novel_generalist',
    currentGroupDisplayName: '默认长任务灵感开局',
    groupSummaries: const <OpeningAgentGroupSummary>[],
    orchestration: OpeningOrchestrationResult(
      state: OpeningSessionState(
        projectTypeId: 'long_novel',
        status: OpeningSessionState.statusCollecting,
        intent: const OpeningIntentSnapshot(
          resolvedAgentGroupId: 'starter_long_novel_generalist',
          availableAgentGroupIds: <String>['starter_long_novel_generalist'],
          runtimeBaselineId: 'continuous_autonomous',
        ),
        stageRecords: const <OpeningStageRecord>[],
        createdAt: '2026-06-13T00:00:00.000',
        updatedAt: '2026-06-13T00:00:00.000',
      ),
      readiness: const OpeningReadinessAssessment(
        canStartLongTask: false,
        canStartInteractiveSession: false,
        missingRequirements: <OpeningMissingRequirement>[
          OpeningMissingRequirement(
            id: 'seed',
            title: '灵感种子',
            description: '请补一条灵感种子。',
          ),
        ],
        effectiveRuntimeBaselineId: 'continuous_autonomous',
      ),
      suggestedActions: const <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.launch_long_task',
          commandId: 'opening.launch_long_task',
          title: '启动长任务',
          description: '继续补齐开局缺口。',
        ),
      ],
    ),
  );
}
