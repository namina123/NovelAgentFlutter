import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('AgentAvailabilityResolverService', () {
    test('rejects agent when project binding disables it', () {
      final resolver = AgentAvailabilityResolverService();

      final assessment = resolver.resolve(
        profile: const AgentProfile(
          id: 'writer',
          name: '作者',
          description: '负责正文',
        ),
        context: AgentAvailabilityContext(
          projectTypeId: 'novel',
          projectTraits: ProjectTraitSet.fromIds(const <String>[
            'opening_guided',
          ]),
        ),
        binding: const ProjectAgentBinding(agentId: 'writer', enabled: false),
      );

      expect(assessment.isSupported, isFalse);
      expect(
        assessment.reasons.first.code,
        AgentAvailabilityReasonCode.disabledByProjectBinding,
      );
    });

    test('rejects agent when scope traits are not satisfied', () {
      final resolver = AgentAvailabilityResolverService();

      final assessment = resolver.resolve(
        profile: const AgentProfile(
          id: 'reviewer',
          name: '审稿',
          description: '负责审稿',
        ),
        context: AgentAvailabilityContext(
          projectTypeId: 'long_novel',
          projectTraits: ProjectTraitSet.fromIds(const <String>['long_task']),
        ),
        scope: const AgentApplicabilityScope(
          requiredTraitIds: <String>['full_outline'],
        ),
      );

      expect(assessment.isSupported, isFalse);
      expect(
        assessment.reasons.any(
          (reason) =>
              reason.code == AgentAvailabilityReasonCode.missingRequiredTraits,
        ),
        isTrue,
      );
    });
  });
}
