import 'package:novel_agent_core/novel_agent_core.dart';

import '../models/project_assets_refresh_outcome.dart';
import '../models/project_assets_refresh_scope.dart';
import '../models/project_assets_snapshot.dart';
import '../models/project_rag_extraction_snapshot.dart';
import '../models/project_rag_extraction_execution_result.dart';
import 'project_assets_catalog_refresh_service.dart';
import 'project_assets_rag_refresh_service.dart';
import 'project_assets_refresh_status_projection_service.dart';
import 'project_assets_selection_reconciler.dart';

class ProjectAssetsRefreshCoordinator {
  ProjectAssetsRefreshCoordinator({
    required ProjectAssetsCatalogRefreshService catalogRefreshService,
    required ProjectAssetsRagRefreshService ragRefreshService,
    required ProjectAssetsSelectionReconciler selectionReconciler,
    required ProjectAssetsRefreshStatusProjectionService
    statusProjectionService,
  }) : _catalogRefreshService = catalogRefreshService,
       _ragRefreshService = ragRefreshService,
       _selectionReconciler = selectionReconciler,
       _statusProjectionService = statusProjectionService;

  final ProjectAssetsCatalogRefreshService _catalogRefreshService;
  final ProjectAssetsRagRefreshService _ragRefreshService;
  final ProjectAssetsSelectionReconciler _selectionReconciler;
  final ProjectAssetsRefreshStatusProjectionService _statusProjectionService;

  Future<ProjectAssetsRefreshOutcome> refreshAll({
    required ProjectDescriptor? currentProject,
    required ProjectAssetsSnapshot previousSnapshot,
    String? status,
  }) async {
    if (currentProject == null) {
      return ProjectAssetsRefreshOutcome(
        snapshot: ProjectAssetsSnapshot.initial(),
        statusMessage: status?.trim().isNotEmpty == true
            ? status!.trim()
            : '请先创建或打开项目。',
      );
    }
    try {
      final catalogResult = await _catalogRefreshService.refresh(
        currentProject,
      );
      var nextSnapshot = previousSnapshot.copyWith(
        catalog: catalogResult.catalog,
        availableAgentOptions: catalogResult.availableAgentOptions,
        availableModeOptions: catalogResult.availableModeOptions,
        availableStageOptions: catalogResult.availableStageOptions,
        isLoading: false,
      );
      nextSnapshot = _selectionReconciler.reconcile(
        project: currentProject,
        previous: nextSnapshot,
        catalog: catalogResult.catalog,
      );
      final ragResult = await _ragRefreshService.refresh(
        project: currentProject,
        selectedCorpusId: nextSnapshot.ragExtraction.selectedCorpusId,
      );
      nextSnapshot = nextSnapshot.copyWith(
        ragExtraction: _updateRagSnapshot(nextSnapshot, ragResult),
      );
      return ProjectAssetsRefreshOutcome(
        snapshot: nextSnapshot,
        statusMessage: _statusProjectionService.loadedMessage(
          ProjectAssetsRefreshScope.full,
          catalogResult.catalog,
          status: status,
        ),
      );
    } catch (error) {
      return ProjectAssetsRefreshOutcome(
        snapshot: previousSnapshot.copyWith(isLoading: false),
        statusMessage: _statusProjectionService.failureMessage(
          ProjectAssetsRefreshScope.full,
          error,
        ),
      );
    }
  }

  Future<ProjectAssetsRefreshOutcome> refreshCatalog({
    required ProjectDescriptor? currentProject,
    required ProjectAssetsSnapshot previousSnapshot,
    String? status,
  }) async {
    if (currentProject == null) {
      return ProjectAssetsRefreshOutcome(
        snapshot: ProjectAssetsSnapshot.initial(),
        statusMessage: status?.trim().isNotEmpty == true
            ? status!.trim()
            : '请先创建或打开项目。',
      );
    }
    try {
      final catalogResult = await _catalogRefreshService.refresh(
        currentProject,
      );
      var nextSnapshot = previousSnapshot.copyWith(
        catalog: catalogResult.catalog,
        availableAgentOptions: catalogResult.availableAgentOptions,
        availableModeOptions: catalogResult.availableModeOptions,
        availableStageOptions: catalogResult.availableStageOptions,
        isLoading: false,
      );
      nextSnapshot = _selectionReconciler.reconcile(
        project: currentProject,
        previous: nextSnapshot,
        catalog: catalogResult.catalog,
      );
      return ProjectAssetsRefreshOutcome(
        snapshot: nextSnapshot,
        statusMessage: _statusProjectionService.loadedMessage(
          ProjectAssetsRefreshScope.catalog,
          catalogResult.catalog,
          status: status,
        ),
      );
    } catch (error) {
      return ProjectAssetsRefreshOutcome(
        snapshot: previousSnapshot.copyWith(isLoading: false),
        statusMessage: _statusProjectionService.failureMessage(
          ProjectAssetsRefreshScope.catalog,
          error,
        ),
      );
    }
  }

  Future<ProjectAssetsRefreshOutcome> refreshRag({
    required ProjectDescriptor? currentProject,
    required ProjectAssetsSnapshot previousSnapshot,
    String? status,
  }) async {
    if (currentProject == null) {
      return ProjectAssetsRefreshOutcome(
        snapshot: ProjectAssetsSnapshot.initial(),
        statusMessage: status?.trim().isNotEmpty == true
            ? status!.trim()
            : '请先创建或打开项目。',
      );
    }
    try {
      final ragResult = await _ragRefreshService.refresh(
        project: currentProject,
        selectedCorpusId: previousSnapshot.ragExtraction.selectedCorpusId,
      );
      final nextSnapshot = previousSnapshot.copyWith(
        ragExtraction: _updateRagSnapshot(previousSnapshot, ragResult),
        isLoading: false,
      );
      return ProjectAssetsRefreshOutcome(
        snapshot: nextSnapshot,
        statusMessage: _statusProjectionService.loadedMessage(
          ProjectAssetsRefreshScope.rag,
          nextSnapshot.catalog,
          status: status,
        ),
      );
    } catch (error) {
      return ProjectAssetsRefreshOutcome(
        snapshot: previousSnapshot.copyWith(isLoading: false),
        statusMessage: _statusProjectionService.failureMessage(
          ProjectAssetsRefreshScope.rag,
          error,
        ),
      );
    }
  }

  ProjectRagExtractionSnapshot _updateRagSnapshot(
    ProjectAssetsSnapshot previousSnapshot,
    ProjectRagExtractionExecutionResult result,
  ) {
    return previousSnapshot.ragExtraction.copyWith(
      selectedCorpusId:
          result.corpusPackage?.corpusId ??
          previousSnapshot.ragExtraction.selectedCorpusId,
      selectedCorpus:
          result.corpusPackage ?? previousSnapshot.ragExtraction.selectedCorpus,
      mountSummary:
          result.mountSummary ?? previousSnapshot.ragExtraction.mountSummary,
      analysisSummary:
          result.analysisSummary ??
          previousSnapshot.ragExtraction.analysisSummary,
      normalizationNote: result.normalizationNote.trim().isNotEmpty
          ? result.normalizationNote
          : previousSnapshot.ragExtraction.normalizationNote,
      statusMessage: result.statusMessage,
      recentSourcePath:
          result.corpusPackage?.metadata['source_file_path']?.toString() ??
          previousSnapshot.ragExtraction.recentSourcePath,
    );
  }
}
