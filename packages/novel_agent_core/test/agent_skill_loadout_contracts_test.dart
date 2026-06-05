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
        availableSkills: _availableSkills,
        toolPermissionProfile: const <String, Object?>{
          'allowed_tool_ids': <String>[
            'list_project_files',
            'read_project_file',
            'write_project_file',
            'submit_chapter_delivery',
          ],
        },
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
      expect(
        resolved.entries
            .singleWhere((entry) => entry.skillId == 'chapter_drafting_method')
            .enabled,
        isTrue,
      );
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

    test('resolver blocks non degradable skill when required capability is missing', () {
      final resolver = AgentSkillLoadoutResolverService();
      final resolved = resolver.resolve(
        profile: const AgentProfile(
          id: 'reviewer',
          name: '审稿智能体',
          description: '默认审稿',
          skills: <String>['external_research_strict'],
        ),
        availableSkills: _availableSkills,
        toolPermissionProfile: const <String, Object?>{
          'allowed_tool_ids': <String>[
            'list_project_files',
            'read_project_file',
          ],
        },
      );

      final researchEntry = resolved.entries.singleWhere(
        (entry) => entry.skillId == 'external_research_strict',
      );
      final issue = resolved.issues.singleWhere(
        (item) =>
            item.code == AgentSkillLoadoutIssueCode.requiredCapabilityMissing,
      );
      expect(researchEntry.enabled, isFalse);
      expect(issue.detailIds, <String>['network_access']);
      expect(issue.message, contains('需要联网权限'));
      expect(issue.message, contains('当前权限画像是只读'));
      expect(issue.message, contains('已阻止装载'));
      expect(issue.metadata['skill_source_kind'], 'builtin');
    });

    test('resolver keeps degradable skill enabled and reports non builtin source', () {
      final resolver = AgentSkillLoadoutResolverService();
      final resolved = resolver.resolve(
        profile: const AgentProfile(
          id: 'writer',
          name: '作者',
          description: '正文',
          skills: <String>['external_research_soft'],
        ),
        availableSkills: _availableSkills,
        toolPermissionProfile: const <String, Object?>{
          'allowed_tool_ids': <String>[
            'list_project_files',
            'read_project_file',
          ],
        },
      );

      final researchEntry = resolved.entries.singleWhere(
        (entry) => entry.skillId == 'external_research_soft',
      );
      final issue = resolved.issues.singleWhere(
        (item) =>
            item.code == AgentSkillLoadoutIssueCode.degradedCapabilityRequirement,
      );
      expect(researchEntry.enabled, isTrue);
      expect(issue.detailIds, <String>['network_access']);
      expect(issue.message, contains('已保留技能并降级为无工具流程指导'));
      expect(issue.metadata['skill_source_kind'], 'non_builtin');
    });
  });
}

const List<Object?> _availableSkills = <Object?>[
  <String, Object?>{
    'id': 'generate_outline',
    'name': '大纲生成',
    'source': 'builtin',
    'required_capabilities': <String>['project_read'],
    'safe_without_tools': true,
  },
  <String, Object?>{
    'id': 'project_context_research',
    'name': '资料检索',
    'source': 'builtin',
    'required_capabilities': <String>['project_read'],
    'safe_without_tools': true,
  },
  <String, Object?>{
    'id': 'artifact_routing',
    'name': '产物归档',
    'source': 'builtin',
    'required_capabilities': <String>['project_write'],
    'safe_without_tools': false,
  },
  <String, Object?>{
    'id': 'revision_workflow',
    'name': '修订流程',
    'source': 'builtin',
    'required_capabilities': <String>['project_write'],
    'safe_without_tools': true,
  },
  <String, Object?>{
    'id': 'summarize_chapter',
    'name': '章节总结',
    'source': 'builtin',
    'required_capabilities': <String>['project_read'],
    'safe_without_tools': true,
  },
  <String, Object?>{
    'id': 'memory_maintenance',
    'name': '记忆维护',
    'source': 'builtin',
    'required_capabilities': <String>['project_write'],
    'safe_without_tools': true,
  },
  <String, Object?>{
    'id': 'check_continuity',
    'name': '连续性检查',
    'source': 'builtin',
    'required_capabilities': <String>['project_read'],
    'safe_without_tools': true,
  },
  <String, Object?>{
    'id': 'chapter_drafting_method',
    'name': '正文起草',
    'source': 'builtin',
    'required_capabilities': <String>['project_write'],
    'optional_capabilities': <String>['formal_delivery'],
    'safe_without_tools': true,
  },
  <String, Object?>{
    'id': 'external_research_strict',
    'name': '严格外部检索',
    'source': 'builtin',
    'required_capabilities': <String>['network_access'],
    'safe_without_tools': false,
  },
  <String, Object?>{
    'id': 'external_research_soft',
    'name': '柔性外部检索',
    'source': 'package',
    'required_capabilities': <String>['network_access'],
    'safe_without_tools': true,
  },
];
