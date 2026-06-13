import '../agents/project_agent_group_selection.dart';
import '../agents/resolved_agent_group_profile.dart';
import 'reference_extraction_execution_profile.dart';

class ReferenceExtractionGroupResolution {
  const ReferenceExtractionGroupResolution({
    required this.selectedGroup,
    required this.resolutionKind,
    required this.executionProfile,
    this.selection = const ProjectAgentGroupSelection(groupId: ''),
  });

  final ResolvedAgentGroupProfile selectedGroup;
  final String resolutionKind;
  final ReferenceExtractionExecutionProfile executionProfile;
  final ProjectAgentGroupSelection selection;

  bool get usedTaskFamilyOverride =>
      selection.taskFamilyIds.contains(executionProfile.taskFamilyId);

  ReferenceExtractionGroupResolution copyWith({
    ResolvedAgentGroupProfile? selectedGroup,
    String? resolutionKind,
    ReferenceExtractionExecutionProfile? executionProfile,
    ProjectAgentGroupSelection? selection,
  }) {
    return ReferenceExtractionGroupResolution(
      selectedGroup: selectedGroup ?? this.selectedGroup,
      resolutionKind: resolutionKind ?? this.resolutionKind,
      executionProfile: executionProfile ?? this.executionProfile,
      selection: selection ?? this.selection,
    );
  }
}
