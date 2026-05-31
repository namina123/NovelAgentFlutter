import 'agent_skill_loadout_issue.dart';
import 'resolved_agent_skill_loadout_entry.dart';

class SkillLoadoutExpansion {
  const SkillLoadoutExpansion({
    this.entries = const <ResolvedAgentSkillLoadoutEntry>[],
    this.issues = const <AgentSkillLoadoutIssue>[],
  });

  final List<ResolvedAgentSkillLoadoutEntry> entries;
  final List<AgentSkillLoadoutIssue> issues;
}
