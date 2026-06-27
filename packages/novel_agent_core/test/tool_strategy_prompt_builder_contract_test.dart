import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ToolStrategyPromptBuilder', () {
    test('consumes collaboration contract for delegation wording', () {
      final builder = ToolStrategyPromptBuilder(
        toolStrategyService: const ToolStrategyService(),
        projectPromptContract: ProjectPromptContract(),
      );
      final profileResolver = const ContinuousTaskProfileResolverService();
      final exposureResolver =
          const ContinuousTaskToolExposureProfileResolverService();
      final taskProfile = profileResolver.forLongTaskMode('draft');
      final exposureResolution = ContinuousTaskToolExposureRuntimeResolution(
        taskProfile: taskProfile,
        exposureProfile: exposureResolver.resolveForTaskProfile(taskProfile),
        defaultAllowedToolIds: const <String>['call_sub_agent'],
        requiresConfirmationToolIds: const <String>[],
        metadata: const <String, Object?>{'delegation_allowed': true},
      );
      final contract = AgentCollaborationContract(
        exposureResolution: exposureResolution,
        toolVisibility: const AgentToolVisibilityContract(
          visibleToolIds: <String>['present_user_options', 'call_sub_agent'],
          defaultAllowedToolIds: <String>['call_sub_agent'],
          requiresConfirmationToolIds: <String>[],
          interactionHintToolIds: <String>['present_user_options'],
          delegationAllowed: true,
        ),
        delegation: const AgentDelegationContract(
          allowed: true,
          childAgentIds: <String>['reviewer'],
          primaryAgentId: 'writer',
          rationale: 'group_has_child_agents',
        ),
        reviewer: const AgentReviewerDispatchContract(
          applicable: true,
          shouldDelegate: false,
          executionMode: 'self_review',
          selectionMode: ReviewerSelectionModes.primaryWriterSelfReview,
          selectionRationale: 'primary_writer_self_review_fallback',
          agentId: 'writer',
          agentName: '作者',
          agentRole: '负责正文',
          groupId: 'writer_room',
          groupName: '写作组',
          groupMemberIds: <String>['writer'],
        ),
      );

      final prompt = builder.buildPromptText(
        settings: const <String, Object?>{},
        intent: 'draft',
        projectNote: 'project-note',
        projectTreeNote: 'tree-note',
        agentNote: 'agent-note',
        styleNote: 'style-note',
        collaborationContract: contract,
        toolIds: const <String>[
          'call_sub_agent',
          'present_user_options',
        ],
      );

      expect(prompt.stable, contains('当前协作合同允许按需调用子智能体'));
      expect(prompt.stable, contains('只传任务摘录、约束和期望产物'));
      expect(prompt.stable, contains('可组装协作视角素材'));
    });

    test('injects conversation goal into stable prefix when provided', () {
      final builder = ToolStrategyPromptBuilder(
        toolStrategyService: const ToolStrategyService(),
        projectPromptContract: ProjectPromptContract(),
      );
      final withGoal = builder.buildPromptText(
        settings: const <String, Object?>{},
        intent: 'draft',
        projectNote: 'project-note',
        projectTreeNote: 'tree-note',
        agentNote: 'agent-note',
        styleNote: 'style-note',
        conversationGoal: '收束第三章伏笔',
        toolIds: const <String>[],
      );
      expect(withGoal.stable, contains('本次会话目标：收束第三章伏笔'));

      final withoutGoal = builder.buildPromptText(
        settings: const <String, Object?>{},
        intent: 'draft',
        projectNote: 'project-note',
        projectTreeNote: 'tree-note',
        agentNote: 'agent-note',
        styleNote: 'style-note',
        toolIds: const <String>[],
      );
      expect(withoutGoal.stable, isNot(contains('本次会话目标')));
    });
  });
}
