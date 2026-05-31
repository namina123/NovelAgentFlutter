import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('SingleAgentGroupAdapterService', () {
    test('adapts single agent into single-member group', () {
      final adapter = SingleAgentGroupAdapterService();

      final group = adapter.adapt(
        const AgentProfile(
          id: 'default_generalist',
          name: '综合创作智能体',
          description: '默认全能智能体',
        ),
      );

      expect(group.id, 'single_agent_default_generalist');
      expect(group.members.length, 1);
      expect(group.primaryMember, isNotNull);
      expect(group.primaryMember!.isRequired, isTrue);
      expect(group.primaryMember!.profile.id, 'default_generalist');
      expect(group.metadata['derived_from_single_agent'], isTrue);
    });
  });
}
