import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('AgentSkillLoadoutSelectionService', () {
    const service = AgentSkillLoadoutSelectionService();

    test('prefers project-type-specific loadout over global fallback', () {
      final selected = service.selectBestMatch(
        agentId: 'default_generalist',
        projectTypeId: 'long_novel',
        loadouts: const <AgentSkillLoadout>[
          AgentSkillLoadout(
            agentId: 'default_generalist',
            source: AgentSkillLoadoutSource.projectSelection,
            extraSkillIds: <String>['global_skill'],
          ),
          AgentSkillLoadout(
            agentId: 'default_generalist',
            source: AgentSkillLoadoutSource.projectSelection,
            scope: AgentSkillLoadoutScope(
              projectTypeIds: <String>['long_novel'],
            ),
            extraSkillIds: <String>['long_novel_skill'],
          ),
        ],
      );

      expect(selected, isNotNull);
      expect(selected!.extraSkillIds, <String>['long_novel_skill']);
    });

    test(
      'ignores loadouts that require unsupported runtime scope dimensions',
      () {
        final selected = service.selectBestMatch(
          agentId: 'default_generalist',
          projectTypeId: 'long_novel',
          loadouts: const <AgentSkillLoadout>[
            AgentSkillLoadout(
              agentId: 'default_generalist',
              source: AgentSkillLoadoutSource.projectSelection,
              scope: AgentSkillLoadoutScope(agentGroupIds: <String>['starter']),
              extraSkillIds: <String>['scoped_skill'],
            ),
          ],
        );

        expect(selected, isNull);
      },
    );
  });
}
