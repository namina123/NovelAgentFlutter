import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/services/project_skill_loadout_workspace_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ProjectSkillLoadoutWorkspaceService', () {
    late ProjectDescriptor project;
    late List<AgentSkillLoadout> savedLoadouts;
    late List<AgentSkillLoadoutHistoryEntry> historyEntries;
    late ProjectSkillLoadoutWorkspaceService service;

    setUp(() {
      project = const ProjectDescriptor(
        id: 'project_1',
        name: '测试项目',
        rootPath: 'D:/Projects/demo',
        projectType: 'long_novel',
      );
      savedLoadouts = <AgentSkillLoadout>[
        const AgentSkillLoadout(
          agentId: 'agent_1',
          source: AgentSkillLoadoutSource.projectSelection,
          skillGroupIds: <String>['combo'],
          extraSkillIds: <String>['extra_skill'],
        ),
      ];
      historyEntries = <AgentSkillLoadoutHistoryEntry>[];
      service = ProjectSkillLoadoutWorkspaceService(
        loadLoadouts: (_) async => savedLoadouts,
        saveLoadouts: (_, loadouts) async {
          savedLoadouts = List<AgentSkillLoadout>.from(loadouts);
        },
        loadHistoryEntries: (_) async => historyEntries,
        saveHistoryEntry: (_, entry) async {
          historyEntries = <AgentSkillLoadoutHistoryEntry>[
            entry,
            ...historyEntries,
          ];
        },
        saveAsGroup:
            ({
              required project,
              required loadout,
              required groupId,
              required displayName,
              required description,
            }) async => groupId,
      );
    });

    test(
      'applyDraft removes persisted loadout when draft becomes empty',
      () async {
        var snapshot = await service.load(project);

        snapshot = service.toggleSkillGroup(
          snapshot,
          agentId: 'agent_1',
          groupId: 'combo',
          selected: false,
        );
        snapshot = service.toggleExtraSkill(
          snapshot,
          agentId: 'agent_1',
          skillId: 'extra_skill',
          selected: false,
        );

        final applied = await service.applyDraft(
          project,
          snapshot,
          agentId: 'agent_1',
        );

        expect(savedLoadouts, isEmpty);
        expect(applied.savedLoadouts, isEmpty);
        expect(applied.draftLoadouts.containsKey('agent_1'), isFalse);
      },
    );

    test(
      'saveHistorySnapshot and restoreHistoryEntry only mutate current draft',
      () async {
        var snapshot = await service.load(project);
        snapshot = service.toggleDisabledSkill(
          snapshot,
          agentId: 'agent_1',
          skillId: 'base_skill',
          disabled: true,
        );

        final savedHistory = await service.saveHistorySnapshot(
          project,
          snapshot,
          agentId: 'agent_1',
          title: '阶段一装载',
        );

        expect(savedLoadouts, hasLength(1));
        expect(savedHistory.historyEntries, hasLength(1));
        expect(savedHistory.historyEntries.single.title, '阶段一装载');

        final restored = service.restoreHistoryEntry(
          savedHistory,
          agentId: 'agent_1',
          historyEntryId: savedHistory.historyEntries.single.id,
        );

        expect(
          restored.draftLoadouts['agent_1']!.source,
          AgentSkillLoadoutSource.historyRestore,
        );
        expect(restored.draftLoadouts['agent_1']!.disabledSkillIds, <String>[
          'base_skill',
        ]);
      },
    );
  });
}
