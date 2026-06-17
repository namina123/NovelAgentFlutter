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
    final phases = <ProjectCreationPhase>[
      ProjectCreationPhase.projectType,
      if (usesBookDeconstructionFollowup(projectTypeId))
        ProjectCreationPhase.bookDeconstructionFollowup,
      ProjectCreationPhase.storageStrategy,
      if (requiresRuntimeBaselineSelection)
        ProjectCreationPhase.runtimeBaseline,
    ];
    return phases;
  }

  ProjectCreationPhase nextPhaseAfterProjectType({
    required String projectTypeId,
    required bool requiresRuntimeBaselineSelection,
  }) {
    return nextPhaseAfter(
          currentPhase: ProjectCreationPhase.projectType,
          projectTypeId: projectTypeId,
          requiresRuntimeBaselineSelection: requiresRuntimeBaselineSelection,
        ) ??
        ProjectCreationPhase.storageStrategy;
  }

  ProjectCreationPhase? nextPhaseAfter({
    required ProjectCreationPhase currentPhase,
    required String projectTypeId,
    required bool requiresRuntimeBaselineSelection,
  }) {
    final phases = phasesFor(
      projectTypeId: projectTypeId,
      requiresRuntimeBaselineSelection: requiresRuntimeBaselineSelection,
    );
    final currentIndex = phases.indexOf(currentPhase);
    if (currentIndex == -1 || currentIndex >= phases.length - 1) {
      return null;
    }
    return phases[currentIndex + 1];
  }

  ProjectCreationPhase? previousPhaseBefore({
    required ProjectCreationPhase currentPhase,
    required String projectTypeId,
    required bool requiresRuntimeBaselineSelection,
  }) {
    final phases = phasesFor(
      projectTypeId: projectTypeId,
      requiresRuntimeBaselineSelection: requiresRuntimeBaselineSelection,
    );
    final currentIndex = phases.indexOf(currentPhase);
    if (currentIndex <= 0) {
      return null;
    }
    return phases[currentIndex - 1];
  }

  bool isFinalPhase({
    required ProjectCreationPhase currentPhase,
    required String projectTypeId,
    required bool requiresRuntimeBaselineSelection,
  }) {
    final phases = phasesFor(
      projectTypeId: projectTypeId,
      requiresRuntimeBaselineSelection: requiresRuntimeBaselineSelection,
    );
    return phases.isNotEmpty && phases.last == currentPhase;
  }
}
