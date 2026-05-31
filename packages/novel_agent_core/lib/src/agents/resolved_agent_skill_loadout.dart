import 'agent_skill_loadout_scope.dart';
import 'agent_skill_loadout_source.dart';
import 'agent_skill_loadout_issue.dart';
import 'resolved_agent_skill_loadout_entry.dart';

class ResolvedAgentSkillLoadout {
  const ResolvedAgentSkillLoadout({
    required this.agentId,
    required this.source,
    required this.scope,
    this.profileSkillIds = const <String>[],
    this.profileSkillGroupIds = const <String>[],
    this.selectedDirectSkillIds = const <String>[],
    this.selectedSkillGroupIds = const <String>[],
    this.disabledSkillIds = const <String>[],
    this.entries = const <ResolvedAgentSkillLoadoutEntry>[],
    this.issues = const <AgentSkillLoadoutIssue>[],
    this.metadata = const <String, Object?>{},
  });

  final String agentId;
  final AgentSkillLoadoutSource source;
  final AgentSkillLoadoutScope scope;
  final List<String> profileSkillIds;
  final List<String> profileSkillGroupIds;
  final List<String> selectedDirectSkillIds;
  final List<String> selectedSkillGroupIds;
  final List<String> disabledSkillIds;
  final List<ResolvedAgentSkillLoadoutEntry> entries;
  final List<AgentSkillLoadoutIssue> issues;
  final Map<String, Object?> metadata;

  bool get hasProfileDefaults =>
      profileSkillIds.isNotEmpty || profileSkillGroupIds.isNotEmpty;

  List<String> get finalSkillIds => entries
      .where((entry) => entry.enabled)
      .map((entry) => entry.skillId)
      .toList(growable: false);

  bool get hasExplicitLoadout =>
      source != AgentSkillLoadoutSource.agentDefault ||
      disabledSkillIds.isNotEmpty ||
      selectedDirectSkillIds.isNotEmpty ||
      selectedSkillGroupIds.isNotEmpty;

  ResolvedAgentSkillLoadout copyWith({
    AgentSkillLoadoutSource? source,
    AgentSkillLoadoutScope? scope,
    List<String>? profileSkillIds,
    List<String>? profileSkillGroupIds,
    List<String>? selectedDirectSkillIds,
    List<String>? selectedSkillGroupIds,
    List<String>? disabledSkillIds,
    List<ResolvedAgentSkillLoadoutEntry>? entries,
    List<AgentSkillLoadoutIssue>? issues,
    Map<String, Object?>? metadata,
  }) {
    return ResolvedAgentSkillLoadout(
      agentId: agentId,
      source: source ?? this.source,
      scope: scope ?? this.scope,
      profileSkillIds: profileSkillIds ?? this.profileSkillIds,
      profileSkillGroupIds: profileSkillGroupIds ?? this.profileSkillGroupIds,
      selectedDirectSkillIds:
          selectedDirectSkillIds ?? this.selectedDirectSkillIds,
      selectedSkillGroupIds:
          selectedSkillGroupIds ?? this.selectedSkillGroupIds,
      disabledSkillIds: disabledSkillIds ?? this.disabledSkillIds,
      entries: entries ?? this.entries,
      issues: issues ?? this.issues,
      metadata: metadata ?? this.metadata,
    );
  }
}
