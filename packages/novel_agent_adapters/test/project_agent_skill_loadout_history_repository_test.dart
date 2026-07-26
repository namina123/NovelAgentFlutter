import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectAgentSkillLoadoutHistoryRepository', () {
    late Directory tempDirectory;
    late ProjectDescriptor project;
    late ProjectAgentSkillLoadoutHistoryRepository repository;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'novel-agent-project-skill-history-',
      );
      project = ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: tempDirectory.path,
        projectType: 'novel',
      );
      repository = ProjectAgentSkillLoadoutHistoryRepository(
        workspacePort: LocalProjectWorkspacePort(),
      );
    });

    tearDown(() async {
      if (await tempDirectory.exists()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test(
      'saves and lists history snapshots separately from current loadout',
      () async {
        await repository.saveEntry(
          project,
          const AgentSkillLoadoutHistoryEntry(
            id: 'history_1',
            agentId: 'default_generalist',
            title: '第一版组合',
            createdAt: '2026-05-27T10:00:00Z',
            loadout: AgentSkillLoadout(
              agentId: 'default_generalist',
              source: AgentSkillLoadoutSource.historyRestore,
              skillGroupIds: <String>['project_io'],
              extraSkillIds: <String>['generate_outline'],
            ),
          ),
        );
        await repository.saveEntry(
          project,
          const AgentSkillLoadoutHistoryEntry(
            id: 'history_2',
            agentId: 'default_generalist',
            title: '第二版组合',
            createdAt: '2026-05-27T11:00:00Z',
            loadout: AgentSkillLoadout(
              agentId: 'default_generalist',
              source: AgentSkillLoadoutSource.historyRestore,
              skillGroupIds: <String>['memory_tools'],
            ),
          ),
        );

        final entries = await repository.listEntries(project);

        expect(entries, hasLength(2));
        expect(entries.first.id, 'history_2');
        expect(entries.first.loadout.skillGroupIds, <String>['memory_tools']);
        expect(entries.last.id, 'history_1');
        final historyFile = File(
          '${tempDirectory.path}${Platform.pathSeparator}.novel_agent${Platform.pathSeparator}history${Platform.pathSeparator}agent_skill_loadouts${Platform.pathSeparator}history_1.json',
        );
        expect(await historyFile.exists(), isTrue);
      },
    );
  });
}
