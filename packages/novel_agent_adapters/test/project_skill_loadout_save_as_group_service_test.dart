import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectSkillLoadoutSaveAsGroupService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectSkillLoadoutSaveAsGroupService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-skill-save-group-',
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
        projectType: 'novel',
      );
      service = ProjectSkillLoadoutSaveAsGroupService(
        workspacePort: LocalProjectWorkspacePort(),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('saves resolved loadout as explicit project skill group', () async {
      final relativePath = await service.saveAsGroup(
        project: project,
        loadout: const ResolvedAgentSkillLoadout(
          agentId: 'default_generalist',
          source: AgentSkillLoadoutSource.projectSelection,
          scope: AgentSkillLoadoutScope(),
          entries: <ResolvedAgentSkillLoadoutEntry>[
            ResolvedAgentSkillLoadoutEntry(
              skillId: 'generate_outline',
              sources: <ResolvedAgentSkillLoadoutEntrySource>[
                ResolvedAgentSkillLoadoutEntrySource(
                  kind: ResolvedAgentSkillLoadoutEntrySourceKind
                      .loadoutDirectSkill,
                  referenceId: '',
                ),
              ],
            ),
            ResolvedAgentSkillLoadoutEntry(
              skillId: 'memory_maintenance',
              sources: <ResolvedAgentSkillLoadoutEntrySource>[
                ResolvedAgentSkillLoadoutEntrySource(
                  kind: ResolvedAgentSkillLoadoutEntrySourceKind
                      .loadoutSkillGroup,
                  referenceId: 'memory_tools',
                ),
              ],
            ),
          ],
        ),
        groupId: 'long novel starter',
        displayName: '长篇起步组',
        description: '显式保存的项目技能组。',
      );

      expect(relativePath, 'skill_groups/long_novel_starter/skill_group.json');
      final savedFile = File(
        '${tempDirectory.path}${Platform.pathSeparator}skill_groups${Platform.pathSeparator}long_novel_starter${Platform.pathSeparator}skill_group.json',
      );
      expect(await savedFile.exists(), isTrue);

      final groups = await LocalSkillGroupCatalog().loadSkillGroups(project);
      final group = groups.singleWhere(
        (item) => ValueReaders.stringValue(item['id']) == 'long_novel_starter',
      );
      expect(group['name'], '长篇起步组');
      expect(ValueReaders.stringList(group['skills']), <String>[
        'generate_outline',
        'memory_maintenance',
      ]);
      expect(
        ValueReaders.mapValue(group['metadata'])['generated_from_agent_id'],
        'default_generalist',
      );
    });
  });
}
