import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('Agent skill loadout contracts', () {
    test('loadout keeps current project selection separate from agent defaults', () {
      const loadout = AgentSkillLoadout(
        agentId: 'default_generalist',
        source: AgentSkillLoadoutSource.projectSelection,
        skillGroupIds: <String>['memory_tools'],
        extraSkillIds: <String>['chapter_drafting_method'],
        disabledSkillIds: <String>['generate_outline'],
      );

      expect(loadout.isEmpty, isFalse);
      expect(loadout.appliesToAgent('default_generalist'), isTrue);
      expect(loadout.appliesToAgent('other_agent'), isFalse);
    });

    test('scope distinguishes global and scoped loadouts', () {
      const globalScope = AgentSkillLoadoutScope();
      const scoped = AgentSkillLoadoutScope(
        projectTypeIds: <String>['long_novel'],
        modeIds: <String>['seed_autopilot_novel'],
        stageIds: <String>['draft'],
      );

      expect(globalScope.isGlobal, isTrue);
      expect(scoped.isGlobal, isFalse);
    });

    test('builder keeps profile defaults and explicit loadout separate before expansion', () {
      final builder = ResolvedAgentSkillLoadoutBuilderService();
      final resolved = builder.build(
        profile: const AgentProfile(
          id: 'default_generalist',
          name: '综合创作智能体',
          description: '默认主智能体',
          skills: <String>['generate_outline'],
          skillGroups: <String>['project_io'],
        ),
        loadout: const AgentSkillLoadout(
          agentId: 'default_generalist',
          source: AgentSkillLoadoutSource.projectSelection,
          scope: AgentSkillLoadoutScope(
            projectTypeIds: <String>['long_novel'],
          ),
          skillGroupIds: <String>['memory_tools'],
          extraSkillIds: <String>['chapter_drafting_method'],
          disabledSkillIds: <String>['generate_outline'],
          metadata: <String, Object?>{'label': '长篇写作装载'},
        ),
      );

      expect(resolved.agentId, 'default_generalist');
      expect(resolved.source, AgentSkillLoadoutSource.projectSelection);
      expect(resolved.scope.projectTypeIds, <String>['long_novel']);
      expect(
        resolved.profileSkillIds,
        <String>['generate_outline'],
      );
      expect(
        resolved.profileSkillGroupIds,
        <String>['project_io'],
      );
      expect(
        resolved.selectedDirectSkillIds,
        <String>['chapter_drafting_method'],
      );
      expect(
        resolved.selectedSkillGroupIds,
        <String>['memory_tools'],
      );
      expect(resolved.disabledSkillIds, <String>['generate_outline']);
      expect(resolved.hasExplicitLoadout, isTrue);
    });

    test('builder falls back to agent defaults when loadout targets another agent', () {
      final builder = ResolvedAgentSkillLoadoutBuilderService();
      final resolved = builder.build(
        profile: const AgentProfile(
          id: 'default_generalist',
          name: '综合创作智能体',
          description: '默认主智能体',
          skills: <String>['generate_outline'],
          skillGroups: <String>['project_io'],
        ),
        loadout: const AgentSkillLoadout(
          agentId: 'other_agent',
          skillGroupIds: <String>['memory_tools'],
          extraSkillIds: <String>['chapter_drafting_method'],
        ),
      );

      expect(resolved.source, AgentSkillLoadoutSource.agentDefault);
      expect(resolved.selectedDirectSkillIds, isEmpty);
      expect(resolved.selectedSkillGroupIds, isEmpty);
      expect(resolved.disabledSkillIds, isEmpty);
      expect(resolved.hasExplicitLoadout, isFalse);
    });

    test('resolver expands groups, applies disabled skills and keeps source explanation', () {
      final resolver = AgentSkillLoadoutResolverService();
      final resolved = resolver.resolve(
        profile: const AgentProfile(
          id: 'default_generalist',
          name: '综合创作智能体',
          description: '默认主智能体',
          skills: <String>['generate_outline'],
          skillGroups: <String>['project_io'],
        ),
        loadout: const AgentSkillLoadout(
          agentId: 'default_generalist',
          skillGroupIds: <String>['memory_tools'],
          extraSkillIds: <String>['chapter_drafting_method'],
          disabledSkillIds: <String>['generate_outline'],
        ),
      );

      expect(
        resolved.finalSkillIds,
        <String>[
          'project_context_research',
          'artifact_routing',
          'revision_workflow',
          'summarize_chapter',
          'memory_maintenance',
          'check_continuity',
          'chapter_drafting_method',
        ],
      );
      final outlineEntry = resolved.entries.singleWhere(
        (entry) => entry.skillId == 'generate_outline',
      );
      expect(outlineEntry.enabled, isFalse);
      expect(outlineEntry.disabledByLoadout, isTrue);
      expect(
        outlineEntry.sources.map((source) => source.kind),
        <ResolvedAgentSkillLoadoutEntrySourceKind>[
          ResolvedAgentSkillLoadoutEntrySourceKind.profileDirectSkill,
        ],
      );
      final memoryEntry = resolved.entries.singleWhere(
        (entry) => entry.skillId == 'memory_maintenance',
      );
      expect(
        memoryEntry.sources.single.kind,
        ResolvedAgentSkillLoadoutEntrySourceKind.loadoutSkillGroup,
      );
      expect(memoryEntry.sources.single.referenceId, 'memory_tools');
      expect(resolved.issues, isEmpty);
    });

    test('resolver returns diagnostics for missing groups, builtin tools and unmatched disabled skills', () {
      final resolver = AgentSkillLoadoutResolverService();
      final resolved = resolver.resolve(
        profile: const AgentProfile(
          id: 'default_generalist',
          name: '综合创作智能体',
          description: '默认主智能体',
          skills: <String>['read_project_file'],
        ),
        loadout: const AgentSkillLoadout(
          agentId: 'default_generalist',
          skillGroupIds: <String>['missing_group'],
          disabledSkillIds: <String>['nonexistent_skill'],
        ),
      );

      expect(resolved.finalSkillIds, isEmpty);
      expect(
        resolved.issues.map((issue) => issue.code),
        containsAll(<AgentSkillLoadoutIssueCode>[
          AgentSkillLoadoutIssueCode.missingSkillGroup,
          AgentSkillLoadoutIssueCode.builtinToolFiltered,
          AgentSkillLoadoutIssueCode.disabledSkillMissingTarget,
        ]),
      );
    });
  });
}
