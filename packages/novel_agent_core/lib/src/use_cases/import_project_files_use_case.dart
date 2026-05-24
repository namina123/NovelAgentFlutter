import '../common/json_types.dart';
import '../ports/project_tool_host_port.dart';
import '../project/project_descriptor.dart';
import '../project/project_entry_path_service.dart';

class ImportProjectFilesUseCase {
  ImportProjectFilesUseCase({
    required ProjectToolHostPort projectToolHostPort,
    ProjectEntryPathService? pathService,
  }) : _projectToolHostPort = projectToolHostPort,
       _pathService = pathService ?? const ProjectEntryPathService();

  final ProjectToolHostPort _projectToolHostPort;
  final ProjectEntryPathService _pathService;

  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required List<String> sourcePaths,
    String targetDirectory = '',
  }) async {
    // 中文注释: 外部文件导入收口在这里，统一处理目标目录、重名去重和结果摘要。
    final cleanTargetDirectory = _pathService.cleanRelativePath(
      targetDirectory,
    );
    if (cleanTargetDirectory.isNotEmpty &&
        !_pathService.isSafeScopePath(cleanTargetDirectory)) {
      return _error(
        '目标目录不安全。',
        data: <String, Object?>{'target_directory': cleanTargetDirectory},
      );
    }
    final importedPaths = <String>[];
    final skippedPaths = <String>[];
    for (final sourcePath in sourcePaths) {
      final cleanSourcePath = sourcePath.trim();
      if (cleanSourcePath.isEmpty) {
        continue;
      }
      final sourceName = _sourceFileName(cleanSourcePath);
      if (sourceName.isEmpty) {
        skippedPaths.add(cleanSourcePath);
        continue;
      }
      final targetRelativePath = cleanTargetDirectory.isEmpty
          ? sourceName
          : '$cleanTargetDirectory/$sourceName';
      final uniqueTargetPath = await _pathService.uniqueRelativePath(
        hostPort: _projectToolHostPort,
        rootPath: project.rootPath,
        relativePath: targetRelativePath,
      );
      await _projectToolHostPort.copyExternalFile(
        cleanSourcePath,
        project.rootPath,
        uniqueTargetPath,
      );
      importedPaths.add(uniqueTargetPath);
    }
    return <String, Object?>{
      'ok': importedPaths.isNotEmpty,
      'summary': importedPaths.isEmpty
          ? '没有可导入的文件。'
          : '已导入 ${importedPaths.length} 个文件。',
      'imported_paths': importedPaths,
      'skipped_paths': skippedPaths,
    };
  }

  String _sourceFileName(String sourcePath) {
    // 中文注释: 外部源文件名提取单独收口，避免路径分隔符判断散落在导入循环里。
    final normalized = sourcePath.replaceAll('\\', '/').trim();
    if (normalized.isEmpty) {
      return '';
    }
    final segments = normalized.split('/');
    return _pathService.safeFileName(
      segments.isEmpty ? normalized : segments.last,
      fallback: 'imported_file',
    );
  }

  JsonMap _error(String error, {JsonMap data = const <String, Object?>{}}) {
    return <String, Object?>{'ok': false, 'error': error, ...data};
  }
}
