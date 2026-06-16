import '../common/json_types.dart';
import '../ports/project_repository.dart';
import '../ports/project_workspace_port.dart';
import '../project/project_descriptor.dart';
import '../project/project_support_document_catalog.dart';
import '../runtime/project_workspace_snapshot.dart';

class LoadProjectWorkspaceUseCase {
  const LoadProjectWorkspaceUseCase({
    required ProjectRepository projectRepository,
    required ProjectWorkspacePort projectWorkspacePort,
  }) : _projectRepository = projectRepository,
       _projectWorkspacePort = projectWorkspacePort;

  final ProjectRepository _projectRepository;
  final ProjectWorkspacePort _projectWorkspacePort;

  Future<ProjectWorkspaceSnapshot?> execute(String rootPath) async {
    // 中文注释: 这个用例把“打开项目”和“读取工作空间目录”收成统一入口，避免宿主层手动串联两步。
    final project = await _projectRepository.openByPath(rootPath);
    if (project == null) {
      return null;
    }
    var entries = await _projectWorkspacePort.listEntries(project.rootPath);
    entries = await _migrateProjectOverviewIfNeeded(project, entries);
    return ProjectWorkspaceSnapshot(
      project: project,
      projectInfo: _projectInfo(project),
      entries: entries,
    );
  }

  Future<List<JsonMap>> _migrateProjectOverviewIfNeeded(
    ProjectDescriptor project,
    List<JsonMap> entries,
  ) async {
    final canonicalPath =
        ProjectSupportDocumentCatalog.projectOverviewRelativePath;
    final normalizedCanonical =
        ProjectSupportDocumentCatalog.normalizeProjectOverviewPath(
          canonicalPath,
        );
    if (normalizedCanonical.isEmpty) {
      return entries;
    }
    if (_containsPath(entries, canonicalPath)) {
      return entries;
    }
    for (final legacyPath
        in ProjectSupportDocumentCatalog.legacyProjectOverviewRelativePaths) {
      if (!_containsPath(entries, legacyPath)) {
        continue;
      }
      final legacyContent = await _projectWorkspacePort.readTextFile(
        project.rootPath,
        legacyPath,
      );
      if (legacyContent == null || legacyContent.trim().isEmpty) {
        continue;
      }
      await _projectWorkspacePort.writeTextFile(
        project.rootPath,
        canonicalPath,
        legacyContent,
      );
      return _projectWorkspacePort.listEntries(project.rootPath);
    }
    return entries;
  }

  bool _containsPath(List<JsonMap> entries, String relativePath) {
    final normalizedTarget = _normalizePath(relativePath);
    if (normalizedTarget.isEmpty) {
      return false;
    }
    for (final entry in entries) {
      final path = _normalizePath(entry['relative_path']?.toString() ?? '');
      if (path == normalizedTarget) {
        return true;
      }
    }
    return false;
  }

  String _normalizePath(String relativePath) {
    return relativePath
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+'), '/')
        .replaceAll(RegExp(r'^/+|/+$'), '')
        .toLowerCase();
  }

  JsonMap _projectInfo(ProjectDescriptor project) {
    // 中文注释: 项目信息在这里先落成稳定字典，供上下文组装、提示词和视图层复用。
    return <String, Object?>{
      'id': project.id,
      'title': project.name,
      'path': project.rootPath,
      'project_type': project.projectType,
      'storage_strategy': project.storageStrategy.id,
      'runtime_baseline_id': project.runtimeBaselineId,
      'stage': 'draft',
    };
  }
}
