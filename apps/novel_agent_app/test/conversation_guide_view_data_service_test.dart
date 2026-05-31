import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_opening_maturity_assessment.dart';
import 'package:novel_agent_app/features/workbench/application/models/project_opening_maturity_stage.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_guide_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test('长任务默认 guide 会优先渲染 opening projection', () {
    final service = ConversationGuideViewDataService();
    final guide = service.build(
      projectType: 'long_novel',
      needsGoalSelection: true,
      isGenerating: false,
      openingMaturity: _openingMaturity(),
      openingProjection: _longTaskProjection(
        const OpeningSuggestedAction(
          id: 'opening.choose_long_task_mode',
          commandId: 'opening.choose_long_task_mode',
          title: '选择长任务模式',
          description: '先确认模式。',
        ),
      ),
    );

    expect(guide.workflowTitle, '长任务开局');
    expect(guide.workflowDescription, contains('当前智能体组：默认长任务开局'));
    expect(guide.primaryActions.single.commandId, 'opening.launch_long_task');
    expect(guide.openingState, isNotNull);
    expect(guide.openingState!.firstPrompt, contains('长任务'));
    expect(guide.openingState!.preferSingleAction, isTrue);
  });

  test('普通项目在已有 opening projection 时会保留原会话入口并补状态摘要', () {
    final service = ConversationGuideViewDataService();
    final guide = service.build(
      projectType: 'novel',
      needsGoalSelection: true,
      isGenerating: false,
      openingMaturity: _openingMaturity(),
      openingProjection: _interactiveProjection(),
    );

    expect(guide.workflowTitle, '这次想让智能体做什么？');
    expect(guide.workflowDescription, contains('当前智能体组：默认小说开局'));
    expect(guide.primaryActions, isNotEmpty);
    expect(guide.openingState, isNotNull);
    expect(guide.openingState!.firstPrompt, '先说一句你现在想让智能体做什么。');
    expect(guide.openingState!.nextStepLabel, guide.primaryActions.first.title);
  });

  test('已有基础的普通项目不会再优先暴露智能开局按钮', () {
    final service = ConversationGuideViewDataService();
    final guide = service.build(
      projectType: 'novel',
      needsGoalSelection: true,
      isGenerating: false,
      openingMaturity: _groundedMaturity(),
      openingProjection: _interactiveProjection(),
    );

    expect(
      guide.primaryActions.any(
        (action) => action.id == 'session.goal.smart_opening',
      ),
      isFalse,
    );
    expect(guide.primaryActions.first.id, 'session.goal.continue_writing');
    expect(guide.workflowDescription, contains('当前项目已经有正文或结构基础'));
    expect(guide.openingState, isNotNull);
    expect(guide.openingState!.hasProjectFoundation, isTrue);
    expect(guide.openingState!.firstPrompt, '直接描述当前要继续推进的内容即可。');
  });

  test('已有基础的长任务项目仍只保留唯一启动动作', () {
    final service = ConversationGuideViewDataService();
    final guide = service.build(
      projectType: 'long_novel',
      needsGoalSelection: true,
      isGenerating: false,
      openingMaturity: _groundedMaturity(),
      openingProjection: _readyLongTaskProjection(),
    );

    expect(guide.workflowTitle, '长篇小说工作台');
    expect(guide.primaryActions, hasLength(1));
    expect(guide.primaryActions.single.commandId, 'opening.launch_long_task');
    expect(guide.primaryActions.single.description, contains('直接启动正式长任务链'));
    expect(guide.openingState, isNotNull);
    expect(guide.openingState!.preferSingleAction, isTrue);
  });
}

ProjectOpeningMaturityAssessment _openingMaturity() {
  return const ProjectOpeningMaturityAssessment(
    stage: ProjectOpeningMaturityStage.openingInProgress,
    summary: '当前项目仍处于开局整理阶段，先补齐少量信息再继续。',
    authoredFoundationFileCount: 0,
    narrativeFileCount: 0,
  );
}

OpeningSessionProjection _readyLongTaskProjection() {
  return OpeningSessionProjection(
    projectTypeId: 'long_novel',
    currentGroupId: 'starter_long_novel_generalist',
    currentGroupDisplayName: '默认长任务开局',
    groupSummaries: const <OpeningAgentGroupSummary>[
      OpeningAgentGroupSummary(
        groupId: 'starter_long_novel_generalist',
        displayName: '默认长任务开局',
        description: '默认长任务开局',
        isSupported: true,
        isDegraded: false,
        isCurrent: true,
        isStarterGroup: true,
      ),
    ],
    orchestration: OpeningOrchestrationResult(
      state: OpeningSessionState(
        projectTypeId: 'long_novel',
        status: OpeningSessionState.statusReadyForLongTask,
        intent: const OpeningIntentSnapshot(
          resolvedAgentGroupId: 'starter_long_novel_generalist',
          availableAgentGroupIds: <String>['starter_long_novel_generalist'],
          runtimeBaselineId: 'continuous_autonomous',
          modeId: 'seed_autopilot_novel',
        ),
        stageRecords: const <OpeningStageRecord>[],
        createdAt: '2026-05-27T00:00:00.000',
        updatedAt: '2026-05-27T00:00:00.000',
      ),
      readiness: const OpeningReadinessAssessment(
        canStartLongTask: true,
        canStartInteractiveSession: false,
        missingRequirements: <OpeningMissingRequirement>[],
        effectiveRuntimeBaselineId: 'continuous_autonomous',
        effectiveModeId: 'seed_autopilot_novel',
      ),
      suggestedActions: const <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.start_long_task_run',
          commandId: 'opening.start_long_task_run',
          title: '启动长任务',
          description: '当前已可启动。',
        ),
      ],
    ),
  );
}

ProjectOpeningMaturityAssessment _groundedMaturity() {
  return const ProjectOpeningMaturityAssessment(
    stage: ProjectOpeningMaturityStage.continueReady,
    summary: '当前项目已经有正文或结构基础，可直接继续创作。',
    authoredFoundationFileCount: 3,
    narrativeFileCount: 1,
  );
}

OpeningSessionProjection _longTaskProjection(OpeningSuggestedAction action) {
  return OpeningSessionProjection(
    projectTypeId: 'long_novel',
    currentGroupId: 'starter_long_novel_generalist',
    currentGroupDisplayName: '默认长任务开局',
    groupSummaries: const <OpeningAgentGroupSummary>[
      OpeningAgentGroupSummary(
        groupId: 'starter_long_novel_generalist',
        displayName: '默认长任务开局',
        description: '默认长任务开局',
        isSupported: true,
        isDegraded: false,
        isCurrent: true,
        isStarterGroup: true,
      ),
    ],
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
        createdAt: '2026-05-27T00:00:00.000',
        updatedAt: '2026-05-27T00:00:00.000',
      ),
      readiness: const OpeningReadinessAssessment(
        canStartLongTask: false,
        canStartInteractiveSession: false,
        missingRequirements: <OpeningMissingRequirement>[
          OpeningMissingRequirement(
            id: 'mode_selection',
            title: '缺少长任务模式',
            description: '请先选择模式。',
          ),
        ],
        effectiveRuntimeBaselineId: 'continuous_autonomous',
      ),
      suggestedActions: <OpeningSuggestedAction>[action],
    ),
  );
}

OpeningSessionProjection _interactiveProjection() {
  return OpeningSessionProjection(
    projectTypeId: 'novel',
    currentGroupId: 'starter_novel_generalist',
    currentGroupDisplayName: '默认小说开局',
    groupSummaries: const <OpeningAgentGroupSummary>[
      OpeningAgentGroupSummary(
        groupId: 'starter_novel_generalist',
        displayName: '默认小说开局',
        description: '默认小说开局',
        isSupported: true,
        isDegraded: false,
        isCurrent: true,
        isStarterGroup: true,
      ),
    ],
    orchestration: OpeningOrchestrationResult(
      state: OpeningSessionState(
        projectTypeId: 'novel',
        status: OpeningSessionState.statusReadyForInteractiveSession,
        intent: const OpeningIntentSnapshot(
          resolvedAgentGroupId: 'starter_novel_generalist',
          availableAgentGroupIds: <String>['starter_novel_generalist'],
          sessionGoalModeId: SessionRecordConstants.modeSmartOpening,
        ),
        stageRecords: const <OpeningStageRecord>[],
        createdAt: '2026-05-27T00:00:00.000',
        updatedAt: '2026-05-27T00:00:00.000',
      ),
      readiness: const OpeningReadinessAssessment(
        canStartLongTask: false,
        canStartInteractiveSession: true,
        missingRequirements: <OpeningMissingRequirement>[],
      ),
      suggestedActions: const <OpeningSuggestedAction>[
        OpeningSuggestedAction(
          id: 'opening.start_interactive_session',
          commandId: 'opening.start_interactive_session',
          title: '开始会话',
          description: '直接开始。',
        ),
      ],
    ),
  );
}
