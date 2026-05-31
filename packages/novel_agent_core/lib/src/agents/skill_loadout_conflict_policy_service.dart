import '../tools/builtin_tool_catalog.dart';
import 'agent_skill_loadout_issue.dart';
import 'agent_skill_loadout_issue_code.dart';
import 'resolved_agent_skill_loadout.dart';
import 'skill_loadout_conflict_result.dart';
import 'skill_loadout_expansion.dart';

class SkillLoadoutConflictPolicyService {
  SkillLoadoutConflictPolicyService({
    List<String>? builtinToolIds,
  }) : _builtinToolIds =
           builtinToolIds ??
           BuiltinToolCatalog.definitions
               .map((definition) => definition.id)
               .toList(growable: false);

  final List<String> _builtinToolIds;

  SkillLoadoutConflictResult apply({
    required ResolvedAgentSkillLoadout loadout,
    required SkillLoadoutExpansion expansion,
    List<String> availableSkillIds = const <String>[],
  }) {
    // 中文注释: 这里统一应用 builtin tool 过滤、可加载 skill 交集和 disabled skills，不再让调用方各自裁剪。
    final issues = <AgentSkillLoadoutIssue>[
      ...expansion.issues,
    ];
    final availableSet = availableSkillIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final disabledSet = loadout.disabledSkillIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final matchedDisabledIds = <String>{};
    final entries = expansion.entries.map((entry) {
      final skillId = entry.skillId;
      if (_builtinToolIds.contains(skillId)) {
        issues.add(
          AgentSkillLoadoutIssue(
            code: AgentSkillLoadoutIssueCode.builtinToolFiltered,
            subjectId: skillId,
          ),
        );
        return entry.copyWith(enabled: false, available: false);
      }
      if (availableSet.isNotEmpty && !availableSet.contains(skillId)) {
        issues.add(
          AgentSkillLoadoutIssue(
            code: AgentSkillLoadoutIssueCode.unavailableSkill,
            subjectId: skillId,
          ),
        );
        return entry.copyWith(enabled: false, available: false);
      }
      if (disabledSet.contains(skillId)) {
        matchedDisabledIds.add(skillId);
        return entry.copyWith(enabled: false, disabledByLoadout: true);
      }
      return entry;
    }).toList(growable: false);
    for (final disabledSkillId in disabledSet) {
      if (matchedDisabledIds.contains(disabledSkillId)) {
        continue;
      }
      issues.add(
        AgentSkillLoadoutIssue(
          code: AgentSkillLoadoutIssueCode.disabledSkillMissingTarget,
          subjectId: disabledSkillId,
        ),
      );
    }
    return SkillLoadoutConflictResult(
      entries: entries,
      issues: List<AgentSkillLoadoutIssue>.unmodifiable(issues),
    );
  }
}
