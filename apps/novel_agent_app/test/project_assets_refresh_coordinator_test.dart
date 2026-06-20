import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_catalog.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_catalog_refresh_result.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_snapshot.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_tab_id.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_rag_analysis_summary.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_rag_extraction_execution_result.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_catalog_refresh_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_loader_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_rag_refresh_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_refresh_coordinator.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_refresh_status_projection_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_selection_reconciler.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_view_data_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_expression_constraint_workspace_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_rag_extraction_execution_service.dart';
import 'package:novel_agent_app/features/project_assets/presentation/models/project_assets_view_data.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  group('ProjectAssetsRefreshCoordinator', () {
    test('refreshAll calls catalog and rag sources once', () async {
      final catalogService = _FakeCatalogRefreshService(
        result: ProjectAssetsCatalogRefreshResult(
          catalog: const ProjectAssetsCatalog(),
          availableAgentOptions:
              const <ExpressionConstraintSelectableOptionViewData>[],
          availableModeOptions:
              const <ExpressionConstraintSelectableOptionViewData>[],
          availableStageOptions:
              const <ExpressionConstraintSelectableOptionViewData>[],
          statusMessage: 'catalog loaded',
        ),
      );
      final ragService = _FakeRagRefreshService(
        result: const ProjectRagExtractionExecutionResult(
          ok: true,
          didMutateProject: false,
          statusMessage: 'rag loaded',
          normalizationNote: '已先整理源文。',
          analysisSummary: ProjectRagAnalysisSummary(
            storyOutlineSummary: '总纲摘要',
            premiseSummary: '前提摘要',
            styleSummary: '风格摘要',
            chapterTitles: <String>['第一章'],
            characterNames: <String>['林砚'],
            organizationNames: <String>['黑潮议会'],
            worldRuleTitles: <String>['原文推断世界规则'],
            relationshipPairs: <String>['林砚 / 黑潮议会'],
            timelineLabels: <String>['第一章'],
            foreshadowTitles: <String>['第一章 的潜在线索'],
          ),
        ),
      );
      final coordinator = ProjectAssetsRefreshCoordinator(
        catalogRefreshService: catalogService,
        ragRefreshService: ragService,
        selectionReconciler: const ProjectAssetsSelectionReconciler(),
        statusProjectionService:
            const ProjectAssetsRefreshStatusProjectionService(),
      );

      final outcome = await coordinator.refreshAll(
        currentProject: const ProjectDescriptor(
          id: 'project_a',
          name: '测试项目',
          rootPath: 'D:/Projects/demo',
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        ),
        previousSnapshot: ProjectAssetsSnapshot.initial().copyWith(
          activeTabId: ProjectAssetsTabId.styles,
        ),
      );

      expect(catalogService.callCount, 1);
      expect(ragService.callCount, 1);
      expect(outcome.statusMessage, contains('已加载'));
    });

    test('refreshCatalog does not touch rag refresh source', () async {
      final catalogService = _FakeCatalogRefreshService(
        result: ProjectAssetsCatalogRefreshResult(
          catalog: const ProjectAssetsCatalog(),
          availableAgentOptions:
              const <ExpressionConstraintSelectableOptionViewData>[],
          availableModeOptions:
              const <ExpressionConstraintSelectableOptionViewData>[],
          availableStageOptions:
              const <ExpressionConstraintSelectableOptionViewData>[],
          statusMessage: 'catalog loaded',
        ),
      );
      final ragService = _FakeRagRefreshService(
        result: const ProjectRagExtractionExecutionResult(
          ok: true,
          didMutateProject: false,
          statusMessage: 'rag loaded',
          normalizationNote: '',
          analysisSummary: ProjectRagAnalysisSummary(
            storyOutlineSummary: '',
            premiseSummary: '',
            styleSummary: '',
            chapterTitles: <String>[],
            characterNames: <String>[],
            organizationNames: <String>[],
            worldRuleTitles: <String>[],
            relationshipPairs: <String>[],
            timelineLabels: <String>[],
            foreshadowTitles: <String>[],
          ),
        ),
      );
      final coordinator = ProjectAssetsRefreshCoordinator(
        catalogRefreshService: catalogService,
        ragRefreshService: ragService,
        selectionReconciler: const ProjectAssetsSelectionReconciler(),
        statusProjectionService:
            const ProjectAssetsRefreshStatusProjectionService(),
      );

      await coordinator.refreshCatalog(
        currentProject: const ProjectDescriptor(
          id: 'project_a',
          name: '测试项目',
          rootPath: 'D:/Projects/demo',
          projectType: 'novel',
          storageStrategy: ProjectStorageStrategy.markdownProjectStore,
        ),
        previousSnapshot: ProjectAssetsSnapshot.initial(),
      );

      expect(catalogService.callCount, 1);
      expect(ragService.callCount, 0);
    });
  });
}

class _FakeCatalogRefreshService extends ProjectAssetsCatalogRefreshService {
  _FakeCatalogRefreshService({required this.result})
    : super(
        loaderService: _NoopProjectAssetsLoaderService(),
        viewDataService: const ProjectAssetsViewDataService(),
        readAvailableProjectAgents: () => const <JsonMap>[],
      );

  final ProjectAssetsCatalogRefreshResult result;
  int callCount = 0;

  @override
  Future<ProjectAssetsCatalogRefreshResult> refresh(
    ProjectDescriptor project,
  ) async {
    callCount += 1;
    return result;
  }
}

class _FakeRagRefreshService extends ProjectAssetsRagRefreshService {
  _FakeRagRefreshService({required this.result})
    : super(
        ragExtractionExecutionService: ProjectRagExtractionExecutionService(),
      );

  final ProjectRagExtractionExecutionResult result;
  int callCount = 0;

  @override
  Future<ProjectRagExtractionExecutionResult> refresh({
    required ProjectDescriptor project,
    String selectedCorpusId = '',
  }) async {
    callCount += 1;
    return result;
  }
}

class _NoopProjectAssetsLoaderService extends ProjectAssetsLoaderService {
  _NoopProjectAssetsLoaderService()
    : super(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        timelineRepository: _NoopProjectTimelineRepository(),
        relationshipRepository: _NoopProjectRelationshipRepository(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
      );

  @override
  Future<ProjectAssetsCatalog> load(ProjectDescriptor project) async {
    return const ProjectAssetsCatalog();
  }
}

class _NoopProjectAssetLibraryService extends ProjectAssetLibraryService {
  _NoopProjectAssetLibraryService()
    : super(
        workspacePort: _NoopProjectWorkspacePort(),
        projectToolHostPort: _NoopProjectToolHostPort(),
      );
}

class _NoopProjectTimelineRepository extends ProjectTimelineRepository {
  _NoopProjectTimelineRepository()
    : super(hostPort: _NoopProjectToolHostPort());
}

class _NoopProjectRelationshipRepository extends ProjectRelationshipRepository {
  _NoopProjectRelationshipRepository()
    : super(hostPort: _NoopProjectToolHostPort());
}

class _NoopProjectWorkspacePort implements ProjectWorkspacePort {
  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}
}

class _NoopProjectToolHostPort implements ProjectToolHostPort {
  @override
  Future<void> copyExternalFile(
    String absolutePath,
    String rootPath,
    String targetRelativePath,
  ) async {}

  @override
  Future<void> createDirectory(String rootPath, String relativePath) async {}

  @override
  Future<void> deleteEntry(String rootPath, String relativePath) async {}

  @override
  Future<bool> entryExists(String rootPath, String relativePath) async => false;

  @override
  Future<List<JsonMap>> listEntries(
    String rootPath, {
    bool recursive = true,
  }) async => const <JsonMap>[];

  @override
  Future<void> moveEntry(
    String rootPath,
    String sourceRelativePath,
    String targetRelativePath,
  ) async {}

  @override
  Future<String?> readExternalTextFile(String absolutePath) async => null;

  @override
  Future<String?> readTextFile(String rootPath, String relativePath) async =>
      null;

  @override
  Future<void> writeTextFile(
    String rootPath,
    String relativePath,
    String content,
  ) async {}

  @override
  Future<void> writeExternalTextFile(
    String absolutePath,
    String content,
  ) async {}
}
