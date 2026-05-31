import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectSkillLoadoutWorkspaceSnapshot {
  const ProjectSkillLoadoutWorkspaceSnapshot({
    required this.savedLoadouts,
    required this.draftLoadouts,
    required this.historyEntries,
    required this.isLoading,
  });

  final List<AgentSkillLoadout> savedLoadouts;
  final Map<String, AgentSkillLoadout> draftLoadouts;
  final List<AgentSkillLoadoutHistoryEntry> historyEntries;
  final bool isLoading;

  factory ProjectSkillLoadoutWorkspaceSnapshot.initial() {
    return const ProjectSkillLoadoutWorkspaceSnapshot(
      savedLoadouts: <AgentSkillLoadout>[],
      draftLoadouts: <String, AgentSkillLoadout>{},
      historyEntries: <AgentSkillLoadoutHistoryEntry>[],
      isLoading: false,
    );
  }

  ProjectSkillLoadoutWorkspaceSnapshot copyWith({
    List<AgentSkillLoadout>? savedLoadouts,
    Map<String, AgentSkillLoadout>? draftLoadouts,
    List<AgentSkillLoadoutHistoryEntry>? historyEntries,
    bool? isLoading,
  }) {
    return ProjectSkillLoadoutWorkspaceSnapshot(
      savedLoadouts: savedLoadouts ?? this.savedLoadouts,
      draftLoadouts: draftLoadouts ?? this.draftLoadouts,
      historyEntries: historyEntries ?? this.historyEntries,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
