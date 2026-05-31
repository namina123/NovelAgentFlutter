import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/services/long_task_start_action_policy_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  const service = LongTaskStartActionPolicyService();

  test('普通项目不会暴露长任务唯一启动动作', () {
    final action = service.build(projectType: 'novel', openingProjection: null);

    expect(action, isNull);
  });

  test('未就绪的长任务项目会给出统一启动动作并说明缺口', () {
    final action = service.build(
      projectType: 'long_novel',
      openingProjection: _projection(
        const OpeningReadinessAssessment(
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
        const OpeningSuggestedAction(
          id: 'opening.choose_long_task_mode',
          commandId: 'opening.choose_long_task_mode',
          title: '选择长任务模式',
          description: '请先选模式。',
        ),
      ),
    );

    expect(action, isNotNull);
    expect(action!.commandId, 'opening.launch_long_task');
    expect(action.title, '启动长任务');
    expect(action.description, contains('缺少长任务模式'));
  });

  test('已就绪的长任务项目会给出统一启动动作并允许直启', () {
    final action = service.build(
      projectType: 'long_novel',
      openingProjection: _projection(
        const OpeningReadinessAssessment(
          canStartLongTask: true,
          canStartInteractiveSession: false,
          missingRequirements: <OpeningMissingRequirement>[],
          effectiveRuntimeBaselineId: 'continuous_autonomous',
          effectiveModeId: 'seed_autopilot_novel',
        ),
        const OpeningSuggestedAction(
          id: 'opening.start_long_task_run',
          commandId: 'opening.start_long_task_run',
          title: '启动长任务',
          description: '已可启动。',
        ),
      ),
    );

    expect(action, isNotNull);
    expect(action!.commandId, 'opening.launch_long_task');
    expect(action.description, contains('直接启动正式长任务链'));
  });
}

OpeningSessionProjection _projection(
  OpeningReadinessAssessment readiness,
  OpeningSuggestedAction action,
) {
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
        createdAt: '2026-05-29T00:00:00.000',
        updatedAt: '2026-05-29T00:00:00.000',
      ),
      readiness: readiness,
      suggestedActions: <OpeningSuggestedAction>[action],
    ),
  );
}
