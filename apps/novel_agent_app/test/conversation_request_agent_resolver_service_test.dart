import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_member_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_primary_agent_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_request_agent_resolver_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_agent_selector_view_data.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/selector_option_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ConversationRequestAgentResolverService', () {
    const service = ConversationRequestAgentResolverService();

    test('uses selected conversation agent when available', () {
      final result = service.resolve(
        openingProjection: _projection(),
        preferredAgentId: 'reviewer',
        fallbackSelector: const ConversationAgentSelectorViewData.initial(),
      );

      expect(result.agentId, 'reviewer');
      expect(result.agent['name'], '审阅智能体');
    });

    test('falls back to primary agent when selected id is invalid', () {
      final result = service.resolve(
        openingProjection: _projection(),
        preferredAgentId: 'ghost',
        fallbackSelector: const ConversationAgentSelectorViewData(
          currentAgentLabel: '过期智能体',
          currentAgentId: 'ghost',
          currentAgentDescription: '旧选择',
          agentOptions: <SelectorOptionViewData>[],
          canSwitchAgent: false,
        ),
      );

      expect(result.agentId, 'writer');
      expect(result.agent['name'], '正文智能体');
    });
  });
}

OpeningSessionProjection _projection() {
  return OpeningSessionProjection(
    projectTypeId: 'novel',
    currentGroupId: 'starter_novel_writer_room',
    currentGroupDisplayName: '正文协作组',
    groupSummaries: const <OpeningAgentGroupSummary>[
      OpeningAgentGroupSummary(
        groupId: 'starter_novel_writer_room',
        displayName: '正文协作组',
        description: '用于正文推进',
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
          resolvedAgentGroupId: 'starter_novel_writer_room',
          availableAgentGroupIds: <String>['starter_novel_writer_room'],
          sessionGoalModeId: SessionRecordConstants.modeContinueWriting,
        ),
        stageRecords: const <OpeningStageRecord>[],
        createdAt: '2026-05-29T00:00:00.000',
        updatedAt: '2026-05-29T00:00:00.000',
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
    availableAgentSummaries: const <OpeningAgentMemberSummary>[
      OpeningAgentMemberSummary(
        agentId: 'writer',
        displayName: '正文智能体',
        role: '负责正文创作',
        isPrimary: true,
        thinkingSupported: true,
        description: '负责完成正文初稿。',
      ),
      OpeningAgentMemberSummary(
        agentId: 'reviewer',
        displayName: '审阅智能体',
        role: '负责审阅与修订建议',
        isPrimary: false,
        thinkingSupported: true,
        description: '负责找出问题并提出修订意见。',
      ),
    ],
    currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
      agentId: 'writer',
      displayName: '正文智能体',
      role: '负责正文创作',
      thinkingSupported: true,
    ),
  );
}
