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
  });
}
