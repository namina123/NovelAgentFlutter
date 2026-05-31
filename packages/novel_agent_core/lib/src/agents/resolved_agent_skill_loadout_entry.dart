import 'resolved_agent_skill_loadout_entry_source.dart';

class ResolvedAgentSkillLoadoutEntry {
  const ResolvedAgentSkillLoadoutEntry({
    required this.skillId,
    required this.sources,
    this.enabled = true,
    this.disabledByLoadout = false,
    this.available = true,
  });

  final String skillId;
  final List<ResolvedAgentSkillLoadoutEntrySource> sources;
  final bool enabled;
  final bool disabledByLoadout;
  final bool available;

  ResolvedAgentSkillLoadoutEntry copyWith({
    List<ResolvedAgentSkillLoadoutEntrySource>? sources,
    bool? enabled,
    bool? disabledByLoadout,
    bool? available,
  }) {
    return ResolvedAgentSkillLoadoutEntry(
      skillId: skillId,
      sources: sources ?? this.sources,
      enabled: enabled ?? this.enabled,
      disabledByLoadout: disabledByLoadout ?? this.disabledByLoadout,
      available: available ?? this.available,
    );
  }
}
