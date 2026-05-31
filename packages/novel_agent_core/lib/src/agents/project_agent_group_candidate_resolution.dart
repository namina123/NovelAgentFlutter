import 'project_agent_group_selection.dart';
import 'resolved_agent_group_profile.dart';

class ProjectAgentGroupCandidateResolution {
  const ProjectAgentGroupCandidateResolution({
    this.currentSelection,
    this.currentGroup,
    this.defaultGroup,
    this.derivedFromAgentBinding = false,
  });

  final ProjectAgentGroupSelection? currentSelection;
  final ResolvedAgentGroupProfile? currentGroup;
  final ResolvedAgentGroupProfile? defaultGroup;
  final bool derivedFromAgentBinding;
}
