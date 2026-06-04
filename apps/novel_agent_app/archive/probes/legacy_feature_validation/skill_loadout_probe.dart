import 'dart:convert';
import 'dart:io';

import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/agent_ecosystem/application/services/project_skill_loadout_workspace_service.dart'
    as app_services;
import 'package:novel_agent_core/novel_agent_core.dart';

Future<void> main() async {
  // 中文注释: 该探针只验证 skill / skill_group / skill_loadout 的七个闭环场景，不扩成 UI 或真实模型链。
  final tempRoot = await Directory.systemTemp.createTemp(
    'novel_agent_skill_loadout_probe_',
  );
  final workspacePort = LocalProjectWorkspacePort();
  final loadoutRepository = ProjectAgentSkillLoadoutRepository(
    workspacePort: workspacePort,
  );
  final historyRepository = ProjectAgentSkillLoadoutHistoryRepository(
    workspacePort: workspacePort,
  );
  final saveAsGroupService = ProjectSkillLoadoutSaveAsGroupService(
    workspacePort: workspacePort,
  );
  final runtimeService = ProjectAgentSkillRuntimeLoadoutService(
    loadoutRepository: loadoutRepository,
  );
  final workspaceService = app_services.ProjectSkillLoadoutWorkspaceService(
    loadLoadouts: loadoutRepository.loadLoadouts,
    saveLoadouts: loadoutRepository.saveLoadouts,
    loadHistoryEntries: historyRepository.listEntries,
    saveHistoryEntry: historyRepository.saveEntry,
    saveAsGroup:
        ({
          required project,
          required loadout,
          required groupId,
          required displayName,
          required description,
        }) => saveAsGroupService.saveAsGroup(
          project: project,
          loadout: loadout,
          groupId: groupId,
          displayName: displayName,
          description: description,
        ),
  );
  final projectA = ProjectDescriptor(
    id: 'project_a',
    name: '技能装载项目 A',
    rootPath: '${tempRoot.path}${Platform.pathSeparator}project_a',
    projectType: 'long_novel',
  );
  final projectB = ProjectDescriptor(
    id: 'project_b',
    name: '技能装载项目 B',
    rootPath: '${tempRoot.path}${Platform.pathSeparator}project_b',
    projectType: 'long_novel',
  );

  const agent = <String, Object?>{
    'id': 'default_generalist',
    'name': '综合创作智能体',
    'skills': <String>['base_skill'],
  };
  const skillGroups = <JsonMap>[
    <String, Object?>{
      'id': 'combo_group',
      'name': '组合技能组',
      'skills': <String>['group_skill'],
    },
  ];
  const availableSkillIds = <String>[
    'base_skill',
    'group_skill',
    'extra_skill',
    'project_a_skill',
    'project_b_skill',
  ];

  try {
    final report = <String, Object?>{
      'default_agent_profile': await _defaultAgentProfileCase(
        repository: loadoutRepository,
        runtimeService: runtimeService,
        project: projectA,
        agent: agent,
        skillGroups: skillGroups,
        availableSkillIds: availableSkillIds,
      ),
      'group_only': await _groupOnlyCase(
        repository: loadoutRepository,
        runtimeService: runtimeService,
        project: projectA,
        agent: agent,
        skillGroups: skillGroups,
        availableSkillIds: availableSkillIds,
      ),
      'group_plus_extra': await _groupPlusExtraCase(
        repository: loadoutRepository,
        runtimeService: runtimeService,
        project: projectA,
        agent: agent,
        skillGroups: skillGroups,
        availableSkillIds: availableSkillIds,
      ),
      'group_plus_disabled': await _groupPlusDisabledCase(
        repository: loadoutRepository,
        runtimeService: runtimeService,
        project: projectA,
        agent: agent,
        skillGroups: skillGroups,
        availableSkillIds: availableSkillIds,
      ),
      'history_restore': await _historyRestoreCase(
        repository: loadoutRepository,
        workspaceService: workspaceService,
        project: projectA,
      ),
      'save_as_group': await _saveAsGroupCase(
        repository: loadoutRepository,
        runtimeService: runtimeService,
        saveAsGroupService: saveAsGroupService,
        project: projectA,
        agent: agent,
        skillGroups: skillGroups,
        availableSkillIds: availableSkillIds,
      ),
      'project_switch_isolation': await _projectSwitchIsolationCase(
        repository: loadoutRepository,
        runtimeService: runtimeService,
        workspaceService: workspaceService,
        firstProject: projectA,
        secondProject: projectB,
        agent: agent,
        skillGroups: skillGroups,
        availableSkillIds: availableSkillIds,
      ),
    };

    final reportPath = File(
      '${Directory.current.path}${Platform.pathSeparator}artifacts${Platform.pathSeparator}skill_loadout_probe_report.json',
    );
    await reportPath.parent.create(recursive: true);
    await reportPath.writeAsString(
      const JsonEncoder.withIndent('  ').convert(report),
    );
    final ok = report.values.every((value) {
      final record = ValueReaders.mapValue(value);
      return ValueReaders.boolValue(record['ok']);
    });
    stdout.writeln('report: ${reportPath.path}');
    stdout.writeln(ok ? 'PASS' : 'FAIL');
  } finally {
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  }
}

Future<Map<String, Object?>> _defaultAgentProfileCase({
  required ProjectAgentSkillLoadoutRepository repository,
  required ProjectAgentSkillRuntimeLoadoutService runtimeService,
  required ProjectDescriptor project,
  required JsonMap agent,
  required List<JsonMap> skillGroups,
  required List<String> availableSkillIds,
}) async {
  await repository.saveLoadouts(project, const <AgentSkillLoadout>[]);
  final resolved = await runtimeService.resolveForAgent(
    project: project,
    agent: agent,
    availableSkillGroups: skillGroups,
    availableSkillIds: availableSkillIds,
  );
  final ok =
      resolved.source == AgentSkillLoadoutSource.agentDefault &&
      _sameStringList(resolved.finalSkillIds, const <String>['base_skill']);
  return <String, Object?>{
    'ok': ok,
    'source': resolved.source.id,
    'final_skill_ids': resolved.finalSkillIds,
  };
}

Future<Map<String, Object?>> _groupOnlyCase({
  required ProjectAgentSkillLoadoutRepository repository,
  required ProjectAgentSkillRuntimeLoadoutService runtimeService,
  required ProjectDescriptor project,
  required JsonMap agent,
  required List<JsonMap> skillGroups,
  required List<String> availableSkillIds,
}) async {
  await repository.saveLoadouts(project, const <AgentSkillLoadout>[
    AgentSkillLoadout(
      agentId: 'default_generalist',
      source: AgentSkillLoadoutSource.projectSelection,
      skillGroupIds: <String>['combo_group'],
    ),
  ]);
  final resolved = await runtimeService.resolveForAgent(
    project: project,
    agent: agent,
    availableSkillGroups: skillGroups,
    availableSkillIds: availableSkillIds,
  );
  final ok =
      resolved.source == AgentSkillLoadoutSource.projectSelection &&
      _sameStringList(resolved.finalSkillIds, const <String>[
        'base_skill',
        'group_skill',
      ]);
  return <String, Object?>{
    'ok': ok,
    'source': resolved.source.id,
    'final_skill_ids': resolved.finalSkillIds,
  };
}

Future<Map<String, Object?>> _groupPlusExtraCase({
  required ProjectAgentSkillLoadoutRepository repository,
  required ProjectAgentSkillRuntimeLoadoutService runtimeService,
  required ProjectDescriptor project,
  required JsonMap agent,
  required List<JsonMap> skillGroups,
  required List<String> availableSkillIds,
}) async {
  await repository.saveLoadouts(project, const <AgentSkillLoadout>[
    AgentSkillLoadout(
      agentId: 'default_generalist',
      source: AgentSkillLoadoutSource.projectSelection,
      skillGroupIds: <String>['combo_group'],
      extraSkillIds: <String>['extra_skill'],
    ),
  ]);
  final resolved = await runtimeService.resolveForAgent(
    project: project,
    agent: agent,
    availableSkillGroups: skillGroups,
    availableSkillIds: availableSkillIds,
  );
  final ok = _sameStringList(resolved.finalSkillIds, const <String>[
    'base_skill',
    'group_skill',
    'extra_skill',
  ]);
  return <String, Object?>{'ok': ok, 'final_skill_ids': resolved.finalSkillIds};
}

Future<Map<String, Object?>> _groupPlusDisabledCase({
  required ProjectAgentSkillLoadoutRepository repository,
  required ProjectAgentSkillRuntimeLoadoutService runtimeService,
  required ProjectDescriptor project,
  required JsonMap agent,
  required List<JsonMap> skillGroups,
  required List<String> availableSkillIds,
}) async {
  await repository.saveLoadouts(project, const <AgentSkillLoadout>[
    AgentSkillLoadout(
      agentId: 'default_generalist',
      source: AgentSkillLoadoutSource.projectSelection,
      skillGroupIds: <String>['combo_group'],
      disabledSkillIds: <String>['base_skill'],
    ),
  ]);
  final resolved = await runtimeService.resolveForAgent(
    project: project,
    agent: agent,
    availableSkillGroups: skillGroups,
    availableSkillIds: availableSkillIds,
  );
  final ok = _sameStringList(resolved.finalSkillIds, const <String>[
    'group_skill',
  ]);
  return <String, Object?>{
    'ok': ok,
    'final_skill_ids': resolved.finalSkillIds,
    'issues': resolved.issues.map((item) => item.code.name).toList(),
  };
}

Future<Map<String, Object?>> _historyRestoreCase({
  required ProjectAgentSkillLoadoutRepository repository,
  required app_services.ProjectSkillLoadoutWorkspaceService workspaceService,
  required ProjectDescriptor project,
}) async {
  await repository.saveLoadouts(project, const <AgentSkillLoadout>[
    AgentSkillLoadout(
      agentId: 'default_generalist',
      source: AgentSkillLoadoutSource.projectSelection,
      skillGroupIds: <String>['combo_group'],
    ),
  ]);
  var snapshot = await workspaceService.load(project);
  snapshot = workspaceService.toggleExtraSkill(
    snapshot,
    agentId: 'default_generalist',
    skillId: 'extra_skill',
    selected: true,
  );
  snapshot = await workspaceService.saveHistorySnapshot(
    project,
    snapshot,
    agentId: 'default_generalist',
    title: '带额外技能',
  );
  snapshot = workspaceService.toggleDisabledSkill(
    snapshot,
    agentId: 'default_generalist',
    skillId: 'base_skill',
    disabled: true,
  );
  snapshot = workspaceService.restoreHistoryEntry(
    snapshot,
    agentId: 'default_generalist',
    historyEntryId: snapshot.historyEntries.first.id,
  );
  final restoredDraft = snapshot.draftLoadouts['default_generalist'];
  final ok =
      restoredDraft != null &&
      restoredDraft.source == AgentSkillLoadoutSource.historyRestore &&
      _sameStringList(restoredDraft.extraSkillIds, const <String>[
        'extra_skill',
      ]) &&
      restoredDraft.disabledSkillIds.isEmpty;
  return <String, Object?>{
    'ok': ok,
    'draft_source': restoredDraft?.source.id ?? '',
    'draft_groups': restoredDraft?.skillGroupIds ?? const <String>[],
    'draft_extra_skills': restoredDraft?.extraSkillIds ?? const <String>[],
    'draft_disabled_skills':
        restoredDraft?.disabledSkillIds ?? const <String>[],
  };
}

Future<Map<String, Object?>> _saveAsGroupCase({
  required ProjectAgentSkillLoadoutRepository repository,
  required ProjectAgentSkillRuntimeLoadoutService runtimeService,
  required ProjectSkillLoadoutSaveAsGroupService saveAsGroupService,
  required ProjectDescriptor project,
  required JsonMap agent,
  required List<JsonMap> skillGroups,
  required List<String> availableSkillIds,
}) async {
  await repository.saveLoadouts(project, const <AgentSkillLoadout>[
    AgentSkillLoadout(
      agentId: 'default_generalist',
      source: AgentSkillLoadoutSource.projectSelection,
      skillGroupIds: <String>['combo_group'],
      extraSkillIds: <String>['extra_skill'],
      disabledSkillIds: <String>['base_skill'],
    ),
  ]);
  final resolved = await runtimeService.resolveForAgent(
    project: project,
    agent: agent,
    availableSkillGroups: skillGroups,
    availableSkillIds: availableSkillIds,
  );
  final relativePath = await saveAsGroupService.saveAsGroup(
    project: project,
    loadout: resolved,
    groupId: 'saved_probe_group',
    displayName: '探针技能组',
    description: '来自探针',
  );
  final groupFile = File(
    '${project.rootPath}${Platform.pathSeparator}${relativePath.replaceAll('/', Platform.pathSeparator)}',
  );
  final groupDocument = jsonDecode(await groupFile.readAsString()) as Map;
  final groupSkills = ValueReaders.stringList(groupDocument['skills']);
  final ok =
      relativePath == 'skill_groups/saved_probe_group/skill_group.json' &&
      _sameStringList(groupSkills, const <String>[
        'group_skill',
        'extra_skill',
      ]);
  return <String, Object?>{
    'ok': ok,
    'relative_path': relativePath,
    'saved_skills': groupSkills,
  };
}

Future<Map<String, Object?>> _projectSwitchIsolationCase({
  required ProjectAgentSkillLoadoutRepository repository,
  required ProjectAgentSkillRuntimeLoadoutService runtimeService,
  required app_services.ProjectSkillLoadoutWorkspaceService workspaceService,
  required ProjectDescriptor firstProject,
  required ProjectDescriptor secondProject,
  required JsonMap agent,
  required List<JsonMap> skillGroups,
  required List<String> availableSkillIds,
}) async {
  await repository.saveLoadouts(firstProject, const <AgentSkillLoadout>[
    AgentSkillLoadout(
      agentId: 'default_generalist',
      source: AgentSkillLoadoutSource.projectSelection,
      extraSkillIds: <String>['project_a_skill'],
      disabledSkillIds: <String>['base_skill'],
    ),
  ]);
  await repository.saveLoadouts(secondProject, const <AgentSkillLoadout>[
    AgentSkillLoadout(
      agentId: 'default_generalist',
      source: AgentSkillLoadoutSource.projectSelection,
      extraSkillIds: <String>['project_b_skill'],
      disabledSkillIds: <String>['base_skill'],
    ),
  ]);
  final firstResolved = await runtimeService.resolveForAgent(
    project: firstProject,
    agent: agent,
    availableSkillGroups: skillGroups,
    availableSkillIds: availableSkillIds,
  );
  final secondResolved = await runtimeService.resolveForAgent(
    project: secondProject,
    agent: agent,
    availableSkillGroups: skillGroups,
    availableSkillIds: availableSkillIds,
  );
  final firstSnapshot = await workspaceService.load(firstProject);
  final secondSnapshot = await workspaceService.load(secondProject);
  final ok =
      _sameStringList(firstResolved.finalSkillIds, const <String>[
        'project_a_skill',
      ]) &&
      _sameStringList(secondResolved.finalSkillIds, const <String>[
        'project_b_skill',
      ]) &&
      _sameStringList(
        firstSnapshot.savedLoadouts.single.extraSkillIds,
        const <String>['project_a_skill'],
      ) &&
      _sameStringList(
        secondSnapshot.savedLoadouts.single.extraSkillIds,
        const <String>['project_b_skill'],
      );
  return <String, Object?>{
    'ok': ok,
    'first_project_final_skills': firstResolved.finalSkillIds,
    'second_project_final_skills': secondResolved.finalSkillIds,
    'first_project_saved_extra':
        firstSnapshot.savedLoadouts.single.extraSkillIds,
    'second_project_saved_extra':
        secondSnapshot.savedLoadouts.single.extraSkillIds,
  };
}

bool _sameStringList(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
