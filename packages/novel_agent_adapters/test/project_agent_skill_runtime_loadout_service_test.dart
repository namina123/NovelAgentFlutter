import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectAgentSkillRuntimeLoadoutService', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectDescriptor secondProject;
    late ProjectAgentSkillLoadoutRepository repository;
    late ProjectAgentSkillRuntimeLoadoutService service;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-runtime-loadout-',
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
        projectType: 'long_novel',
      );
      secondProject = ProjectDescriptor(
        id: 'project_2',
        name: '另一个项目',
        rootPath: '${tempDirectory.path}${Platform.pathSeparator}project_b',
        projectType: 'long_novel',
      );
      repository = ProjectAgentSkillLoadoutRepository(
        workspacePort: LocalProjectWorkspacePort(),
      );
      service = ProjectAgentSkillRuntimeLoadoutService(
        loadoutRepository: repository,
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'resolves project loadout before falling back to agent defaults',
      () async {
        await repository.saveLoadouts(project, const <AgentSkillLoadout>[
          AgentSkillLoadout(
            agentId: 'default_generalist',
            source: AgentSkillLoadoutSource.projectSelection,
            scope: AgentSkillLoadoutScope(
              projectTypeIds: <String>['long_novel'],
            ),
            extraSkillIds: <String>['custom_style_review'],
            disabledSkillIds: <String>['generate_outline'],
          ),
        ]);

        final resolved = await service.resolveForAgent(
          project: project,
          agent: const <String, Object?>{
            'id': 'default_generalist',
            'skills': <String>['generate_outline'],
          },
          availableSkillIds: const <String>[
            'generate_outline',
            'custom_style_review',
          ],
        );

        expect(resolved.source, AgentSkillLoadoutSource.projectSelection);
        expect(resolved.finalSkillIds, <String>['custom_style_review']);
      },
    );

    test(
      'falls back to agent defaults when project has no matching loadout',
      () async {
        final resolved = await service.resolveForAgent(
          project: project,
          agent: const <String, Object?>{
            'id': 'default_generalist',
            'skills': <String>['generate_outline'],
          },
          availableSkillIds: const <String>['generate_outline'],
        );

        expect(resolved.source, AgentSkillLoadoutSource.agentDefault);
        expect(resolved.finalSkillIds, <String>['generate_outline']);
      },
    );

    test('keeps runtime loadouts isolated across projects', () async {
      await repository.saveLoadouts(project, const <AgentSkillLoadout>[
        AgentSkillLoadout(
          agentId: 'default_generalist',
          source: AgentSkillLoadoutSource.projectSelection,
          extraSkillIds: <String>['skill_a'],
          disabledSkillIds: <String>['generate_outline'],
        ),
      ]);
      await repository.saveLoadouts(secondProject, const <AgentSkillLoadout>[
        AgentSkillLoadout(
          agentId: 'default_generalist',
          source: AgentSkillLoadoutSource.projectSelection,
          extraSkillIds: <String>['skill_b'],
          disabledSkillIds: <String>['generate_outline'],
        ),
      ]);

      final firstResolved = await service.resolveForAgent(
        project: project,
        agent: const <String, Object?>{
          'id': 'default_generalist',
          'skills': <String>['generate_outline'],
        },
        availableSkillIds: const <String>[
          'generate_outline',
          'skill_a',
          'skill_b',
        ],
      );
      final secondResolved = await service.resolveForAgent(
        project: secondProject,
        agent: const <String, Object?>{
          'id': 'default_generalist',
          'skills': <String>['generate_outline'],
        },
        availableSkillIds: const <String>[
          'generate_outline',
          'skill_a',
          'skill_b',
        ],
      );

      expect(firstResolved.finalSkillIds, <String>['skill_a']);
      expect(secondResolved.finalSkillIds, <String>['skill_b']);
    });
  });
}
