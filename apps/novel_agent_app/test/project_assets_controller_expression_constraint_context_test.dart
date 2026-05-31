import 'package:flutter_test/flutter_test.dart';
import 'package:novel_agent_adapters/novel_agent_adapters.dart';
import 'package:novel_agent_app/features/project_assets/application/controllers/project_assets_controller.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_catalog.dart';
import 'package:novel_agent_app/features/project_assets/application/models/project_assets_tab_id.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_assets_loader_service.dart';
import 'package:novel_agent_app/features/project_assets/application/services/project_expression_constraint_workspace_service.dart';
import 'package:novel_agent_core/novel_agent_core.dart';

void main() {
  test(
    'openExpressionConstraintsForAgent switches to expression constraints tab and keeps agent context',
    () {
      final controller = ProjectAssetsController(
        projectAssetLibraryService: _NoopProjectAssetLibraryService(),
        expressionConstraintWorkspaceService:
            ProjectExpressionConstraintWorkspaceService(
              loadProfiles: (project) async =>
                  const <ExpressionConstraintProfile>[],
              loadBindings: (_) async =>
                  const <ProjectExpressionConstraintBinding>[],
              saveBindings: (project, bindings) async {},
            ),
        loaderService: _NoopProjectAssetsLoaderService(),
        readCurrentProject: () => null,
        readAvailableProjectAgents: () => const <JsonMap>[],
        syncWorkbenchResources: () async {},
        onBackRequested: () {},
      );

      controller.openExpressionConstraintsForAgent('reviewer');

      expect(
        controller.viewData.activeTabId,
        ProjectAssetsTabId.expressionConstraints,
      );
      expect(controller.viewData.entryAgentContextId, 'reviewer');
    },
  );
}

class _NoopProjectAssetLibraryService extends ProjectAssetLibraryService {
  _NoopProjectAssetLibraryService()
    : super(
        workspacePort: _NoopProjectWorkspacePort(),
        projectToolHostPort: _NoopProjectToolHostPort(),
      );
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
    return ProjectAssetsCatalog.empty();
  }
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

class _NoopProjectTimelineRepository extends ProjectTimelineRepository {
  _NoopProjectTimelineRepository()
    : super(hostPort: _NoopProjectToolHostPort());
}

class _NoopProjectRelationshipRepository extends ProjectRelationshipRepository {
  _NoopProjectRelationshipRepository()
    : super(hostPort: _NoopProjectToolHostPort());
}
