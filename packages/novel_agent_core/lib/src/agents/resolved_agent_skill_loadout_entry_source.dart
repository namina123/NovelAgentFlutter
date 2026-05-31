import 'resolved_agent_skill_loadout_entry_source_kind.dart';

class ResolvedAgentSkillLoadoutEntrySource {
  const ResolvedAgentSkillLoadoutEntrySource({
    required this.kind,
    required this.referenceId,
  });

  final ResolvedAgentSkillLoadoutEntrySourceKind kind;
  final String referenceId;
}
