import 'project_content_path_policy_service.dart';
import 'project_content_storage_disposition.dart';
import 'project_storage_strategy.dart';

class ProjectStructuredContentWritePolicy {
  const ProjectStructuredContentWritePolicy({
    ProjectContentPathPolicyService? projectContentPathPolicyService,
  }) : _projectContentPathPolicyService =
           projectContentPathPolicyService ??
           const ProjectContentPathPolicyService();

  final ProjectContentPathPolicyService _projectContentPathPolicyService;

  static const Set<String> _sqlitePrimaryContentTypes = <String>{
    'chapter',
    'scene',
    'outline',
    'volume_outline',
    'chapter_outline',
    'setting',
    'character',
    'style',
    'summary',
    'knowledge',
    'source_original',
  };

  ProjectContentStorageDisposition dispositionOfBodyTextDocument({
    required ProjectStorageStrategy storageStrategy,
    required String documentKind,
  }) {
    // 中文注释: 这里直接回答“正文该去哪里”，让 core 先把 SQLite 主事实源与文件主事实源的边界说清楚。
    final normalizedKind = _projectContentPathPolicyService
        .normalizeContentType(documentKind);
    switch (storageStrategy) {
      case ProjectStorageStrategy.markdownProjectStore:
        return ProjectContentStorageDisposition.filesystemPrimaryFactSource;
      case ProjectStorageStrategy.sqliteProjectStore:
        return _sqlitePrimaryContentTypes.contains(normalizedKind)
            ? ProjectContentStorageDisposition.sqlitePrimaryFactSource
            : ProjectContentStorageDisposition.filesystemCompatibilityMirror;
    }
  }

  bool shouldWriteToSqlitePrimarySource({
    required ProjectStorageStrategy storageStrategy,
    required String documentKind,
  }) {
    // 中文注释: 这个布尔方法给现有写入链一个更易读的判断入口，避免调用方自己去比对枚举值。
    return dispositionOfBodyTextDocument(
          storageStrategy: storageStrategy,
          documentKind: documentKind,
        ) ==
        ProjectContentStorageDisposition.sqlitePrimaryFactSource;
  }

  bool shouldWriteToFilesystemPrimarySource({
    required ProjectStorageStrategy storageStrategy,
    required String documentKind,
  }) {
    // 中文注释: Markdown 主项目仍然走文件主事实源，因此这里保留一个对称的判断入口。
    return dispositionOfBodyTextDocument(
          storageStrategy: storageStrategy,
          documentKind: documentKind,
        ) ==
        ProjectContentStorageDisposition.filesystemPrimaryFactSource;
  }

  bool shouldKeepFilesystemCompatibilityMirror({
    required ProjectStorageStrategy storageStrategy,
    required String documentKind,
  }) {
    // 中文注释: SQLite 项目里并非所有内容都必须生成可编辑文件，兼容镜像只给需要文件投影的条目。
    return dispositionOfBodyTextDocument(
          storageStrategy: storageStrategy,
          documentKind: documentKind,
        ) ==
        ProjectContentStorageDisposition.filesystemCompatibilityMirror;
  }
}
