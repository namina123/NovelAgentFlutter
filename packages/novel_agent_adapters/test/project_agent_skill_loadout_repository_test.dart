import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectAgentSkillLoadoutRepository', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectAgentSkillLoadoutRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-project-skill-loadout-',
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      repository = ProjectAgentSkillLoadoutRepository(
        workspacePort: LocalProjectWorkspacePort(),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('persists loadouts inside current project only', () async {
      await repository.saveLoadouts(
        project,
        const <AgentSkillLoadout>[
          AgentSkillLoadout(
            agentId: 'default_generalist',
            source: AgentSkillLoadoutSource.projectSelection,
            scope: AgentSkillLoadoutScope(
              projectTypeIds: <String>['long_novel'],
            ),
            skillGroupIds: <String>['memory_tools'],
            extraSkillIds: <String>['chapter_drafting_method'],
            disabledSkillIds: <String>['generate_outline'],
          ),
        ],
      );

      final loaded = await repository.loadLoadouts(project);

      expect(loaded, hasLength(1));
      expect(loaded.single.agentId, 'default_generalist');
      expect(loaded.single.skillGroupIds, <String>['memory_tools']);
      expect(loaded.single.extraSkillIds, <String>['chapter_drafting_method']);
      expect(loaded.single.disabledSkillIds, <String>['generate_outline']);
      final loadoutFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}settings${Platform.pathSeparator}agent_skill_loadouts.json',
      );
      expect(await loadoutFile.exists(), isTrue);
    });
  });
}
