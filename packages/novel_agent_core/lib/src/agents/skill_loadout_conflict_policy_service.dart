import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../tools/builtin_tool_catalog.dart';
import 'agent_skill_loadout_issue.dart';
import 'agent_skill_loadout_issue_code.dart';
import 'resolved_agent_skill_loadout.dart';
import 'resolved_agent_skill_loadout_entry.dart';
import 'skill_capability_catalog_service.dart';
import 'skill_capability_requirement_service.dart';
import 'skill_loadout_conflict_result.dart';
import 'skill_loadout_expansion.dart';
import 'tool_permission_profile_service.dart';

class SkillLoadoutConflictPolicyService {
  SkillLoadoutConflictPolicyService({
    List<String>? builtinToolIds,
    SkillCapabilityRequirementService? capabilityRequirementService,
    ToolPermissionProfileService? toolPermissionProfileService,
    SkillCapabilityCatalogService? capabilityCatalogService,
  }) : _builtinToolIds =
           builtinToolIds ??
           BuiltinToolCatalog.definitions
               .map((definition) => definition.id)
               .toList(growable: false),
       _capabilityRequirementService =
           capabilityRequirementService ?? SkillCapabilityRequirementService(),
       _toolPermissionProfileService =
           toolPermissionProfileService ?? ToolPermissionProfileService(),
       _capabilityCatalogService =
           capabilityCatalogService ?? const SkillCapabilityCatalogService();

  final List<String> _builtinToolIds;
  final SkillCapabilityRequirementService _capabilityRequirementService;
  final ToolPermissionProfileService _toolPermissionProfileService;
  final SkillCapabilityCatalogService _capabilityCatalogService;

  SkillLoadoutConflictResult apply({
    required ResolvedAgentSkillLoadout loadout,
    required SkillLoadoutExpansion expansion,
    List<String> availableSkillIds = const <String>[],
    List<Object?> availableSkills = const <Object?>[],
    JsonMap toolPermissionProfile = const <String, Object?>{},
    JsonMap agent = const <String, Object?>{},
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
    final compatibilityResult = _applyCapabilityCompatibility(
      entries: entries,
      issues: issues,
      availableSkills: availableSkills,
      toolPermissionProfile: toolPermissionProfile,
      agent: agent,
    );
    return SkillLoadoutConflictResult(
      entries: compatibilityResult.$1,
      issues: List<AgentSkillLoadoutIssue>.unmodifiable(compatibilityResult.$2),
    );
  }

  (List<ResolvedAgentSkillLoadoutEntry>, List<AgentSkillLoadoutIssue>) _applyCapabilityCompatibility({
    required List<ResolvedAgentSkillLoadoutEntry> entries,
    required List<AgentSkillLoadoutIssue> issues,
    required List<Object?> availableSkills,
    required JsonMap toolPermissionProfile,
    required JsonMap agent,
  }) {
    if (availableSkills.isEmpty) {
      return (entries, issues);
    }
    final requirementBySkillId = _capabilityRequirementService.indexBySkillId(
      availableSkills,
    );
    if (requirementBySkillId.isEmpty) {
      return (entries, issues);
    }
    final normalizedPermissionProfile = _toolPermissionProfileService.resolve(
      profile: toolPermissionProfile,
      agent: agent,
    );
    final grantedCapabilities = ValueReaders.stringList(
      normalizedPermissionProfile['granted_capabilities'],
    ).toSet();
    final nextIssues = <AgentSkillLoadoutIssue>[...issues];
    final nextEntries = entries.map((rawEntry) {
      final entry = rawEntry;
      if (!entry.enabled || !entry.available || entry.disabledByLoadout) {
        return entry;
      }
      final requirement = requirementBySkillId[entry.skillId];
      if (requirement == null || requirement.isEmpty) {
        return entry;
      }
      final missingRequired = ValueReaders.stringList(
        requirement['required_capabilities'],
      ).where((capabilityId) => !grantedCapabilities.contains(capabilityId)).toList(
        growable: false,
      );
      final missingOptional = ValueReaders.stringList(
        requirement['optional_capabilities'],
      ).where((capabilityId) => !grantedCapabilities.contains(capabilityId)).toList(
        growable: false,
      );
      final safeWithoutTools = ValueReaders.boolValue(
        requirement['safe_without_tools'],
        true,
      );
      if (missingRequired.isNotEmpty) {
        if (safeWithoutTools) {
          nextIssues.add(
            _capabilityIssue(
              code: AgentSkillLoadoutIssueCode.degradedCapabilityRequirement,
              requirement: requirement,
              missingCapabilities: missingRequired,
              permissionProfile: normalizedPermissionProfile,
              blocked: false,
            ),
          );
        } else {
          nextIssues.add(
            _capabilityIssue(
              code: AgentSkillLoadoutIssueCode.requiredCapabilityMissing,
              requirement: requirement,
              missingCapabilities: missingRequired,
              permissionProfile: normalizedPermissionProfile,
              blocked: true,
            ),
          );
          return entry.copyWith(enabled: false);
        }
      }
      if (missingOptional.isNotEmpty) {
        nextIssues.add(
          _capabilityIssue(
            code: AgentSkillLoadoutIssueCode.optionalCapabilityUnavailable,
            requirement: requirement,
            missingCapabilities: missingOptional,
            permissionProfile: normalizedPermissionProfile,
            blocked: false,
          ),
        );
      }
      return entry;
    }).toList(growable: false);
    return (nextEntries, nextIssues);
  }

  AgentSkillLoadoutIssue _capabilityIssue({
    required AgentSkillLoadoutIssueCode code,
    required JsonMap requirement,
    required List<String> missingCapabilities,
    required JsonMap permissionProfile,
    required bool blocked,
  }) {
    final skillId = ValueReaders.stringValue(requirement['id']).trim();
    final skillName = ValueReaders.stringValue(requirement['name'], skillId).trim();
    final sourceKind = ValueReaders.stringValue(
      requirement['source_kind'],
      'non_builtin',
    ).trim();
    final sourceLabel = _capabilityRequirementService.sourceLabel(sourceKind);
    final capabilityText = missingCapabilities
        .map(_capabilityCatalogService.displayLabel)
        .join('、');
    final permissionSummary = _toolPermissionProfileService.summaryLabel(
      permissionProfile,
    );
    final message = switch (code) {
      AgentSkillLoadoutIssueCode.requiredCapabilityMissing =>
        '$sourceLabel「$skillName」需要$capabilityText，但当前权限画像是$permissionSummary，已阻止装载。',
      AgentSkillLoadoutIssueCode.degradedCapabilityRequirement =>
        '$sourceLabel「$skillName」需要$capabilityText，但当前权限画像是$permissionSummary；已保留技能并降级为无工具流程指导。',
      AgentSkillLoadoutIssueCode.optionalCapabilityUnavailable =>
        '$sourceLabel「$skillName」可选使用$capabilityText，但当前权限画像是$permissionSummary；将继续使用受限路径。',
      _ => '',
    };
    return AgentSkillLoadoutIssue(
      code: code,
      subjectId: skillId,
      detailIds: missingCapabilities,
      message: message,
      metadata: <String, Object?>{
        'skill_name': skillName,
        'skill_source_kind': sourceKind == 'builtin' ? 'builtin' : 'non_builtin',
        'permission_profile_summary': permissionSummary,
        'blocked': blocked,
      },
    );
  }
}
