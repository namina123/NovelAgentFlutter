import '../../presentation/models/project_creation_phase.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectCreationPhaseResolverService {
  const ProjectCreationPhaseResolverService();

  bool usesKnowledgeBaseBranch(String projectTypeId) {
    return const KnowledgeBaseBranchCatalogService().usesBranchSelection(
      projectTypeId,
    );
  }

  bool usesBookDeconstructionFollowup(String projectTypeId) {
    return projectTypeId.trim() == 'book_deconstruction';
  }

  /// 是否需要独立的“主存储策略”向导步。
  ///
  /// 默认不再把 Markdown/SQLite 决策硬塞给每个用户；仅当显式要求高级配置时展示。
  /// 单策略类型（如资料知识库）永远不需要这一步。
  bool usesStorageStrategyPhase(
    String projectTypeId, {
    bool includeStorageStrategyPhase = false,
  }) {
    final definition = const ProjectTypeCatalogService().definitionOf(
      projectTypeId,
    );
    if (definition.supportedStorageStrategies.length <= 1) {
      return false;
    }
    return includeStorageStrategyPhase;
  }

  ProjectStorageStrategy defaultStorageStrategy(String projectTypeId) {
    final definition = const ProjectTypeCatalogService().definitionOf(
      projectTypeId,
    );
    final supported = definition.supportedStorageStrategies;
    if (supported.isEmpty) {
      return ProjectStorageStrategy.markdownProjectStore;
    }
    if (supported.contains(ProjectStorageStrategy.markdownProjectStore)) {
      return ProjectStorageStrategy.markdownProjectStore;
    }
    return supported.first;
  }

  List<ProjectCreationPhase> phasesFor({
    required String projectTypeId,
    required bool requiresRuntimeBaselineSelection,
    bool includeStorageStrategyPhase = false,
  }) {
    final phases = <ProjectCreationPhase>[
      ProjectCreationPhase.projectType,
      if (usesKnowledgeBaseBranch(projectTypeId))
        ProjectCreationPhase.knowledgeBaseBranch,
      if (usesBookDeconstructionFollowup(projectTypeId))
        ProjectCreationPhase.bookDeconstructionFollowup,
      if (usesStorageStrategyPhase(
        projectTypeId,
        includeStorageStrategyPhase: includeStorageStrategyPhase,
      ))
        ProjectCreationPhase.storageStrategy,
      if (requiresRuntimeBaselineSelection)
        ProjectCreationPhase.runtimeBaseline,
    ];
    return phases;
  }

  ProjectCreationPhase nextPhaseAfterProjectType({
    required String projectTypeId,
    required bool requiresRuntimeBaselineSelection,
    bool includeStorageStrategyPhase = false,
  }) {
    return nextPhaseAfter(
          currentPhase: ProjectCreationPhase.projectType,
          projectTypeId: projectTypeId,
          requiresRuntimeBaselineSelection: requiresRuntimeBaselineSelection,
          includeStorageStrategyPhase: includeStorageStrategyPhase,
        ) ??
        (requiresRuntimeBaselineSelection
            ? ProjectCreationPhase.runtimeBaseline
            : ProjectCreationPhase.projectType);
  }

  ProjectCreationPhase? nextPhaseAfter({
    required ProjectCreationPhase currentPhase,
    required String projectTypeId,
    required bool requiresRuntimeBaselineSelection,
    bool includeStorageStrategyPhase = false,
  }) {
    final phases = phasesFor(
      projectTypeId: projectTypeId,
      requiresRuntimeBaselineSelection: requiresRuntimeBaselineSelection,
      includeStorageStrategyPhase: includeStorageStrategyPhase,
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
    bool includeStorageStrategyPhase = false,
  }) {
    final phases = phasesFor(
      projectTypeId: projectTypeId,
      requiresRuntimeBaselineSelection: requiresRuntimeBaselineSelection,
      includeStorageStrategyPhase: includeStorageStrategyPhase,
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
    bool includeStorageStrategyPhase = false,
  }) {
    final phases = phasesFor(
      projectTypeId: projectTypeId,
      requiresRuntimeBaselineSelection: requiresRuntimeBaselineSelection,
      includeStorageStrategyPhase: includeStorageStrategyPhase,
    );
    return phases.isNotEmpty && phases.last == currentPhase;
  }
}
