import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ApplicabilityScopeMatcherService', () {
    const matcher = ApplicabilityScopeMatcherService();

    test('accepts unrestricted agent scope', () {
      final result = matcher.matchAgentScope(
        const AgentApplicabilityScope(),
        projectTypeId: 'novel',
        projectTraits: ProjectTraitSet.fromIds(const <String>[]),
      );

      expect(result.matches, isTrue);
      expect(result.projectTypeAllowed, isTrue);
      expect(result.missingRequiredTraitIds, isEmpty);
    });

    test('rejects agent scope when required trait is missing', () {
      final result = matcher.matchAgentScope(
        const AgentApplicabilityScope(
          allowedProjectTypeIds: <String>['long_novel'],
          requiredTraitIds: <String>['seed_driven'],
        ),
        projectTypeId: 'long_novel',
        projectTraits: ProjectTraitSet.fromIds(const <String>[
          'long_task',
          'opening_guided',
        ]),
      );

      expect(result.matches, isFalse);
      expect(result.projectTypeAllowed, isTrue);
      expect(result.missingRequiredTraitIds, <String>['seed_driven']);
    });

    test('rejects group scope when excluded trait exists', () {
      final result = matcher.matchAgentGroupScope(
        const AgentGroupApplicabilityScope(
          requiredTraitIds: <String>['long_task'],
          excludedTraitIds: <String>['book_deconstruction'],
          allowedModeIds: <String>['seed_autopilot_novel'],
        ),
        projectTypeId: 'long_novel',
        modeId: 'seed_autopilot_novel',
        projectTraits: ProjectTraitSet.fromIds(const <String>[
          'long_task',
          'book_deconstruction',
        ]),
      );

      expect(result.matches, isFalse);
      expect(result.modeAllowed, isTrue);
      expect(result.excludedTraitIds, <String>['book_deconstruction']);
    });

    test('requires explicit mode and stage when scope declares them', () {
      final result = matcher.matchAgentGroupScope(
        const AgentGroupApplicabilityScope(
          allowedModeIds: <String>['full_outline_consensus'],
          allowedStageIds: <String>['opening'],
        ),
        projectTypeId: 'long_novel',
        modeId: 'full_outline_consensus',
        stageId: 'opening',
        projectTraits: ProjectTraitSet.fromIds(const <String>[
          'long_task',
          'full_outline',
        ]),
      );

      expect(result.matches, isTrue);
      expect(result.stageAllowed, isTrue);
    });
  });
}
