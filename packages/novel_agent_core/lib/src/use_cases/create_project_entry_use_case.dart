import '../common/json_types.dart';
import '../ports/project_tool_host_port.dart';
import '../project/project_descriptor.dart';
import '../project/project_entry_path_service.dart';

class CreateProjectEntryUseCase {
  CreateProjectEntryUseCase({
    required ProjectToolHostPort projectToolHostPort,
    ProjectEntryPathService? pathService,
  }) : _projectToolHostPort = projectToolHostPort,
       _pathService = pathService ?? const ProjectEntryPathService();

  final ProjectToolHostPort _projectToolHostPort;
  final ProjectEntryPathService _pathService;

  Future<JsonMap> execute({
    required ProjectDescriptor project,
    required String relativePath,
    bool isFolder = false,
    String content = '',
    bool overwrite = false,
  }) async {
    // 中文注释: 新建文件或目录统一经过这里，确保 GUI、CLI 和后续自动化入口遵循同一套路径规则。
    var cleanRelativePath = _pathService.cleanRelativePath(relativePath);
    if (cleanRelativePath.isEmpty) {
      return _error('relative_path 不能为空。');
    }
    if (isFolder) {
      if (!_pathService.isSafeScopePath(cleanRelativePath)) {
        return _error(
          '目录路径不安全。',
          data: <String, Object?>{'relative_path': cleanRelativePath},
        );
      }
      cleanRelativePath = await _pathService.uniqueRelativePath(
        hostPort: _projectToolHostPort,
        rootPath: project.rootPath,
        relativePath: cleanRelativePath,
      );
      await _projectToolHostPort.createDirectory(
        project.rootPath,
        cleanRelativePath,
      );
      return _success(
        '已创建目录：$cleanRelativePath',
        data: <String, Object?>{
          'relative_path': cleanRelativePath,
          'is_folder': true,
        },
      );
    }
    if (!_pathService.isSafeFilePath(cleanRelativePath)) {
      return _error(
        '文件路径不安全。',
        data: <String, Object?>{'relative_path': cleanRelativePath},
      );
    }
    if (!cleanRelativePath.split('/').last.contains('.')) {
      cleanRelativePath = '$cleanRelativePath.md';
    }
    final exists = await _projectToolHostPort.entryExists(
      project.rootPath,
      cleanRelativePath,
    );
    if (exists && !overwrite) {
      cleanRelativePath = await _pathService.uniqueRelativePath(
        hostPort: _projectToolHostPort,
        rootPath: project.rootPath,
        relativePath: cleanRelativePath,
      );
    }
    await _projectToolHostPort.writeTextFile(
      project.rootPath,
      cleanRelativePath,
      content,
    );
    return _success(
      '已创建文件：$cleanRelativePath',
      data: <String, Object?>{
        'relative_path': cleanRelativePath,
        'is_folder': false,
      },
    );
  }

  JsonMap _success(String summary, {JsonMap data = const <String, Object?>{}}) {
    return <String, Object?>{'ok': true, 'summary': summary, ...data};
  }

  JsonMap _error(String error, {JsonMap data = const <String, Object?>{}}) {
    return <String, Object?>{'ok': false, 'error': error, ...data};
  }
}
