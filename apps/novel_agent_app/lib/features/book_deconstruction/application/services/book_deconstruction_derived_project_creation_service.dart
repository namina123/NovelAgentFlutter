import 'package:novel_agent_core/novel_agent_core.dart';

import 'book_deconstruction_application_plan_materialization_service.dart';
import 'book_deconstruction_derived_project_runtime_baseline_resolver_service.dart';
import 'book_deconstruction_derived_project_storage_strategy_service.dart';
import 'book_deconstruction_followup_persistence_service.dart';
import 'book_deconstruction_narrative_persistence_service.dart';

class BookDeconstructionDerivedProjectCreationService {
  BookDeconstructionDerivedProjectCreationService({
    required CreateProjectWorkspaceUseCase createProjectWorkspaceUseCase,
    required WriteProjectTextFileUseCase writeProjectTextFileUseCase,
    required BookDeconstructionNarrativePersistenceService
    narrativePersistenceService,
    BookDeconstructionApplicationPlanMaterializationService?
    applicationPlanMaterializationService,
    BookDeconstructionFollowupPersistenceService? followupPersistenceService,
    BookDeconstructionDerivedProjectRuntimeBaselineResolverService?
    runtimeBaselineResolverService,
    BookDeconstructionDerivedProjectStorageStrategyService?
    storageStrategyService,
    BookDeconstructionNarrativePromotionService? narrativePromotionService,
  }) : _createProjectWorkspaceUseCase = createProjectWorkspaceUseCase,
       _writeProjectTextFileUseCase = writeProjectTextFileUseCase,
       _narrativePersistenceService = narrativePersistenceService,
       _applicationPlanMaterializationService =
           applicationPlanMaterializationService ??
           BookDeconstructionApplicationPlanMaterializationService(
             writeProjectTextFileUseCase: writeProjectTextFileUseCase,
           ),
       _followupPersistenceService =
           followupPersistenceService ??
           BookDeconstructionFollowupPersistenceService(
             writeProjectTextFileUseCase: writeProjectTextFileUseCase,
           ),
       _runtimeBaselineResolverService =
           runtimeBaselineResolverService ??
           const BookDeconstructionDerivedProjectRuntimeBaselineResolverService(),
       _storageStrategyService =
           storageStrategyService ??
           const BookDeconstructionDerivedProjectStorageStrategyService(),
       _narrativePromotionService =
           narrativePromotionService ??
           const BookDeconstructionNarrativePromotionService();

  final CreateProjectWorkspaceUseCase _createProjectWorkspaceUseCase;
  final WriteProjectTextFileUseCase _writeProjectTextFileUseCase;
  final BookDeconstructionNarrativePersistenceService
  _narrativePersistenceService;
  final BookDeconstructionApplicationPlanMaterializationService
  _applicationPlanMaterializationService;
  final BookDeconstructionFollowupPersistenceService
  _followupPersistenceService;
  final BookDeconstructionDerivedProjectRuntimeBaselineResolverService
  _runtimeBaselineResolverService;
  final BookDeconstructionDerivedProjectStorageStrategyService
  _storageStrategyService;
  final BookDeconstructionNarrativePromotionService _narrativePromotionService;

  Future<BookDeconstructionDerivedProjectCreationResult> execute({
    required String projectsRootPath,
    required ProjectDescriptor sourceProject,
    required BookDeconstructionDraftBuildResult buildResult,
    required Set<String> selectedItemIds,
    required String selectedFollowupOptionId,
  }) async {
    final derivedPlan =
        const BookDeconstructionDerivedProjectPlanBuilderService().build(
          input: buildResult.input,
          followupMenu: buildResult.followupMenu,
          followupOptionId: selectedFollowupOptionId,
          narrativeArtifacts: buildResult.narrativeArtifacts,
        );
    final runtimeBaselineId = _runtimeBaselineResolverService.resolve(
      targetProjectTypeId: derivedPlan.targetProjectTypeId,
      targetModeId: derivedPlan.targetModeId,
    );
    final creationPlan = _createProjectWorkspaceUseCase.prepare(
      ProjectCreateRequest(
        title: derivedPlan.suggestedProjectTitle,
        projectTypeId: derivedPlan.targetProjectTypeId,
        storageStrategy: _storageStrategyService.resolve(
          targetProjectTypeId: derivedPlan.targetProjectTypeId,
          preferredStrategy: sourceProject.storageStrategy,
        ),
        runtimeBaselineId: runtimeBaselineId,
      ),
    );
    final derivedProject = await _createProjectWorkspaceUseCase.executePrepared(
      projectsRootPath: projectsRootPath,
      plan: creationPlan,
    );

    final changedPaths = <String>[];
    changedPaths.addAll(
      await _applicationPlanMaterializationService.materialize(
        project: derivedProject,
        buildResult: buildResult,
        selectedItemIds: selectedItemIds,
      ),
    );
    final promotedNarrativeArtifacts = _narrativePromotionService.promote(
      analysisBundle: buildResult.narrativeArtifacts,
      promotedBy: 'book_deconstruction_derived_project_creation',
    );
    changedPaths.addAll(
      await _narrativePersistenceService.persist(
        project: derivedProject,
        narrativeArtifacts: promotedNarrativeArtifacts,
      ),
    );
    final followupResult = await _followupPersistenceService.persist(
      project: derivedProject,
      buildResult: buildResult,
      followupOptionId: selectedFollowupOptionId,
    );
    changedPaths.addAll(<String>[
      followupResult.planPath,
      followupResult.guidePath,
      ...followupResult.inheritedChapterPaths,
    ]);
    changedPaths.addAll(
      await _persistSourceDocuments(
        project: derivedProject,
        buildResult: buildResult,
      ),
    );
    return BookDeconstructionDerivedProjectCreationResult(
      project: derivedProject,
      preferredOpenPath: followupResult.guidePath,
      changedPaths: changedPaths.toSet().toList(growable: false),
    );
  }

  Future<List<String>> _persistSourceDocuments({
    required ProjectDescriptor project,
    required BookDeconstructionDraftBuildResult buildResult,
  }) async {
    final changedPaths = <String>[];
    for (
      var index = 0;
      index < buildResult.input.sourceDocuments.length;
      index++
    ) {
      final document = buildResult.input.sourceDocuments[index];
      final content = document.content.trim();
      if (content.isEmpty) {
        continue;
      }
      final relativePath = _sourceDocumentPath(document, index + 1);
      final title = document.title.trim().isEmpty
          ? '原作资料 ${index + 1}'
          : document.title.trim();
      final buffer = StringBuffer()
        ..writeln(title)
        ..writeln()
        ..write(content);
      await _writeProjectTextFileUseCase.execute(
        project: project,
        relativePath: relativePath,
        content: buffer.toString().trimRight(),
      );
      changedPaths.add(relativePath);
    }
    return changedPaths;
  }

  String _sourceDocumentPath(
    BookDeconstructionSourceDocument document,
    int index,
  ) {
    final safeTitle = _safeId(document.title);
    final suffix = safeTitle.isEmpty ? 'source_$index' : '${index}_$safeTitle';
    return 'sources/original/book_deconstruction_$suffix.md';
  }

  String _safeId(String value) {
    return value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }
}

class BookDeconstructionDerivedProjectCreationResult {
  const BookDeconstructionDerivedProjectCreationResult({
    required this.project,
    required this.preferredOpenPath,
    required this.changedPaths,
  });

  final ProjectDescriptor project;
  final String preferredOpenPath;
  final List<String> changedPaths;
}
