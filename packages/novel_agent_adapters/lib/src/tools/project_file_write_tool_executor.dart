import 'dart:convert';

import 'package:novel_agent_core/novel_agent_core.dart';
import 'package:novel_agent_core/src/project/project_storage_aware_workspace_policy.dart';

import '../storage/project_structured_content_bridge_service.dart';
import '../storage/project_structured_content_synchronization_host_port.dart';
import 'project_tool_path_policy.dart';
import 'project_tool_result_factory.dart';

class ProjectFileWriteToolExecutor {
  ProjectFileWriteToolExecutor({
    required ProjectToolHostPort hostPort,
    ProjectToolPathPolicy? pathPolicy,
    ProjectToolResultFactory? resultFactory,
    ProjectStorageAwareWorkspacePolicy? workspacePolicy,
    ChapterOutputPathPolicyService? chapterOutputPathPolicyService,
    ProjectStructuredContentBridgeService? structuredContentBridgeService,
  }) : _hostPort = hostPort,
       _pathPolicy = pathPolicy ?? ProjectToolPathPolicy(),
       _resultFactory = resultFactory ?? ProjectToolResultFactory(),
       _workspacePolicy =
           workspacePolicy ?? const ProjectStorageAwareWorkspacePolicy(),
       _chapterOutputPathPolicyService =
           chapterOutputPathPolicyService ??
           const ChapterOutputPathPolicyService(),
       _structuredContentBridgeService =
           structuredContentBridgeService ??
           ProjectStructuredContentBridgeService();

  final ProjectToolHostPort _hostPort;
  final ProjectToolPathPolicy _pathPolicy;
  final ProjectToolResultFactory _resultFactory;
  final ProjectStorageAwareWorkspacePolicy _workspacePolicy;
  final ChapterOutputPathPolicyService _chapterOutputPathPolicyService;
  final ProjectStructuredContentBridgeService _structuredContentBridgeService;

  Future<JsonMap> writeProjectFile(
    ProjectDescriptor project,
    JsonMap arguments,
  ) async {
    // 中文注释: 写入正式产物时由宿主落盘，但目标目录和命名策略仍遵循核心工作空间约定。
    final contentType = _pathPolicy.normalizeContentType(
      ValueReaders.stringValue(arguments['content_type'], 'chapter'),
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
      if (contentType == 'chapter') {
        relativePath = _chapterOutputPathPolicyService.suggestChapterPath(
          explicitTitle: title,
          chapterContent: content,
          fallbackTitle: contentType,
        );
      }
      if (relativePath.trim().isEmpty) {
        final fileName =
            '${_pathPolicy.safeFileName(title, fallback: contentType)}.md';
        relativePath = '${_pathPolicy.contentTypeDir(contentType)}/$fileName';
      }
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
    final storageRejection = _storageAwareProjectionRejection(
      project: project,
      relativePath: relativePath,
      contentType: contentType,
    );
    if (storageRejection != null) {
      return storageRejection;
    }
    final overwrite = ValueReaders.boolValue(arguments['overwrite']);
    final targetPath = overwrite
        ? relativePath
        : await _pathPolicy.uniqueRelativePath(
            hostPort: _hostPort,
            rootPath: project.rootPath,
            relativePath: relativePath,
          );
    await _persistStructuredProjection(
      project: project,
      relativePath: targetPath,
      contentType: contentType,
      title: title,
      content: content,
    );
    await _runWithoutHostStructuredContentSynchronization(
      () => _hostPort.writeTextFile(project.rootPath, targetPath, content),
    );
    return _resultFactory.success(
      '已写入项目文件：$targetPath',
      data: <String, Object?>{
        'relative_path': targetPath,
        'content_type': contentType,
        'overwritten': overwrite && targetPath == relativePath,
        'changed_paths': <Object?>[targetPath],
        'storage_strategy': project.storageStrategy.id,
        'storage_surface_role': _storageSurfaceRole(
          project: project,
          relativePath: targetPath,
          contentType: contentType,
        ),
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
      return _resultFactory.notExecuted(
        'create_project_entry 缺少 relative_path。请先确定目标英文相对路径后重试。',
      );
    }
    final isFolder =
        ValueReaders.boolValue(arguments['is_folder']) ||
        (!relativePath.split('/').last.contains('.') &&
            ValueReaders.stringValue(arguments['content']).trim().isEmpty);
    if (isFolder) {
      final storageRejection = _storageAwareProjectionRejection(
        project: project,
        relativePath: relativePath,
        contentType: _pathPolicy.inferContentTypeFromPath(relativePath),
      );
      if (storageRejection != null) {
        return storageRejection;
      }
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
          'storage_strategy': project.storageStrategy.id,
          'storage_surface_role': _storageSurfaceRole(
            project: project,
            relativePath: relativePath,
          ),
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
    final storageRejection = _storageAwareProjectionRejection(
      project: project,
      relativePath: relativePath,
      contentType: _pathPolicy.inferContentTypeFromPath(relativePath),
    );
    if (storageRejection != null) {
      return storageRejection;
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
    final content = ValueReaders.stringValue(arguments['content']);
    await _persistStructuredProjection(
      project: project,
      relativePath: targetPath,
      contentType: _pathPolicy.inferContentTypeFromPath(targetPath),
      title: targetPath.split('/').last,
      content: content,
    );
    await _runWithoutHostStructuredContentSynchronization(
      () => _hostPort.writeTextFile(project.rootPath, targetPath, content),
    );
    return _resultFactory.success(
      '已创建项目条目：$targetPath',
      data: <String, Object?>{
        'relative_path': targetPath,
        'is_folder': false,
        'changed_paths': <Object?>[targetPath],
        'storage_strategy': project.storageStrategy.id,
        'storage_surface_role': _storageSurfaceRole(
          project: project,
          relativePath: targetPath,
        ),
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
      return _resultFactory.notExecuted(
        'move_project_file 的源路径或目标路径无效。请使用项目内英文 relative_path。',
        data: <String, Object?>{
          'relative_path': source,
          'target_relative_path': target,
        },
      );
    }
    if (source == target) {
      return _resultFactory.notExecuted(
        'move_project_file 的源路径和目标路径不能相同。',
        data: <String, Object?>{
          'relative_path': source,
          'target_relative_path': target,
        },
      );
    }
    final storageRejection = _storageAwareProjectionRejection(
      project: project,
      relativePath: source,
      contentType: _pathPolicy.inferContentTypeFromPath(source),
    );
    if (storageRejection != null) {
      return storageRejection;
    }
    final targetRejection = _storageAwareProjectionRejection(
      project: project,
      relativePath: target,
      contentType: _pathPolicy.inferContentTypeFromPath(target),
    );
    if (targetRejection != null) {
      return targetRejection;
    }
    if (!await _hostPort.entryExists(project.rootPath, source)) {
      return _resultFactory.notExecuted(
        'move_project_file 未找到源文件。请先调用 list_project_files 确认英文 relative_path。',
        data: <String, Object?>{'relative_path': source},
      );
    }
    final overwrite = ValueReaders.boolValue(arguments['overwrite']);
    final targetExisted = await _hostPort.entryExists(project.rootPath, target);
    if (targetExisted) {
      if (!overwrite) {
        return _resultFactory.error(
          'Target file already exists.',
          data: <String, Object?>{'relative_path': target},
        );
      }
    }
    final sourceSnapshot = await _structuredContentBridgeService
        .loadStructuredDocument(project: project, documentPath: source);
    final targetSnapshot = await _structuredContentBridgeService
        .loadStructuredDocument(project: project, documentPath: target);
    final sourceContent = await _hostPort.readTextFile(
      project.rootPath,
      source,
    );
    final targetContent = targetExisted
        ? await _hostPort.readTextFile(project.rootPath, target)
        : null;
    try {
      // Move SQLite first, then mutate the readable projection. Either leg can
      // fail, so the catch block restores both snapshots best-effort.
      await _structuredContentBridgeService.moveStructuredDocument(
        project: project,
        sourcePath: source,
        targetPath: target,
        targetDocumentKind: _pathPolicy.inferContentTypeFromPath(target),
      );
      await _runWithoutHostStructuredContentSynchronization(() async {
        if (targetExisted) {
          await _hostPort.deleteEntry(project.rootPath, target);
        }
        await _hostPort.moveEntry(project.rootPath, source, target);
      });
    } catch (_) {
      await _restoreMoveProjection(
        project: project,
        sourcePath: source,
        sourceContent: sourceContent,
        targetPath: target,
        targetExisted: targetExisted,
        targetContent: targetContent,
      );
      await _restoreStructuredDocument(
        project: project,
        documentPath: source,
        snapshot: sourceSnapshot,
      );
      await _restoreStructuredDocument(
        project: project,
        documentPath: target,
        snapshot: targetSnapshot,
      );
      rethrow;
    }
    return _resultFactory.success(
      '已移动项目文件：$source -> $target',
      data: <String, Object?>{
        'relative_path': target,
        'source_relative_path': source,
        'changed_paths': <Object?>[source, target],
        'storage_strategy': project.storageStrategy.id,
        'storage_surface_role': _storageSurfaceRole(
          project: project,
          relativePath: target,
        ),
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
      return _resultFactory.notExecuted(
        'rename_project_file 缺少 relative_path 或 new_name。',
        data: <String, Object?>{'relative_path': source},
      );
    }
    final storageRejection = _storageAwareProjectionRejection(
      project: project,
      relativePath: source,
      contentType: _pathPolicy.inferContentTypeFromPath(source),
    );
    if (storageRejection != null) {
      return storageRejection;
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
      return _resultFactory.notExecuted(
        'delete_project_file 的 relative_path 无效。请使用项目内英文 relative_path。',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    final storageRejection = _storageAwareProjectionRejection(
      project: project,
      relativePath: relativePath,
      contentType: _pathPolicy.inferContentTypeFromPath(relativePath),
    );
    if (storageRejection != null) {
      return storageRejection;
    }
    if (!await _hostPort.entryExists(project.rootPath, relativePath)) {
      return _resultFactory.notExecuted(
        'delete_project_file 未找到目标文件。请先调用 list_project_files 确认英文 relative_path。',
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
    final contentSnapshot = await _hostPort.readTextFile(
      project.rootPath,
      relativePath,
    );
    final structuredSnapshot = await _structuredContentBridgeService
        .loadStructuredDocument(project: project, documentPath: relativePath);
    try {
      // Delete the primary SQLite record first. If projection deletion fails,
      // restore the document so reads cannot observe an orphaned projection.
      await _structuredContentBridgeService.deleteStructuredDocument(
        project: project,
        documentPath: relativePath,
        documentKind: _pathPolicy.inferContentTypeFromPath(relativePath),
      );
      await _runWithoutHostStructuredContentSynchronization(
        () => _hostPort.deleteEntry(project.rootPath, relativePath),
      );
    } catch (_) {
      await _restoreDeletedProjection(
        project: project,
        relativePath: relativePath,
        content: contentSnapshot,
      );
      await _restoreStructuredDocument(
        project: project,
        documentPath: relativePath,
        snapshot: structuredSnapshot,
      );
      rethrow;
    }
    return _resultFactory.success(
      '已删除项目文件：$relativePath',
      data: <String, Object?>{
        'relative_path': relativePath,
        'backup_path': backupPath,
        'changed_paths': <Object?>[relativePath],
        'storage_strategy': project.storageStrategy.id,
        'storage_surface_role': _storageSurfaceRole(
          project: project,
          relativePath: relativePath,
        ),
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
      return _resultFactory.notExecuted(
        'create_backup 的 relative_path 无效。请使用项目内英文 relative_path。',
        data: <String, Object?>{'relative_path': relativePath},
      );
    }
    final content =
        await _structuredContentBridgeService.readProjectedBodyText(
          project,
          relativePath,
        ) ??
        await _hostPort.readTextFile(project.rootPath, relativePath);
    if (content == null) {
      return _resultFactory.notExecuted(
        'create_backup 未找到目标文件。请先调用 list_project_files 确认英文 relative_path。',
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
        'storage_strategy': project.storageStrategy.id,
        'storage_surface_role': 'compatibility_backup',
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
      return _resultFactory.notExecuted(
        'restore_backup 的 backup_path 无效，必须是 backups/ 下的英文相对路径。',
        data: <String, Object?>{'backup_path': backupPath},
      );
    }
    final backupContent = await _hostPort.readTextFile(
      project.rootPath,
      backupPath,
    );
    if (backupContent == null) {
      return _resultFactory.notExecuted(
        'restore_backup 未找到备份文件。请先确认 backups/ 下的英文相对路径。',
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
      return _resultFactory.notExecuted(
        'restore_backup 的恢复目标无效。请使用项目内英文相对路径。',
        data: <String, Object?>{
          'backup_path': backupPath,
          'relative_path': targetPath,
        },
      );
    }
    await _persistStructuredProjection(
      project: project,
      relativePath: targetPath,
      contentType: _pathPolicy.inferContentTypeFromPath(targetPath),
      title: targetPath.split('/').last,
      content: backupContent,
    );
    await _hostPort.writeTextFile(project.rootPath, targetPath, backupContent);
    return _resultFactory.success(
      '已恢复备份：$targetPath',
      data: <String, Object?>{
        'backup_path': backupPath,
        'relative_path': targetPath,
        'changed_paths': <Object?>[targetPath],
        'storage_strategy': project.storageStrategy.id,
        'storage_surface_role': 'compatibility_restore',
      },
    );
  }

  JsonMap? _storageAwareProjectionRejection({
    required ProjectDescriptor project,
    required String relativePath,
    required String contentType,
  }) {
    // 中文注释: SQLite 项目里知识/研究/引用投影是只读入口，低层写工具碰到这些路径要显式退回。
    if (project.storageStrategy != ProjectStorageStrategy.sqliteProjectStore) {
      return null;
    }
    final cleanPath = _pathPolicy.cleanRelativePath(relativePath);
    if (cleanPath.startsWith('knowledge/') ||
        cleanPath.startsWith('research/') ||
        cleanPath.startsWith('references/') ||
        contentType == 'knowledge') {
      return _resultFactory.notExecuted(
        'SQLite 项目中的知识/研究/引用投影为只读入口，请改用语义工具或主事实源写入链。',
        data: <String, Object?>{
          'relative_path': cleanPath,
          'storage_strategy': project.storageStrategy.id,
          'storage_surface_role': 'compatibility_rejected_projection',
        },
      );
    }
    return null;
  }

  String _storageSurfaceRole({
    required ProjectDescriptor project,
    required String relativePath,
    String contentType = '',
  }) {
    // 中文注释: 写工具结果里主动标注当前路径属于主链、兼容层还是投影层，方便 prompt 和测试读取。
    if (project.storageStrategy != ProjectStorageStrategy.sqliteProjectStore) {
      return 'filesystem_primary';
    }
    final cleanPath = _pathPolicy.cleanRelativePath(relativePath);
    if (_workspacePolicy.isMetadataPath(relativePath: cleanPath)) {
      return 'workspace_metadata_read';
    }
    if (_workspacePolicy.isProjectionPath(
      storageStrategy: project.storageStrategy,
      relativePath: cleanPath,
    )) {
      final inferredType = contentType.trim().isNotEmpty
          ? contentType.trim()
          : _pathPolicy.inferContentTypeFromPath(cleanPath);
      if (inferredType == 'knowledge') {
        return 'compatibility_rejected_projection';
      }
      return 'compatibility_projection';
    }
    final inferredType = contentType.trim().isNotEmpty
        ? contentType.trim()
        : _pathPolicy.inferContentTypeFromPath(cleanPath);
    if (cleanPath.startsWith('knowledge/') ||
        cleanPath.startsWith('research/') ||
        cleanPath.startsWith('references/') ||
        inferredType == 'knowledge') {
      return 'compatibility_rejected_projection';
    }
    if (inferredType == 'chapter' ||
        inferredType == 'scene' ||
        inferredType == 'outline' ||
        inferredType == 'volume_outline' ||
        inferredType == 'chapter_outline' ||
        inferredType == 'setting' ||
        inferredType == 'character' ||
        inferredType == 'style' ||
        inferredType == 'summary') {
      return 'compatibility_projection';
    }
    return 'compatibility_mirror';
  }

  Future<void> _persistStructuredProjection({
    required ProjectDescriptor project,
    required String relativePath,
    required String contentType,
    required String title,
    required String content,
  }) {
    return _structuredContentBridgeService.persistWorkspaceProjectionDocument(
      project: project,
      documentPath: relativePath,
      inferredDocumentKind: contentType,
      title: title,
      content: content,
    );
  }

  Future<void> _restoreMoveProjection({
    required ProjectDescriptor project,
    required String sourcePath,
    required String? sourceContent,
    required String targetPath,
    required bool targetExisted,
    required String? targetContent,
  }) async {
    // Projection repair is deliberately best-effort: arbitrary host ports may
    // fail after a partial filesystem mutation, while SQLite is restored below.
    try {
      final sourceExists = await _hostPort.entryExists(
        project.rootPath,
        sourcePath,
      );
      if (!sourceExists && sourceContent != null) {
        await _hostPort.writeTextFile(
          project.rootPath,
          sourcePath,
          sourceContent,
        );
      }
      if (targetExisted) {
        if (targetContent != null) {
          await _hostPort.writeTextFile(
            project.rootPath,
            targetPath,
            targetContent,
          );
        }
      } else if (await _hostPort.entryExists(project.rootPath, targetPath)) {
        await _hostPort.deleteEntry(project.rootPath, targetPath);
      }
    } catch (_) {}
  }

  Future<void> _restoreDeletedProjection({
    required ProjectDescriptor project,
    required String relativePath,
    required String? content,
  }) async {
    if (content == null) {
      return;
    }
    try {
      if (!await _hostPort.entryExists(project.rootPath, relativePath)) {
        await _hostPort.writeTextFile(project.rootPath, relativePath, content);
      }
    } catch (_) {}
  }

  Future<void> _restoreStructuredDocument({
    required ProjectDescriptor project,
    required String documentPath,
    required SqliteProjectBodyTextDocument? snapshot,
  }) async {
    try {
      await _structuredContentBridgeService.restoreStructuredDocument(
        project: project,
        documentPath: documentPath,
        snapshot: snapshot,
      );
    } catch (_) {}
  }

  Future<T> _runWithoutHostStructuredContentSynchronization<T>(
    Future<T> Function() operation,
  ) {
    final hostPort = _hostPort;
    if (hostPort is ProjectStructuredContentSynchronizationHostPort) {
      return (hostPort as ProjectStructuredContentSynchronizationHostPort)
          .runWithoutStructuredContentSynchronization(operation);
    }
    return operation();
  }
}
