import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_storage_strategy_resolver.dart';

class LocalProjectRepository implements ProjectRepository {
  LocalProjectRepository({
    ProjectManifestCodecService? projectManifestCodecService,
    ProjectStorageStrategyResolver? projectStorageStrategyResolver,
  }) : _projectManifestCodecService =
           projectManifestCodecService ?? ProjectManifestCodecService(),
       _projectStorageStrategyResolver =
           projectStorageStrategyResolver ?? ProjectStorageStrategyResolver();

  final ProjectManifestCodecService _projectManifestCodecService;
  final ProjectStorageStrategyResolver _projectStorageStrategyResolver;

  @override
  Future<ProjectDescriptor?> openByPath(String rootPath) async {
    // 中文注释: 本地项目仓储只接受真正带 manifest 的项目根目录，普通文件夹不能再被误认成项目。
    final directory = Directory(rootPath).absolute;
    if (!await directory.exists()) {
      return null;
    }
    final normalizedName = directory.uri.pathSegments.isEmpty
        ? 'novel_project'
        : directory.uri.pathSegments
              .where((segment) => segment.trim().isNotEmpty)
              .last;
    final projectName = normalizedName.endsWith('/')
        ? normalizedName.substring(0, normalizedName.length - 1)
        : normalizedName;
    final manifestPath =
        '${directory.path}${Platform.pathSeparator}${ProjectManifestCodecService.manifestRelativePath.replaceAll('/', Platform.pathSeparator)}';
    final manifestFile = File(manifestPath);
    final manifestExists = await manifestFile.exists();
    if (!manifestExists) {
      return null;
    }
    final manifest = _projectManifestCodecService.parse(
      await manifestFile.readAsString(),
      fallbackTitle: projectName,
    );
    final storageStrategy =
        await _projectStorageStrategyResolver.resolveFromRootPath(
          directory.path,
        );
    return ProjectDescriptor(
      id: _projectIdFromName(manifest.title),
      name: manifest.title,
      rootPath: directory.path,
      projectType: manifest.projectType,
      storageStrategy: storageStrategy,
      projectBranchId: manifest.projectBranchId,
      runtimeBaselineId: manifest.runtimeBaselineId,
    );
  }

  String _projectIdFromName(String projectName) {
    // 中文注释: 项目 ID 只做轻量归一化，保证目录名中含空格或中文时仍有稳定标识。
    var result = projectName.trim().toLowerCase();
    result = result.replaceAll(RegExp(r'\s+'), '_');
    result = result.replaceAll(RegExp(r'[^a-z0-9_\u4e00-\u9fff-]'), '_');
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.replaceAll(RegExp(r'^_+|_+$'), '');
    return result.isEmpty ? 'novel_project' : result;
  }
}
