import 'agent_skill_loadout.dart';

class AgentSkillLoadoutHistoryEntry {
  const AgentSkillLoadoutHistoryEntry({
    required this.id,
    required this.agentId,
    required this.loadout,
    this.title = '',
    this.createdAt = '',
    this.metadata = const <String, Object?>{},
  });

  final String id;
  final String agentId;
  final AgentSkillLoadout loadout;
  final String title;
  final String createdAt;
  final Map<String, Object?> metadata;
}
