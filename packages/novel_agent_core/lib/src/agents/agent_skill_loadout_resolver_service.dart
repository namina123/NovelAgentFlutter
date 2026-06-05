import '../common/json_types.dart';
import 'agent_profile.dart';
import 'agent_profile_mapper_service.dart';
import 'agent_skill_loadout.dart';
import 'resolved_agent_skill_loadout.dart';
import 'resolved_agent_skill_loadout_builder_service.dart';
import 'skill_loadout_conflict_policy_service.dart';
import 'skill_loadout_expansion_service.dart';

class AgentSkillLoadoutResolverService {
  AgentSkillLoadoutResolverService({
    ResolvedAgentSkillLoadoutBuilderService? builderService,
    SkillLoadoutExpansionService? expansionService,
    SkillLoadoutConflictPolicyService? conflictPolicyService,
    AgentProfileMapperService? agentProfileMapperService,
  }) : _builderService =
           builderService ?? ResolvedAgentSkillLoadoutBuilderService(),
       _expansionService = expansionService ?? SkillLoadoutExpansionService(),
       _conflictPolicyService =
           conflictPolicyService ?? SkillLoadoutConflictPolicyService(),
       _agentProfileMapperService =
           agentProfileMapperService ?? const AgentProfileMapperService();

  final ResolvedAgentSkillLoadoutBuilderService _builderService;
  final SkillLoadoutExpansionService _expansionService;
  final SkillLoadoutConflictPolicyService _conflictPolicyService;
  final AgentProfileMapperService _agentProfileMapperService;

  ResolvedAgentSkillLoadout resolve({
    required AgentProfile profile,
    AgentSkillLoadout? loadout,
    List<Object?> availableSkillGroups = const <Object?>[],
    List<String> availableSkillIds = const <String>[],
    List<Object?> availableSkills = const <Object?>[],
    JsonMap toolPermissionProfile = const <String, Object?>{},
  }) {
    // 中文注释: resolver 作为薄编排层，把 build -> expand -> conflict 三步串起来，不在这里埋额外规则。
    final contract = _builderService.build(profile: profile, loadout: loadout);
    final expansion = _expansionService.expand(
      contract,
      availableSkillGroups: availableSkillGroups,
    );
    final conflictResult = _conflictPolicyService.apply(
      loadout: contract,
      expansion: expansion,
      availableSkillIds: availableSkillIds,
      availableSkills: availableSkills,
      toolPermissionProfile: toolPermissionProfile,
      agent: _agentProfileMapperService.toDocument(profile),
    );
    return contract.copyWith(
      entries: conflictResult.entries,
      issues: conflictResult.issues,
    );
  }

  ResolvedAgentSkillLoadout resolveAgentDocument(
    JsonMap agent, {
    AgentSkillLoadout? loadout,
    List<Object?> availableSkillGroups = const <Object?>[],
    List<String> availableSkillIds = const <String>[],
    List<Object?> availableSkills = const <Object?>[],
    JsonMap toolPermissionProfile = const <String, Object?>{},
  }) {
    return resolve(
      profile: _agentProfileMapperService.fromDocument(agent),
      loadout: loadout,
      availableSkillGroups: availableSkillGroups,
      availableSkillIds: availableSkillIds,
      availableSkills: availableSkills,
      toolPermissionProfile: toolPermissionProfile,
    );
  }
}
