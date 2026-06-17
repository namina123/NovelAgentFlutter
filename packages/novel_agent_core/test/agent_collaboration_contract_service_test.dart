import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('AgentCollaborationContractService', () {
    final service = AgentCollaborationContractService();

    test('keeps single-agent groups from enabling child delegation', () {
      final contract = service.resolve(
        candidateToolIds: const <String>[
          'present_user_options',
          'call_sub_agent',
          'submit_semantic_review',
        ],
        selectedCollaborationGroup: const <String, Object?>{
          'id': 'single_agent_writer',
          'agents': <String>['writer'],
          'primary_agent_id': 'writer',
          'metadata': <String, Object?>{'derived_from_single_agent': true},
        },
        runtimeContext: const <String, Object?>{'task_type': 'draft'},
        intent: 'draft',
        mainAgent: const <String, Object?>{
          'id': 'writer',
          'name': '作者',
          'role': '负责正文',
        },
        availableAgents: const <JsonMap>[
          <String, Object?>{
            'id': 'writer',
            'name': '作者',
            'role': '负责正文',
          },
        ],
        availableGroups: const <JsonMap>[],
      );

      expect(contract.delegation.allowed, isFalse);
      expect(contract.delegation.childAgentIds, isEmpty);
      expect(contract.toolVisibility.visibleToolIds, isNot(contains('call_sub_agent')));
      expect(contract.toolVisibility.delegationAllowed, isFalse);
    });

    test('falls back to self review when no dedicated reviewer exists', () {
      final contract = service.resolve(
        candidateToolIds: const <String>['submit_semantic_review'],
        selectedCollaborationGroup: const <String, Object?>{
          'id': 'review_room',
          'agents': <String>['writer'],
          'primary_agent_id': 'writer',
        },
        runtimeContext: const <String, Object?>{'task_type': 'review'},
        intent: 'review',
        mainAgent: const <String, Object?>{
          'id': 'writer',
          'name': '作者',
          'role': '负责正文',
        },
        availableAgents: const <JsonMap>[
          <String, Object?>{
            'id': 'writer',
            'name': '作者',
            'role': '负责正文',
          },
        ],
        availableGroups: const <JsonMap>[],
      );

      expect(contract.reviewer.applicable, isTrue);
      expect(contract.reviewer.shouldDelegate, isFalse);
      expect(
        contract.reviewer.selectionMode,
        ReviewerSelectionModes.primaryWriterSelfReview,
      );
      expect(contract.reviewer.agentId, 'writer');
    });
  });
}
