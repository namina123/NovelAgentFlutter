import 'project_content_path_policy_service.dart';
import 'project_content_storage_disposition.dart';
import 'project_storage_strategy.dart';

class ProjectStorageAwareWorkspacePolicy {
  const ProjectStorageAwareWorkspacePolicy({
    ProjectContentPathPolicyService? projectContentPathPolicyService,
  }) : _projectContentPathPolicyService =
           projectContentPathPolicyService ??
           const ProjectContentPathPolicyService();

  final ProjectContentPathPolicyService _projectContentPathPolicyService;

  ProjectContentStorageDisposition dispositionOfWorkspacePath({
    required ProjectStorageStrategy storageStrategy,
    required String relativePath,
  }) {
    // 中文注释: 这里负责把工作区路径翻译成“主事实源 / 投影 / 兼容镜像 / 元数据”，给后续 adapters 统一消费。
    final cleanPath = relativePath.trim().replaceAll('\\', '/');
    if (cleanPath.isEmpty) {
      return ProjectContentStorageDisposition.unsupported;
    }
    if (cleanPath.startsWith('.novel_agent/')) {
      return ProjectContentStorageDisposition.workspaceMetadata;
    }
    if (cleanPath.endsWith('.db') || cleanPath.endsWith('.sqlite')) {
      return ProjectContentStorageDisposition.filesystemCompatibilityMirror;
    }
    final contentType = _projectContentPathPolicyService
        .inferContentTypeFromPath(cleanPath);
    if (storageStrategy == ProjectStorageStrategy.markdownProjectStore) {
      return ProjectContentStorageDisposition.filesystemPrimaryFactSource;
    }
    if (storageStrategy == ProjectStorageStrategy.sqliteProjectStore) {
      return _isStructuredContentType(contentType)
          ? ProjectContentStorageDisposition.filesystemProjection
          : ProjectContentStorageDisposition.filesystemCompatibilityMirror;
    }
    return ProjectContentStorageDisposition.unsupported;
  }

  bool isPrimaryFactSourcePath({
    required ProjectStorageStrategy storageStrategy,
    required String relativePath,
  }) {
    // 中文注释: 这个判断专门给调用方一个“这是主事实源吗”的快捷入口，不让他们自己再解释 disposition。
    return dispositionOfWorkspacePath(
          storageStrategy: storageStrategy,
          relativePath: relativePath,
        ) ==
        ProjectContentStorageDisposition.filesystemPrimaryFactSource;
  }

  bool isProjectionPath({
    required ProjectStorageStrategy storageStrategy,
    required String relativePath,
  }) {
    // 中文注释: SQLite 项目里文件树多数条目会降级成投影，这里保留一个显式判断入口。
    return dispositionOfWorkspacePath(
          storageStrategy: storageStrategy,
          relativePath: relativePath,
        ) ==
        ProjectContentStorageDisposition.filesystemProjection;
  }

  bool isMetadataPath({required String relativePath}) {
    // 中文注释: `.novel_agent/` 下的文件属于工作区元数据，不参与正文主事实源判断。
    final cleanPath = relativePath.trim().replaceAll('\\', '/');
    return cleanPath.startsWith('.novel_agent/');
  }

  bool _isStructuredContentType(String contentType) {
    // 中文注释: 这里维护一份最小的结构化内容类型集合，用来区分 SQLite 项目里的正文投影与兼容镜像。
    switch (_projectContentPathPolicyService.normalizeContentType(
      contentType,
    )) {
      case 'premise':
      case 'chapter':
      case 'scene':
      case 'outline':
      case 'volume_outline':
      case 'chapter_outline':
      case 'setting':
      case 'character':
      case 'style':
      case 'summary':
      case 'knowledge':
      case 'source_original':
      case 'derived_continuation_narrative':
      case 'derived_fanfic_narrative':
      case 'organization_profile':
      case 'foreshadow_record':
      case 'timeline_record':
      case 'relationship_record':
        return true;
      default:
        return false;
    }
  }
}
