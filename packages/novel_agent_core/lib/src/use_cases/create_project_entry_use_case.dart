import '../common/json_types.dart';
import '../ports/project_tool_host_port.dart';
import '../project/project_descriptor.dart';
import '../project/project_entry_path_service.dart';

typedef PrepareProjectEntryFileWrite =
    Future<void> Function({
      required ProjectDescriptor project,
      required String relativePath,
      required String content,
    });

typedef RollbackProjectEntryFileWrite =
    Future<void> Function({
      required ProjectDescriptor project,
      required String relativePath,
      required String content,
    });

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
    PrepareProjectEntryFileWrite? prepareFileWrite,
    RollbackProjectEntryFileWrite? rollbackPreparedFileWrite,
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
    // 中文注释: SQLite 等结构化存储先提交主事实源，再写入文件投影，避免只留下 Markdown 镜像。
    var primarySourcePrepared = false;
    try {
      await prepareFileWrite?.call(
        project: project,
        relativePath: cleanRelativePath,
        content: content,
      );
      primarySourcePrepared = prepareFileWrite != null;
      await _projectToolHostPort.writeTextFile(
        project.rootPath,
        cleanRelativePath,
        content,
      );
    } catch (error, stackTrace) {
      // 中文注释: 主事实源与文件投影不能共享事务；投影失败时让宿主按保存前快照
      // 恢复主库，且绝不让恢复异常盖掉用户真正需要处理的写入错误。
      if (primarySourcePrepared) {
        try {
          await rollbackPreparedFileWrite?.call(
            project: project,
            relativePath: cleanRelativePath,
            content: content,
          );
        } catch (_) {
          // Preserve the original write failure.
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
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
