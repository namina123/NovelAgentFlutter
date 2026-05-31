import 'agent_skill_loadout_scope.dart';
import 'agent_skill_loadout_source.dart';

class AgentSkillLoadout {
  const AgentSkillLoadout({
    required this.agentId,
    this.source = AgentSkillLoadoutSource.projectSelection,
    this.scope = const AgentSkillLoadoutScope(),
    this.skillGroupIds = const <String>[],
    this.extraSkillIds = const <String>[],
    this.disabledSkillIds = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final String agentId;
  final AgentSkillLoadoutSource source;
  final AgentSkillLoadoutScope scope;
  final List<String> skillGroupIds;
  final List<String> extraSkillIds;
  final List<String> disabledSkillIds;
  final Map<String, Object?> metadata;

  bool get isEmpty =>
      skillGroupIds.isEmpty &&
      extraSkillIds.isEmpty &&
      disabledSkillIds.isEmpty;

  bool appliesToAgent(String candidateAgentId) {
    return agentId.trim().isNotEmpty && agentId.trim() == candidateAgentId.trim();
  }
}
