import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/project_skill_loadout_workspace_snapshot.dart';

typedef LoadProjectSkillLoadouts =
    Future<List<AgentSkillLoadout>> Function(ProjectDescriptor project);
typedef SaveProjectSkillLoadouts =
    Future<void> Function(
      ProjectDescriptor project,
      List<AgentSkillLoadout> loadouts,
    );
typedef LoadProjectSkillLoadoutHistory =
    Future<List<AgentSkillLoadoutHistoryEntry>> Function(
      ProjectDescriptor project,
    );
typedef SaveProjectSkillLoadoutHistoryEntry =
    Future<void> Function(
      ProjectDescriptor project,
      AgentSkillLoadoutHistoryEntry entry,
    );
typedef SaveProjectSkillLoadoutAsGroup =
    Future<String> Function({
      required ProjectDescriptor project,
      required ResolvedAgentSkillLoadout loadout,
      required String groupId,
      required String displayName,
      required String description,
    });

class ProjectSkillLoadoutWorkspaceService {
  ProjectSkillLoadoutWorkspaceService({
    required LoadProjectSkillLoadouts loadLoadouts,
    required SaveProjectSkillLoadouts saveLoadouts,
    required LoadProjectSkillLoadoutHistory loadHistoryEntries,
    required SaveProjectSkillLoadoutHistoryEntry saveHistoryEntry,
    required SaveProjectSkillLoadoutAsGroup saveAsGroup,
    AgentIdService? idService,
  }) : _loadLoadouts = loadLoadouts,
       _saveLoadouts = saveLoadouts,
       _loadHistoryEntries = loadHistoryEntries,
       _saveHistoryEntry = saveHistoryEntry,
       _saveAsGroup = saveAsGroup,
       _idService = idService ?? AgentIdService();

  final LoadProjectSkillLoadouts _loadLoadouts;
  final SaveProjectSkillLoadouts _saveLoadouts;
  final LoadProjectSkillLoadoutHistory _loadHistoryEntries;
  final SaveProjectSkillLoadoutHistoryEntry _saveHistoryEntry;
  final SaveProjectSkillLoadoutAsGroup _saveAsGroup;
  final AgentIdService _idService;

  Future<ProjectSkillLoadoutWorkspaceSnapshot> load(
    ProjectDescriptor project,
  ) async {
    // 中文注释: 读侧统一在这里同时装载当前项目装载与历史快照，避免壳层自己拼仓储时序。
    final results = await Future.wait<Object>(<Future<Object>>[
      _loadLoadouts(project),
      _loadHistoryEntries(project),
    ]);
    final savedLoadouts = List<AgentSkillLoadout>.from(
      results[0] as List<AgentSkillLoadout>,
    );
    final historyEntries = List<AgentSkillLoadoutHistoryEntry>.from(
      results[1] as List<AgentSkillLoadoutHistoryEntry>,
    );
    final draftLoadouts = <String, AgentSkillLoadout>{
      for (final loadout in savedLoadouts) loadout.agentId: _copyLoadout(loadout),
    };
    return ProjectSkillLoadoutWorkspaceSnapshot(
      savedLoadouts: savedLoadouts,
      draftLoadouts: draftLoadouts,
      historyEntries: historyEntries,
      isLoading: false,
    );
  }

  AgentSkillLoadout draftForAgent(
    ProjectSkillLoadoutWorkspaceSnapshot snapshot,
    String agentId,
  ) {
    final cleanAgentId = agentId.trim();
    final existingDraft = snapshot.draftLoadouts[cleanAgentId];
    if (existingDraft != null) {
      return existingDraft;
    }
    for (final savedLoadout in snapshot.savedLoadouts) {
      if (savedLoadout.agentId == cleanAgentId) {
        return _copyLoadout(savedLoadout);
      }
    }
    return AgentSkillLoadout(
      agentId: cleanAgentId,
      source: AgentSkillLoadoutSource.projectSelection,
    );
  }

  ProjectSkillLoadoutWorkspaceSnapshot resetDraft(
    ProjectSkillLoadoutWorkspaceSnapshot snapshot,
    String agentId,
  ) {
    // 中文注释: 重置只回到已保存装载或空草稿，不触碰历史记录和其他智能体的草稿。
    final nextDrafts = Map<String, AgentSkillLoadout>.from(snapshot.draftLoadouts);
    final cleanAgentId = agentId.trim();
    final saved = snapshot.savedLoadouts.where((item) => item.agentId == cleanAgentId);
    if (saved.isEmpty) {
      nextDrafts.remove(cleanAgentId);
    } else {
      nextDrafts[cleanAgentId] = _copyLoadout(saved.first);
    }
    return snapshot.copyWith(draftLoadouts: nextDrafts);
  }

  ProjectSkillLoadoutWorkspaceSnapshot toggleSkillGroup(
    ProjectSkillLoadoutWorkspaceSnapshot snapshot, {
    required String agentId,
    required String groupId,
    required bool selected,
  }) {
    return _replaceDraft(
      snapshot,
      _copyLoadout(
        draftForAgent(snapshot, agentId),
        skillGroupIds: _toggleId(
          draftForAgent(snapshot, agentId).skillGroupIds,
          groupId,
          selected,
        ),
      ),
    );
  }

  ProjectSkillLoadoutWorkspaceSnapshot toggleExtraSkill(
    ProjectSkillLoadoutWorkspaceSnapshot snapshot, {
    required String agentId,
    required String skillId,
    required bool selected,
  }) {
    return _replaceDraft(
      snapshot,
      _copyLoadout(
        draftForAgent(snapshot, agentId),
        extraSkillIds: _toggleId(
          draftForAgent(snapshot, agentId).extraSkillIds,
          skillId,
          selected,
        ),
      ),
    );
  }

  ProjectSkillLoadoutWorkspaceSnapshot toggleDisabledSkill(
    ProjectSkillLoadoutWorkspaceSnapshot snapshot, {
    required String agentId,
    required String skillId,
    required bool disabled,
  }) {
    return _replaceDraft(
      snapshot,
      _copyLoadout(
        draftForAgent(snapshot, agentId),
        disabledSkillIds: _toggleId(
          draftForAgent(snapshot, agentId).disabledSkillIds,
          skillId,
          disabled,
        ),
      ),
    );
  }

  ProjectSkillLoadoutWorkspaceSnapshot restoreHistoryEntry(
    ProjectSkillLoadoutWorkspaceSnapshot snapshot, {
    required String agentId,
    required String historyEntryId,
  }) {
    // 中文注释: 历史恢复只更新当前智能体的草稿，不会在用户明确应用前直接改动已保存装载。
    for (final entry in snapshot.historyEntries) {
      if (entry.id != historyEntryId || entry.agentId != agentId) {
        continue;
      }
      return _replaceDraft(
        snapshot,
        _copyLoadout(
          entry.loadout,
          agentId: agentId,
          source: AgentSkillLoadoutSource.historyRestore,
        ),
      );
    }
    return snapshot;
  }

  Future<ProjectSkillLoadoutWorkspaceSnapshot> applyDraft(
    ProjectDescriptor project,
    ProjectSkillLoadoutWorkspaceSnapshot snapshot, {
    required String agentId,
  }) async {
    // 中文注释: 应用动作只落当前项目的正式 loadout 文档，不自动写历史，也不顺手资产化技能组。
    final appliedDraft = _normalizedDraft(draftForAgent(snapshot, agentId));
    final nextSavedLoadouts = <AgentSkillLoadout>[
      for (final loadout in snapshot.savedLoadouts)
        if (loadout.agentId != agentId) loadout,
      if (!appliedDraft.isEmpty) appliedDraft,
    ];
    await _saveLoadouts(project, nextSavedLoadouts);
    final nextDrafts = Map<String, AgentSkillLoadout>.from(snapshot.draftLoadouts);
    if (appliedDraft.isEmpty) {
      nextDrafts.remove(agentId);
    } else {
      nextDrafts[agentId] = _copyLoadout(appliedDraft);
    }
    return snapshot.copyWith(
      savedLoadouts: nextSavedLoadouts,
      draftLoadouts: nextDrafts,
    );
  }

  Future<ProjectSkillLoadoutWorkspaceSnapshot> saveHistorySnapshot(
    ProjectDescriptor project,
    ProjectSkillLoadoutWorkspaceSnapshot snapshot, {
    required String agentId,
    required String title,
  }) async {
    // 中文注释: 历史快照必须显式触发，保持和“当前装载保存”“另存为技能组”这两条路径分离。
    final cleanTitle = title.trim().isEmpty ? '未命名装载快照' : title.trim();
    final createdAt = DateTime.now().toUtc().toIso8601String();
    final entry = AgentSkillLoadoutHistoryEntry(
      id: '${_idService.safeAgentId(agentId)}_${DateTime.now().millisecondsSinceEpoch}',
      agentId: agentId,
      title: cleanTitle,
      createdAt: createdAt,
      loadout: _copyLoadout(
        _normalizedDraft(draftForAgent(snapshot, agentId)),
        source: AgentSkillLoadoutSource.historyRestore,
      ),
    );
    await _saveHistoryEntry(project, entry);
    return snapshot.copyWith(
      historyEntries: <AgentSkillLoadoutHistoryEntry>[
        entry,
        ...snapshot.historyEntries,
      ],
    );
  }

  Future<String> saveAsGroup({
    required ProjectDescriptor project,
    required ResolvedAgentSkillLoadout loadout,
    required String groupId,
    required String displayName,
    required String description,
  }) {
    // 中文注释: 另存为技能组仍复用 adapters 层的显式资产化入口，这层只转发用户确认后的参数。
    return _saveAsGroup(
      project: project,
      loadout: loadout,
      groupId: groupId,
      displayName: displayName,
      description: description,
    );
  }

  ProjectSkillLoadoutWorkspaceSnapshot _replaceDraft(
    ProjectSkillLoadoutWorkspaceSnapshot snapshot,
    AgentSkillLoadout nextDraft,
  ) {
    final nextDrafts = Map<String, AgentSkillLoadout>.from(snapshot.draftLoadouts);
    nextDrafts[nextDraft.agentId] = nextDraft;
    return snapshot.copyWith(draftLoadouts: nextDrafts);
  }

  List<String> _toggleId(List<String> source, String id, bool selected) {
    final cleanId = id.trim();
    final next = <String>[];
    for (final item in source) {
      final cleanItem = item.trim();
      if (cleanItem.isEmpty || cleanItem == cleanId || next.contains(cleanItem)) {
        continue;
      }
      next.add(cleanItem);
    }
    if (selected && cleanId.isNotEmpty && !next.contains(cleanId)) {
      next.add(cleanId);
    }
    return next;
  }

  AgentSkillLoadout _normalizedDraft(AgentSkillLoadout draft) {
    return _copyLoadout(
      draft,
      skillGroupIds: _dedupe(draft.skillGroupIds),
      extraSkillIds: _dedupe(draft.extraSkillIds),
      disabledSkillIds: _dedupe(draft.disabledSkillIds),
    );
  }

  List<String> _dedupe(List<String> values) {
    final result = <String>[];
    for (final value in values) {
      final cleanValue = value.trim();
      if (cleanValue.isEmpty || result.contains(cleanValue)) {
        continue;
      }
      result.add(cleanValue);
    }
    return result;
  }

  AgentSkillLoadout _copyLoadout(
    AgentSkillLoadout loadout, {
    String? agentId,
    AgentSkillLoadoutSource? source,
    AgentSkillLoadoutScope? scope,
    List<String>? skillGroupIds,
    List<String>? extraSkillIds,
    List<String>? disabledSkillIds,
    Map<String, Object?>? metadata,
  }) {
    return AgentSkillLoadout(
      agentId: agentId ?? loadout.agentId,
      source: source ?? loadout.source,
      scope: scope ?? loadout.scope,
      skillGroupIds: List<String>.from(skillGroupIds ?? loadout.skillGroupIds),
      extraSkillIds: List<String>.from(extraSkillIds ?? loadout.extraSkillIds),
      disabledSkillIds: List<String>.from(
        disabledSkillIds ?? loadout.disabledSkillIds,
      ),
      metadata: Map<String, Object?>.from(metadata ?? loadout.metadata),
    );
  }
}
