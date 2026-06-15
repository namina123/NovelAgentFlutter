import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('OpeningOrchestrationService', () {
    final service = OpeningOrchestrationService();

    test('keeps long task opening collecting until mode guidance is ready', () {
      final project = const ProjectDescriptor(
        id: 'project_1',
        name: '长篇项目',
        rootPath: 'D:/demo',
        projectType: 'long_novel',
        runtimeBaselineId: 'continuous_autonomous',
      );
      final modeGuidanceState = ModeGuidanceTransitionService().answer(
        ModeGuidanceTransitionService().initialize('seed_autopilot_novel'),
        stageId: 'seed_scope',
        fieldKey: 'seed_scope',
        value: '只有一句灵感。',
        label: '一句灵感',
        source: 'option',
      );

      final result = service.orchestrate(
        project: project,
        intent: const OpeningIntentSnapshot(
          availableAgentGroupIds: <String>[
            'starter_long_novel_seed_generalist',
          ],
          modeId: 'seed_autopilot_novel',
        ),
        modeGuidanceState: modeGuidanceState,
        now: '2026-05-27T10:00:00.000Z',
      );

      expect(result.state.status, OpeningSessionState.statusCollecting);
      expect(result.readiness.canStartLongTask, isFalse);
      expect(
        result.readiness.missingRequirements.any(
          (item) => item.id.startsWith('mode_guidance.'),
        ),
        isTrue,
      );
      expect(result.suggestedActions, hasLength(1));
      expect(
        result.suggestedActions.single.commandId,
        'opening.continue_mode_guidance',
      );
      expect(
        result.state.intent.resolvedAgentGroupId,
        'starter_long_novel_seed_generalist',
      );
    });

    test(
      'marks long task opening ready when group baseline and guidance exist',
      () {
        final transitionService = ModeGuidanceTransitionService();
        var state = transitionService.initialize('seed_autopilot_novel');
        for (final item in const <Map<String, String>>[
          <String, String>{
            'stage_id': 'seed_scope',
            'field_key': 'seed_scope',
            'value': '只有一句灵感。',
          },
          <String, String>{
            'stage_id': 'core_promise',
            'field_key': 'core_promise',
            'value': '持续升级与翻盘。',
          },
          <String, String>{
            'stage_id': 'world_anchor',
            'field_key': 'world_anchor',
            'value': '世界存在稳定修炼秩序。',
          },
          <String, String>{
            'stage_id': 'protagonist_drive',
            'field_key': 'protagonist_drive',
            'value': '主角以复仇翻盘为目标。',
          },
          <String, String>{
            'stage_id': 'style_target',
            'field_key': 'style_target',
            'value': '商业网文，节奏快。',
          },
          <String, String>{
            'stage_id': 'autonomy_guardrails',
            'field_key': 'autonomy_guardrails',
            'value': '跨卷前确认，其他默认托管。',
          },
          <String, String>{
            'stage_id': 'review_ready',
            'field_key': 'review_ready',
            'value': '已确认开始托管。',
          },
        ]) {
          state = transitionService.answer(
            state,
            stageId: item['stage_id']!,
            fieldKey: item['field_key']!,
            value: item['value']!,
          );
        }
        final result = service.orchestrate(
          project: const ProjectDescriptor(
            id: 'project_1',
            name: '长篇项目',
            rootPath: 'D:/demo',
            projectType: 'long_novel',
            runtimeBaselineId: 'continuous_autonomous',
          ),
          intent: const OpeningIntentSnapshot(
            resolvedAgentGroupId: 'starter_long_novel_seed_generalist',
            availableAgentGroupIds: <String>[
              'starter_long_novel_seed_generalist',
            ],
            modeId: 'seed_autopilot_novel',
          ),
          modeGuidanceState: state,
        );

        expect(result.state.status, OpeningSessionState.statusReadyForLongTask);
        expect(result.readiness.canStartLongTask, isTrue);
        expect(result.readiness.missingRequirements, isEmpty);
        expect(result.suggestedActions, hasLength(1));
        expect(
          result.suggestedActions.single.commandId,
          'opening.start_long_task_run',
        );
        expect(
          result.state.stageRecords.last.status,
          OpeningStageRecord.statusReady,
        );
      },
    );

    test('marks normal novel opening ready when goal and group exist', () {
      final result = service.orchestrate(
        project: const ProjectDescriptor(
          id: 'project_2',
          name: '普通小说项目',
          rootPath: 'D:/demo',
          projectType: 'novel',
        ),
        intent: const OpeningIntentSnapshot(
          resolvedAgentGroupId: 'starter_novel_generalist',
          availableAgentGroupIds: <String>['starter_novel_generalist'],
          sessionGoalModeId: SessionRecordConstants.modeChapterDraft,
        ),
      );

      expect(
        result.state.status,
        OpeningSessionState.statusReadyForInteractiveSession,
      );
      expect(result.readiness.canStartInteractiveSession, isTrue);
      expect(result.readiness.missingRequirements, isEmpty);
      expect(
        result.suggestedActions.single.commandId,
        'opening.start_interactive_session',
      );
      final contract = ValueReaders.mapValue(
        result.state.metadata['fact_acquisition_contract'],
      );
      expect(
        ValueReaders.stringValue(contract['workflow_id']),
        'interactive_opening',
      );
    });

    test(
      'asks normal novel opening for goal when neither goal nor free text exists',
      () {
        final result = service.orchestrate(
          project: const ProjectDescriptor(
            id: 'project_2',
            name: '普通小说项目',
            rootPath: 'D:/demo',
            projectType: 'novel',
          ),
          intent: const OpeningIntentSnapshot(
            resolvedAgentGroupId: 'starter_novel_generalist',
            availableAgentGroupIds: <String>['starter_novel_generalist'],
          ),
        );

        expect(result.state.status, OpeningSessionState.statusCollecting);
        expect(result.readiness.canStartInteractiveSession, isFalse);
        expect(result.readiness.missingRequirements, hasLength(1));
        expect(
          result.readiness.missingRequirements.single.id,
          'conversation_goal',
        );
        expect(result.suggestedActions, hasLength(2));
        expect(
          result.suggestedActions.first.commandId,
          'opening.choose_session_goal',
        );
        final contract = ValueReaders.mapValue(
          result.state.metadata['fact_acquisition_contract'],
        );
        expect(
          ValueReaders.stringValue(contract['workflow_id']),
          'interactive_opening',
        );
        expect(ValueReaders.mapList(contract['lanes']), hasLength(3));
      },
    );

    test('stores long task fact acquisition contract in opening metadata', () {
      final result = service.orchestrate(
        project: const ProjectDescriptor(
          id: 'project_3',
          name: '长篇项目',
          rootPath: 'D:/demo',
          projectType: 'long_novel',
          runtimeBaselineId: 'continuous_autonomous',
        ),
        intent: const OpeningIntentSnapshot(
          resolvedAgentGroupId: 'starter_long_novel_seed_generalist',
          availableAgentGroupIds: <String>[
            'starter_long_novel_seed_generalist',
          ],
          modeId: 'seed_autopilot_novel',
        ),
      );

      final contract = ValueReaders.mapValue(
        result.state.metadata['fact_acquisition_contract'],
      );
      expect(
        ValueReaders.stringValue(contract['workflow_id']),
        'long_task_opening',
      );
      expect(
        ValueReaders.stringValue(contract['project_type_id']),
        'long_novel',
      );
    });
  });
}
