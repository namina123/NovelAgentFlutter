import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_group_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_agent_member_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_primary_agent_summary.dart';
import 'package:novel_agent_app/features/workbench/application/models/opening_session_projection.dart';
import 'package:novel_agent_app/features/workbench/application/services/conversation_agent_selector_view_data_service.dart';
import 'package:novel_agent_app/features/workbench/presentation/models/conversation_agent_selector_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  const service = ConversationAgentSelectorViewDataService();

  test('build prefers the requested current agent when it still exists', () {
    final viewData = service.build(
      openingProjection: _projection(
        availableAgentSummaries: const <OpeningAgentMemberSummary>[
          OpeningAgentMemberSummary(
            agentId: 'writer',
            displayName: '作者智能体',
            role: '正文创作',
            isPrimary: true,
            thinkingSupported: true,
            description: '负责正文撰写',
          ),
          OpeningAgentMemberSummary(
            agentId: 'reviewer',
            displayName: '审阅智能体',
            role: '质量审阅',
            isPrimary: false,
            thinkingSupported: false,
            description: '负责审阅和校对',
          ),
        ],
        currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
          agentId: 'writer',
          displayName: '作者智能体',
          role: '正文创作',
          thinkingSupported: true,
        ),
      ),
      preferredAgentId: 'reviewer',
      fallback: const ConversationAgentSelectorViewData.initial(),
    );

    expect(viewData.currentAgentId, 'reviewer');
    expect(viewData.currentAgentLabel, '审阅智能体');
    expect(viewData.currentAgentDescription, '质量审阅');
    expect(viewData.headerSubtitle, '质量审阅');
    expect(viewData.agentOptions, hasLength(2));
    expect(viewData.canSwitchAgent, isTrue);
  });

  test(
    'build falls back to primary member when preferred agent is missing',
    () {
      final viewData = service.build(
        openingProjection: _projection(
          availableAgentSummaries: const <OpeningAgentMemberSummary>[
            OpeningAgentMemberSummary(
              agentId: 'writer',
              displayName: '作者智能体',
              role: '正文创作',
              isPrimary: true,
              thinkingSupported: true,
            ),
            OpeningAgentMemberSummary(
              agentId: 'reviewer',
              displayName: '审阅智能体',
              role: '质量审阅',
              isPrimary: false,
              thinkingSupported: false,
            ),
          ],
          currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
            agentId: 'writer',
            displayName: '作者智能体',
            role: '正文创作',
            thinkingSupported: true,
          ),
        ),
        preferredAgentId: 'planner',
        fallback: const ConversationAgentSelectorViewData.initial(),
      );

      expect(viewData.currentAgentId, 'writer');
      expect(viewData.currentAgentLabel, '作者智能体');
      expect(viewData.currentAgentDescription, '正文创作');
    },
  );

  test('build keeps stable fallback copy when projection is unavailable', () {
    final viewData = service.build(
      openingProjection: null,
      preferredAgentId: '',
      fallback: const ConversationAgentSelectorViewData(
        currentAgentLabel: '后备智能体',
        currentAgentId: 'fallback-agent',
        currentAgentDescription: '后备描述',
        agentOptions: [],
        canSwitchAgent: false,
        headerSubtitle: '后备副标题',
      ),
    );

    expect(viewData.currentAgentLabel, '后备智能体');
    expect(viewData.currentAgentId, 'fallback-agent');
    expect(viewData.currentAgentDescription, '后备描述');
    expect(viewData.agentOptions, isEmpty);
    expect(viewData.canSwitchAgent, isFalse);
    expect(viewData.headerSubtitle, '后备副标题');
  });

  test('build keeps selector disabled when only one agent is available', () {
    final viewData = service.build(
      openingProjection: _projection(
        availableAgentSummaries: const <OpeningAgentMemberSummary>[
          OpeningAgentMemberSummary(
            agentId: 'writer',
            displayName: '作者智能体',
            role: '正文创作',
            isPrimary: true,
            thinkingSupported: true,
            description: '负责正文撰写',
          ),
        ],
        currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
          agentId: 'writer',
          displayName: '作者智能体',
          role: '正文创作',
          thinkingSupported: true,
        ),
      ),
      preferredAgentId: '',
      fallback: const ConversationAgentSelectorViewData.initial(),
    );

    expect(viewData.currentAgentId, 'writer');
    expect(viewData.agentOptions, hasLength(1));
    expect(viewData.agentOptions.single.note, '正文创作 · 负责正文撰写');
    expect(viewData.canSwitchAgent, isFalse);
  });

  test(
    'build keeps header subtitle empty when selected member has no role',
    () {
      final viewData = service.build(
        openingProjection: _projection(
          availableAgentSummaries: const <OpeningAgentMemberSummary>[
            OpeningAgentMemberSummary(
              agentId: 'writer',
              displayName: '作者智能体',
              role: '',
              isPrimary: true,
              thinkingSupported: true,
              description: '负责正文撰写',
            ),
          ],
          currentPrimaryAgentSummary: const OpeningPrimaryAgentSummary(
            agentId: 'writer',
            displayName: '作者智能体',
            role: '正文创作',
            thinkingSupported: true,
          ),
        ),
        preferredAgentId: 'writer',
        fallback: const ConversationAgentSelectorViewData.initial(),
      );

      expect(viewData.currentAgentDescription, '负责正文撰写');
      expect(viewData.headerSubtitle, isNull);
    },
  );
}

OpeningSessionProjection _projection({
  required List<OpeningAgentMemberSummary> availableAgentSummaries,
  required OpeningPrimaryAgentSummary? currentPrimaryAgentSummary,
}) {
  return OpeningSessionProjection(
    projectTypeId: 'novel',
    currentGroupId: 'starter_novel_group',
    currentGroupDisplayName: '默认小说组',
    groupSummaries: const <OpeningAgentGroupSummary>[
      OpeningAgentGroupSummary(
        groupId: 'starter_novel_group',
        displayName: '默认小说组',
        description: '适合小说协作',
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
          resolvedAgentGroupId: 'starter_novel_group',
          availableAgentGroupIds: <String>['starter_novel_group'],
        ),
        stageRecords: <OpeningStageRecord>[],
        createdAt: '2026-05-29T00:00:00Z',
        updatedAt: '2026-05-29T00:00:00Z',
      ),
      readiness: const OpeningReadinessAssessment(
        canStartLongTask: false,
        canStartInteractiveSession: true,
        missingRequirements: <OpeningMissingRequirement>[],
      ),
      suggestedActions: const <OpeningSuggestedAction>[],
    ),
    availableAgentSummaries: availableAgentSummaries,
    currentPrimaryAgentSummary: currentPrimaryAgentSummary,
  );
}
