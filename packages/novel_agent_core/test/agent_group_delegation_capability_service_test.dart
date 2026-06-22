import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('AgentGroupDelegationCapabilityService', () {
    const service = AgentGroupDelegationCapabilityService();

    test('returns false for derived single-agent groups', () {
      const group = <String, Object?>{
        'id': 'single_agent_writer',
        'agents': <String>['writer'],
        'primary_agent_id': 'writer',
        'metadata': <String, Object?>{'derived_from_single_agent': true},
      };

      expect(service.supportsChildDelegation(group), isFalse);
      expect(service.childAgentIds(group), isEmpty);
    });

    test('returns true only when a real child member exists', () {
      const group = <String, Object?>{
        'id': 'writer_room',
        'agents': <String>['writer', 'reviewer'],
        'primary_agent_id': 'writer',
      };

      expect(service.supportsChildDelegation(group), isTrue);
      expect(service.childAgentIds(group), <String>['reviewer']);
    });

    test(
      'returns false for any derived-single-agent flag spelling even with members',
      () {
        // 中文注释: 历史上 adapter/controller/candidate-resolver 用三种不同 flag 标记“派生自单智能体”。
        // 这里复现 controller 路径（derived_from_agent_binding）在 summary 含多成员时仍不应允许委派。
        const controllerDerived = <String, Object?>{
          'id': 'derived_current',
          'agents': <String>['writer', 'reviewer'],
          'primary_agent_id': 'writer',
          'metadata': <String, Object?>{'derived_from_agent_binding': true},
        };
        expect(service.supportsChildDelegation(controllerDerived), isFalse);
        expect(service.childAgentIds(controllerDerived), isEmpty);

        const resolverDerived = <String, Object?>{
          'id': 'derived_binding',
          'agents': <String>['writer', 'editor_in_chief'],
          'primary_agent_id': 'writer',
          'metadata': <String, Object?>{
            'derived_from_project_agent_binding': true,
          },
        };
        expect(service.supportsChildDelegation(resolverDerived), isFalse);
        expect(service.childAgentIds(resolverDerived), isEmpty);
      },
    );
  });
}
