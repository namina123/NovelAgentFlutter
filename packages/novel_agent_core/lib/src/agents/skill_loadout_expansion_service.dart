import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'agent_skill_loadout_issue.dart';
import 'agent_skill_loadout_issue_code.dart';
import 'builtin_skill_group_catalog_service.dart';
import 'resolved_agent_skill_loadout.dart';
import 'resolved_agent_skill_loadout_entry.dart';
import 'resolved_agent_skill_loadout_entry_source.dart';
import 'resolved_agent_skill_loadout_entry_source_kind.dart';
import 'skill_loadout_expansion.dart';

class SkillLoadoutExpansionService {
  SkillLoadoutExpansionService({
    BuiltinSkillGroupCatalogService? skillGroupCatalogService,
  }) : _skillGroupCatalogService =
           skillGroupCatalogService ?? const BuiltinSkillGroupCatalogService();

  final BuiltinSkillGroupCatalogService _skillGroupCatalogService;

  SkillLoadoutExpansion expand(
    ResolvedAgentSkillLoadout loadout, {
    List<Object?> availableSkillGroups = const <Object?>[],
  }) {
    // 中文注释: 这里只负责把 direct skill 与 skill group 展开成候选技能条目，不负责可用性过滤或禁用裁剪。
    final issues = <AgentSkillLoadoutIssue>[];
    final entryMap = <String, ResolvedAgentSkillLoadoutEntry>{};
    final groups = _mergedSkillGroups(availableSkillGroups);

    for (final skillId in loadout.profileSkillIds) {
      _appendEntry(
        entryMap,
        skillId: skillId,
        source: const ResolvedAgentSkillLoadoutEntrySource(
          kind: ResolvedAgentSkillLoadoutEntrySourceKind.profileDirectSkill,
          referenceId: '',
        ),
      );
    }
    for (final groupId in loadout.profileSkillGroupIds) {
      final expanded = _expandGroup(groupId, groups: groups);
      if (expanded.isEmpty) {
        issues.add(
          AgentSkillLoadoutIssue(
            code: AgentSkillLoadoutIssueCode.missingSkillGroup,
            subjectId: groupId,
          ),
        );
        continue;
      }
      for (final skillId in expanded) {
        _appendEntry(
          entryMap,
          skillId: skillId,
          source: ResolvedAgentSkillLoadoutEntrySource(
            kind: ResolvedAgentSkillLoadoutEntrySourceKind.profileSkillGroup,
            referenceId: groupId,
          ),
        );
      }
    }
    for (final groupId in loadout.selectedSkillGroupIds) {
      final expanded = _expandGroup(groupId, groups: groups);
      if (expanded.isEmpty) {
        issues.add(
          AgentSkillLoadoutIssue(
            code: AgentSkillLoadoutIssueCode.missingSkillGroup,
            subjectId: groupId,
          ),
        );
        continue;
      }
      for (final skillId in expanded) {
        _appendEntry(
          entryMap,
          skillId: skillId,
          source: ResolvedAgentSkillLoadoutEntrySource(
            kind: ResolvedAgentSkillLoadoutEntrySourceKind.loadoutSkillGroup,
            referenceId: groupId,
          ),
        );
      }
    }
    for (final skillId in loadout.selectedDirectSkillIds) {
      _appendEntry(
        entryMap,
        skillId: skillId,
        source: const ResolvedAgentSkillLoadoutEntrySource(
          kind: ResolvedAgentSkillLoadoutEntrySourceKind.loadoutDirectSkill,
          referenceId: '',
        ),
      );
    }

    return SkillLoadoutExpansion(
      entries: entryMap.values.toList(growable: false),
      issues: List<AgentSkillLoadoutIssue>.unmodifiable(issues),
    );
  }

  List<JsonMap> _mergedSkillGroups(List<Object?> availableSkillGroups) {
    final byId = <String, JsonMap>{};
    for (final group in _skillGroupCatalogService.builtinGroups()) {
      final id = ValueReaders.stringValue(group['id']).trim();
      if (id.isNotEmpty) {
        byId[id] = group;
      }
    }
    for (final rawGroup in availableSkillGroups) {
      final group = ValueReaders.mapValue(rawGroup);
      final id = ValueReaders.stringValue(group['id']).trim();
      if (id.isNotEmpty) {
        byId[id] = group;
      }
    }
    return byId.values.toList(growable: false);
  }

  List<String> _expandGroup(
    String groupId, {
    required List<Object?> groups,
  }) {
    return _skillGroupCatalogService.skillIdsForGroup(groupId, groups: groups);
  }

  void _appendEntry(
    Map<String, ResolvedAgentSkillLoadoutEntry> entryMap, {
    required String skillId,
    required ResolvedAgentSkillLoadoutEntrySource source,
  }) {
    final cleanId = skillId.trim();
    if (cleanId.isEmpty) {
      return;
    }
    final existing = entryMap[cleanId];
    if (existing == null) {
      entryMap[cleanId] = ResolvedAgentSkillLoadoutEntry(
        skillId: cleanId,
        sources: <ResolvedAgentSkillLoadoutEntrySource>[source],
      );
      return;
    }
    final nextSources = <ResolvedAgentSkillLoadoutEntrySource>[
      ...existing.sources,
    ];
    final duplicate = nextSources.any(
      (candidate) =>
          candidate.kind == source.kind &&
          candidate.referenceId == source.referenceId,
    );
    if (!duplicate) {
      nextSources.add(source);
    }
    entryMap[cleanId] = existing.copyWith(sources: nextSources);
  }
}
