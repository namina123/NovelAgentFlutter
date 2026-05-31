import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_primary_agent_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_group_selector_view_data_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  const service = ConversationGroupSelectorViewDataService();

  test('build projects group-first selector and primary agent summary', () {
    final viewData = service.build(
      openingProjection: OpeningSessionProjection(
        projectTypeId: 'novel',
        currentGroupId: 'starter_novel_generalist',
        currentGroupDisplayName: '默认小说开局',
        groupSummaries: const [
          OpeningAgentGroupSummary(
            groupId: 'starter_novel_generalist',
            displayName: '默认小说开局',
            description: '适合普通小说项目。',
            isSupported: true,
            isDegraded: false,
            isCurrent: true,
            isStarterGroup: true,
          ),
        ],
        orchestration: OpeningOrchestrationResult(
          state: const OpeningSessionState(
            projectTypeId: 'novel',
            status: OpeningSessionState.statusReadyForInteractiveSession,
            intent: OpeningIntentSnapshot(
              resolvedAgentGroupId: 'starter_novel_generalist',
              availableAgentGroupIds: ['starter_novel_generalist'],
            ),
            stageRecords: [],
            createdAt: '2026-05-28T00:00:00Z',
            updatedAt: '2026-05-28T00:00:00Z',
          ),
          readiness: const OpeningReadinessAssessment(
            canStartLongTask: false,
            canStartInteractiveSession: true,
            missingRequirements: [],
          ),
          suggestedActions: const [],
        ),
        currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
          agentId: 'default_generalist',
          displayName: '综合创作智能体',
          role: '负责统筹当前小说协作。',
          thinkingSupported: true,
        ),
      ),
      fallbackPrimaryAgentLabel: '后备智能体',
    );

    expect(viewData.currentGroupLabel, '默认小说开局');
    expect(viewData.headerSubtitle, '默认小说开局');
    expect(viewData.primaryAgentLabel, '综合创作智能体');
    expect(viewData.primaryAgentDescription, '负责统筹当前小说协作。');
    expect(viewData.groupOptions, hasLength(1));
    expect(viewData.groupOptions.single.label, '默认小说开局');
    expect(viewData.canSwitchGroup, isTrue);
  });

  test('build falls back when no opening projection is available', () {
    final viewData = service.build(
      openingProjection: null,
      fallbackPrimaryAgentLabel: '后备智能体',
    );

    expect(viewData.currentGroupLabel, '未确定智能体组');
    expect(viewData.headerSubtitle, isNull);
    expect(viewData.primaryAgentLabel, '后备智能体');
    expect(viewData.groupOptions, isEmpty);
    expect(viewData.canSwitchGroup, isFalse);
  });

  test('build never falls back to internal agent id copy', () {
    final viewData = service.build(
      openingProjection: OpeningSessionProjection(
        projectTypeId: 'novel',
        currentGroupId: 'starter_novel_generalist',
        currentGroupDisplayName: '默认小说开局',
        groupSummaries: const [],
        orchestration: OpeningOrchestrationResult(
          state: const OpeningSessionState(
            projectTypeId: 'novel',
            status: OpeningSessionState.statusReadyForInteractiveSession,
            intent: OpeningIntentSnapshot(
              resolvedAgentGroupId: 'starter_novel_generalist',
              availableAgentGroupIds: ['starter_novel_generalist'],
            ),
            stageRecords: [],
            createdAt: '2026-05-28T00:00:00Z',
            updatedAt: '2026-05-28T00:00:00Z',
          ),
          readiness: const OpeningReadinessAssessment(
            canStartLongTask: false,
            canStartInteractiveSession: true,
            missingRequirements: [],
          ),
          suggestedActions: const [],
        ),
        currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
          agentId: 'default_generalist',
          displayName: '',
          role: '',
          thinkingSupported: true,
        ),
      ),
      fallbackPrimaryAgentLabel: 'default_generalist',
    );

    expect(viewData.primaryAgentLabel, '综合创作智能体');
    expect(viewData.primaryAgentDescription, isEmpty);
  });
}
