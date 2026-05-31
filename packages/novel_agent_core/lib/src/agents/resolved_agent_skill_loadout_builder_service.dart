import 'agent_profile.dart';
import 'agent_skill_loadout.dart';
import 'agent_skill_loadout_scope.dart';
import 'agent_skill_loadout_source.dart';
import 'agent_string_list_service.dart';
import 'resolved_agent_skill_loadout.dart';

class ResolvedAgentSkillLoadoutBuilderService {
  ResolvedAgentSkillLoadoutBuilderService({
    AgentStringListService? stringListService,
  }) : _stringListService = stringListService ?? AgentStringListService();

  final AgentStringListService _stringListService;

  ResolvedAgentSkillLoadout build({
    required AgentProfile profile,
    AgentSkillLoadout? loadout,
  }) {
    // 中文注释: 这里只把 profile 默认声明和当前 loadout 叠成稳定合同，不负责展开技能组或应用禁用策略。
    final profileSkillIds = _stringListService.normalize(profile.skills);
    final profileSkillGroupIds = _stringListService.normalize(profile.skillGroups);
    final appliedLoadout = _resolveLoadout(profile, loadout);
    return ResolvedAgentSkillLoadout(
      agentId: profile.id,
      source: appliedLoadout?.source ?? AgentSkillLoadoutSource.agentDefault,
      scope: appliedLoadout?.scope ?? const AgentSkillLoadoutScope(),
      profileSkillIds: profileSkillIds,
      profileSkillGroupIds: profileSkillGroupIds,
      selectedDirectSkillIds: _stringListService.normalize(
        appliedLoadout?.extraSkillIds ?? const <String>[],
      ),
      selectedSkillGroupIds: _stringListService.normalize(
        appliedLoadout?.skillGroupIds ?? const <String>[],
      ),
      disabledSkillIds: _stringListService.normalize(
        appliedLoadout?.disabledSkillIds ?? const <String>[],
      ),
      metadata: appliedLoadout?.metadata ?? const <String, Object?>{},
    );
  }

  AgentSkillLoadout? _resolveLoadout(
    AgentProfile profile,
    AgentSkillLoadout? loadout,
  ) {
    if (loadout == null) {
      return null;
    }
    if (!loadout.appliesToAgent(profile.id)) {
      return null;
    }
    return loadout;
  }
}
