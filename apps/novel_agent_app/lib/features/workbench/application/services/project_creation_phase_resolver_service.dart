import '../../presentation/models/project_creation_phase.dart';

class ProjectCreationPhaseResolverService {
  const ProjectCreationPhaseResolverService();

  bool usesBookDeconstructionFollowup(String projectTypeId) {
    return projectTypeId.trim() == 'book_deconstruction';
  }

  List<ProjectCreationPhase> phasesFor({
    required String projectTypeId,
    required bool requiresRuntimeBaselineSelection,
  }) {
    if (usesBookDeconstructionFollowup(projectTypeId)) {
      return const <ProjectCreationPhase>[
        ProjectCreationPhase.projectType,
        ProjectCreationPhase.bookDeconstructionFollowup,
      ];
    }
    return <ProjectCreationPhase>[
      ProjectCreationPhase.projectType,
      ProjectCreationPhase.storageStrategy,
      if (requiresRuntimeBaselineSelection)
        ProjectCreationPhase.runtimeBaseline,
    ];
  }

  ProjectCreationPhase nextPhaseAfterProjectType({
    required String projectTypeId,
    required bool requiresRuntimeBaselineSelection,
  }) {
    if (usesBookDeconstructionFollowup(projectTypeId)) {
      return ProjectCreationPhase.bookDeconstructionFollowup;
    }
    return ProjectCreationPhase.storageStrategy;
  }
}
