import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';

import 'project_tool_path_policy.dart';
import 'project_tool_result_factory.dart';

class ProjectFileWriteToolExecutor {
  ProjectFileWriteToolExecutor({
    required ProjectToolHostPort hostPort,
    ProjectToolPathPolicy? pathPolicy,
    ProjectToolResultFactory? resultFactory,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory();

  final ProjectToolHostPort _hostPort;
  final ProjectToolPathPolicy _pathPolicy;
  final ProjectToolResultFactory _resultFactory;

  Future<JsonMap> writeProjectFile(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 写入正式产物时由宿主落盘，但目标目录和命名策略仍遵循核心工作空间约定。
    final contentType = _pathPolicy.normalizeContentType(
      ValueReaders.stringValue(arguments['content_type'], 'draft'),
    );
    final title = ValueReaders.stringValue(arguments['title']).trim();
    final content = ValueReaders.stringValue(arguments['content']);
    if (content.trim().isEmpty) {
      return _resultFactory.error('content is required.');
    }
    var relativePath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    if (relativePath.isEmpty) {
      final fileName =
          '${_pathPolicy.safeFileName(title, fallback: contentType)}.md';
      relativePath = '${_pathPolicy.contentTypeDir(contentType)}/$fileName';
    }
    if (!relativePath.split('/').last.contains('.')) {
      relativePath = '$relativePath.md';
    }
    if (!_pathPolicy.isSafeFilePath(relativePath)) {
      return _resultFactory.error(
        'Unsafe or empty relative_path.',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    final overwrite = ValueReaders.boolValue(arguments['overwrite']);
    final targetPath = overwrite
        ? relativePath
        : await _pathPolicy.uniqueRelativePath(
            hostPort: _hostPort,
            rootPath: project.rootPath,
            relativePath: relativePath,
          );
    await _hostPort.writeTextFile(project.rootPath, targetPath, content);
    return _resultFactory.success(
      '已写入项目文件：$targetPath',
      data: <String, Object?>{
        'relative_path': targetPath,
        'content_type': contentType,
        'overwritten': overwrite && targetPath == relativePath,
        'changed_paths': <Object?>[targetPath],
      },
    );
  }

  Future<JsonMap> createProjectEntry(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 创建文件或目录的真实副作用在宿主层，但安全路径校验和缺省规则统一在这里。
    var relativePath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    if (relativePath.isEmpty) {
      return _resultFactory.error('relative_path is required.');
    }
    final isFolder =
        ValueReaders.boolValue(arguments['is_folder']) ||
        (!relativePath.split('/').last.contains('.') &&
            ValueReaders.stringValue(arguments['content']).trim().isEmpty);
    if (isFolder) {
      if (!_pathPolicy.isSafeScopePath(relativePath)) {
        return _resultFactory.error(
          'Unsafe folder path.',
          data: <String, Object?>{'relative_path': relativePath},
        );
      }
      relativePath = await _pathPolicy.uniqueRelativePath(
        hostPort: _hostPort,
        rootPath: project.rootPath,
        relativePath: relativePath,
      );
      await _hostPort.createDirectory(project.rootPath, relativePath);
      return _resultFactory.success(
        '已创建项目条目：$relativePath',
        data: <String, Object?>{
          'relative_path': relativePath,
          'is_folder': true,
          'changed_paths': <Object?>[relativePath],
        },
      );
    }
    if (!relativePath.split('/').last.contains('.')) {
      relativePath = '$relativePath.md';
    }
    if (!_pathPolicy.isSafeFilePath(relativePath)) {
      return _resultFactory.error(
        'Unsafe file path.',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    final overwrite = ValueReaders.boolValue(arguments['overwrite']);
    final exists = await _hostPort.entryExists(project.rootPath, relativePath);
    if (exists && !overwrite) {
      return _resultFactory.error(
        'Target file already exists.',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    final targetPath = exists && overwrite
        ? relativePath
        : await _pathPolicy.uniqueRelativePath(
            hostPort: _hostPort,
            rootPath: project.rootPath,
            relativePath: relativePath,
          );
    await _hostPort.writeTextFile(
      project.rootPath,
      targetPath,
      ValueReaders.stringValue(arguments['content']),
    );
    return _resultFactory.success(
      '已创建项目条目：$targetPath',
      data: <String, Object?>{
        'relative_path': targetPath,
        'is_folder': false,
        'changed_paths': <Object?>[targetPath],
      },
    );
  }

  Future<JsonMap> moveProjectFile(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 文件移动只允许项目内相对路径之间迁移，覆盖目标时要显式声明 overwrite。
    final source = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    final target = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['target_relative_path']),
    );
    if (!_pathPolicy.isSafeFilePath(source) ||
        !_pathPolicy.isSafeFilePath(target)) {
      return _resultFactory.error(
        'Unsafe source or target path.',
        data: <String, Object?>{
          'relative_path': source,
          'target_relative_path': target,
        },
      );
    }
    if (!await _hostPort.entryExists(project.rootPath, source)) {
      return _resultFactory.error(
        'Source file not found.',
        data: <String, Object?>{'relative_path': source},
      );
    }
    final overwrite = ValueReaders.boolValue(arguments['overwrite']);
    if (await _hostPort.entryExists(project.rootPath, target)) {
      if (!overwrite) {
        return _resultFactory.error(
          'Target file already exists.',
          data: <String, Object?>{'relative_path': target},
        );
      }
      await _hostPort.deleteEntry(project.rootPath, target);
    }
    await _hostPort.moveEntry(project.rootPath, source, target);
    return _resultFactory.success(
      '已移动项目文件：$source -> $target',
      data: <String, Object?>{
        'relative_path': target,
        'source_relative_path': source,
        'changed_paths': <Object?>[source, target],
      },
    );
  }

  Future<JsonMap> renameProjectFile(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 重命名只是 move 的受限变体，因此统一复用同一套安全检查和返回结构。
    final source = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    final newName = _pathPolicy.safeFileName(
      ValueReaders.stringValue(arguments['new_name']),
    );
    if (source.isEmpty || newName.isEmpty) {
      return _resultFactory.error(
        'relative_path and new_name are required.',
        data: <String, Object?>{'relative_path': source},
      );
    }
    final slashIndex = source.lastIndexOf('/');
    final target = slashIndex >= 0
        ? '${source.substring(0, slashIndex)}/$newName'
        : newName;
    return moveProjectFile(project, <String, Object?>{
      ...arguments,
      'relative_path': source,
      'target_relative_path': target,
    });
  }

  Future<JsonMap> deleteProjectFile(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 删除默认先备份，确保危险操作仍然留有回滚出口。
    final relativePath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    if (!_pathPolicy.isSafeFilePath(relativePath)) {
      return _resultFactory.error(
        'Unsafe or empty relative_path.',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    if (!await _hostPort.entryExists(project.rootPath, relativePath)) {
      return _resultFactory.error(
        'File not found.',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    var backupPath = '';
    if (ValueReaders.boolValue(arguments['create_backup'], true)) {
      final backup = await createBackup(project, arguments);
      if (!ValueReaders.boolValue(backup['ok'])) {
        return backup;
      }
      backupPath = ValueReaders.stringValue(backup['backup_path']);
    }
    await _hostPort.deleteEntry(project.rootPath, relativePath);
    return _resultFactory.success(
      '已删除项目文件：$relativePath',
      data: <String, Object?>{
        'relative_path': relativePath,
        'backup_path': backupPath,
        'changed_paths': <Object?>[relativePath],
      },
    );
  }

  Future<JsonMap> createBackup(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 显式备份会把原文件内容复制到 backups/，并附带一个轻量 meta.json 记录来源。
    final relativePath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['relative_path']),
    );
    if (!_pathPolicy.isSafeFilePath(relativePath) ||
        relativePath.startsWith('backups/')) {
      return _resultFactory.error(
        'Unsafe or empty relative_path.',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    final content = await _hostPort.readTextFile(
      project.rootPath,
      relativePath,
    );
    if (content == null) {
      return _resultFactory.error(
        'File not found.',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final slashIndex = relativePath.lastIndexOf('/');
    final directory = slashIndex >= 0
        ? relativePath.substring(0, slashIndex)
        : '';
    final fileName = slashIndex >= 0
        ? relativePath.substring(slashIndex + 1)
        : relativePath;
    final backupName = '$fileName.$timestamp.bak';
    final initialBackupPath = directory.isEmpty
        ? 'backups/$backupName'
        : 'backups/$directory/$backupName';
    final backupPath = await _pathPolicy.uniqueRelativePath(
      hostPort: _hostPort,
      rootPath: project.rootPath,
      relativePath: initialBackupPath,
    );
    await _hostPort.writeTextFile(project.rootPath, backupPath, content);
    final reason = ValueReaders.stringValue(arguments['reason']).trim();
    if (reason.isNotEmpty) {
      await _hostPort.writeTextFile(
        project.rootPath,
        '$backupPath.meta.json',
        const JsonEncoder.withIndent('  ').convert(<String, Object?>{
          'schema_version': 1,
          'source_path': relativePath,
          'backup_path': backupPath,
          'reason': reason,
          'created_at': DateTime.now().toIso8601String(),
        }),
      );
    }
    return _resultFactory.success(
      '已创建备份：$backupPath',
      data: <String, Object?>{
        'relative_path': relativePath,
        'backup_path': backupPath,
        'changed_paths': <Object?>[backupPath],
      },
    );
  }

  Future<JsonMap> restoreBackup(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 恢复备份默认回到原目标路径，也允许显式指定新的恢复位置。
    final backupPath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['backup_path']),
    );
    var targetPath = _pathPolicy.cleanRelativePath(
      ValueReaders.stringValue(arguments['target_path']),
    );
    if (!_pathPolicy.isSafeFilePath(backupPath) ||
        !backupPath.startsWith('backups/')) {
      return _resultFactory.error(
        'backup_path must be under backups/.',
        data: <String, Object?>{'backup_path': backupPath},
      );
    }
    final backupContent = await _hostPort.readTextFile(
      project.rootPath,
      backupPath,
    );
    if (backupContent == null) {
      return _resultFactory.error(
        'Backup file not found.',
        data: <String, Object?>{'backup_path': backupPath},
      );
    }
    if (targetPath.isEmpty) {
      final metaText = await _hostPort.readTextFile(
        project.rootPath,
        '$backupPath.meta.json',
      );
      if (metaText != null && metaText.trim().isNotEmpty) {
        try {
          final meta = ValueReaders.mapValue(jsonDecode(metaText));
          targetPath = _pathPolicy.cleanRelativePath(
            ValueReaders.stringValue(meta['source_path']),
          );
        } catch (_) {}
      }
      if (targetPath.isEmpty) {
        targetPath = _pathPolicy.backupTargetFromPath(backupPath);
      }
    }
    if (!_pathPolicy.isSafeFilePath(targetPath) ||
        targetPath.startsWith('backups/')) {
      return _resultFactory.error(
        'Unsafe restore target.',
        data: <String, Object?>{
          'backup_path': backupPath,
          'relative_path': targetPath,
        },
      );
    }
    await _hostPort.writeTextFile(project.rootPath, targetPath, backupContent);
    return _resultFactory.success(
      '已恢复备份：$targetPath',
      data: <String, Object?>{
        'backup_path': backupPath,
        'relative_path': targetPath,
        'changed_paths': <Object?>[targetPath],
      },
    );
  }
}
