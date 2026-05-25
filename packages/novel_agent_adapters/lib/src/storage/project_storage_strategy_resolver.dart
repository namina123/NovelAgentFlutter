import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

class ProjectStorageStrategyResolver {
  ProjectStorageStrategyResolver({
    ProjectManifestCodecService? projectManifestCodecService,
  }) : _projectManifestCodecService =
           projectManifestCodecService ?? ProjectManifestCodecService();

  final ProjectManifestCodecService _projectManifestCodecService;

  Future<ProjectStorageStrategy> resolveFromRootPath(String rootPath) async {
    // 中文注释: 旧项目没有 storage_strategy 字段时默认按 Markdown 兼容，避免历史项目升级前直接打不开。
    final manifestFile = File(
      '$rootPath${Platform.pathSeparator}${ProjectManifestCodecService.manifestRelativePath.replaceAll('/', Platform.pathSeparator)}',
    );
    if (!await manifestFile.exists()) {
      return ProjectStorageStrategy.markdownProjectStore;
    }
    final manifest = _projectManifestCodecService.parse(
      await manifestFile.readAsString(),
    );
    return manifest.storageStrategy;
  }

  ProjectStorageStrategy resolveManifest(ProjectManifest manifest) {
    return manifest.storageStrategy;
  }
}
