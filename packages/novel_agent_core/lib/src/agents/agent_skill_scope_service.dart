import '../common/json_types.dart';
import 'agent_skill_loadout_resolver_service.dart';

class AgentSkillScopeService {
  AgentSkillScopeService({
    AgentSkillLoadoutResolverService? loadoutResolverService,
  }) : _loadoutResolverService =
           loadoutResolverService ?? AgentSkillLoadoutResolverService();

  final AgentSkillLoadoutResolverService _loadoutResolverService;

  List<String> declaredSkillIds(
    JsonMap agent, {
    List<Object?> availableSkillGroups = const <Object?>[],
  }) {
    // 中文注释: 这里保留兼容 facade，只返回“按默认声明解析后”的最终技能集合。
    if (agent.isEmpty) {
      return const <String>[];
    }
    final resolved = _loadoutResolverService.resolveAgentDocument(
      agent,
      availableSkillGroups: availableSkillGroups,
    );
    return resolved.finalSkillIds;
  }

  List<String> enabledSkillIds(
    JsonMap agent, {
    List<Object?> availableSkillGroups = const <Object?>[],
    List<String> availableSkillIds = const <String>[],
  }) {
    // 中文注释: enabledSkillIds 继续作为兼容入口，但真正的展开、去重和诊断已经下沉到 loadout resolver。
    final resolved = _loadoutResolverService.resolveAgentDocument(
      agent,
      availableSkillGroups: availableSkillGroups,
      availableSkillIds: availableSkillIds,
    );
    return resolved.finalSkillIds;
  }
}
