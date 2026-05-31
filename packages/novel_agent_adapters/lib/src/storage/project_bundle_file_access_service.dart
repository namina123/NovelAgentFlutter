import 'dart:io';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_bundle_directory_layout_service.dart';
import 'project_bundle_source_descriptor.dart';

class ProjectBundleFileAccessService {
  ProjectBundleFileAccessService({
    required ProjectToolHostPort hostPort,
    ProjectBundleDirectoryLayoutService? directoryLayoutService,
  }) : _hostPort = hostPort,
       _directoryLayoutService =
           directoryLayoutService ?? const ProjectBundleDirectoryLayoutService();

  final ProjectToolHostPort _hostPort;
  final ProjectBundleDirectoryLayoutService _directoryLayoutService;

  Future<ProjectBundleSourceDescriptor?> readBundleSource(
    String sourcePath,
  ) async {
    // 中文注释: bundle 源读取统一兼容“目录根”与“单独 bundle.json 文件”两种入口，CLI 不再自己猜路径。
    final absoluteSource = FileSystemEntity.isDirectorySync(sourcePath)
        ? Directory(sourcePath).absolute.path
        : File(sourcePath).absolute.path;
    if (Directory(absoluteSource).existsSync()) {
      final bundleFilePath = _join(
        absoluteSource,
        _directoryLayoutService.bundleFileName(),
      );
      final bundleContent = await _hostPort.readExternalTextFile(bundleFilePath);
      if ((bundleContent ?? '').trim().isEmpty) {
        return null;
      }
      return ProjectBundleSourceDescriptor(
        sourcePath: sourcePath,
        rootDirectoryPath: absoluteSource,
        bundleFilePath: bundleFilePath,
        bundleContent: bundleContent!,
      );
    }
    final file = File(absoluteSource);
    if (!file.existsSync()) {
      return null;
    }
    final bundleContent = await _hostPort.readExternalTextFile(absoluteSource);
    if ((bundleContent ?? '').trim().isEmpty) {
      return null;
    }
    return ProjectBundleSourceDescriptor(
      sourcePath: sourcePath,
      rootDirectoryPath: file.parent.absolute.path,
      bundleFilePath: absoluteSource,
      bundleContent: bundleContent!,
    );
  }

  Future<String> writeExportDirectory({
    required String targetDirectoryPath,
    required String directoryName,
    required Map<String, String> files,
  }) async {
    // 中文注释: 目录导出统一在目标根下创建一个 bundle 目录，避免直接把多个 bundle 文件平铺到用户选中的目录里。
    final rootDirectory = Directory(targetDirectoryPath).absolute.path;
    final exportDirectoryPath = _join(rootDirectory, directoryName);
    for (final entry in files.entries) {
      final absolutePath = _join(exportDirectoryPath, entry.key);
      await _hostPort.writeExternalTextFile(absolutePath, entry.value);
    }
    return exportDirectoryPath;
  }

  String joinWithinDirectory(String rootDirectoryPath, String relativePath) {
    return _join(rootDirectoryPath, relativePath);
  }

  String _join(String left, String right) {
    final separator = Platform.pathSeparator;
    final normalizedLeft = left.endsWith(separator)
        ? left.substring(0, left.length - 1)
        : left;
    final normalizedRight = right.replaceAll('/', separator);
    return '$normalizedLeft$separator$normalizedRight';
  }
}
