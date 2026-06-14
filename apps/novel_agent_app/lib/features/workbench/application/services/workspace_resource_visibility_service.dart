import 'package:novel_agent_core/novel_agent_core.dart';

class WorkspaceResourceVisibilityService {
  const WorkspaceResourceVisibilityService();

  static const List<String> _legacyCompatibilityRoots = <String>[
    'drafts',
    'specs',
    'characters',
    'inspiration',
  ];

  bool shouldHideFromDefaultTree(String relativePath) {
    // 中文注释: 默认资源树只展示正式用户主目录，旧兼容根和系统文件继续保留可读，但不再直接暴露在主树里。
    final cleanPath = _normalizePath(relativePath).toLowerCase();
    if (cleanPath.isEmpty) {
      return false;
    }
    if (cleanPath == ProjectManifestCodecService.manifestRelativePath) {
      return true;
    }
    if (ProjectWorkspaceCatalog.isInternalWorkspacePath(cleanPath)) {
      return true;
    }
    if (ProjectWorkspaceCatalog.isAdvancedWorkspacePath(cleanPath)) {
      return true;
    }
    if (isLegacyCompatibilityPath(cleanPath)) {
      return true;
    }
    if (cleanPath.endsWith('.db') || cleanPath.endsWith('.sqlite')) {
      return true;
    }
    if (cleanPath.endsWith('.json') || cleanPath.endsWith('.jsonl')) {
      return true;
    }
    if (cleanPath == 'readme.md') {
      return true;
    }
    if (RegExp(r'^[^/]+/readme\.md$').hasMatch(cleanPath)) {
      return true;
    }
    return false;
  }

  bool isLegacyCompatibilityPath(String relativePath) {
    final cleanPath = _normalizePath(relativePath).toLowerCase();
    if (cleanPath.isEmpty) {
      return false;
    }
    for (final root in _legacyCompatibilityRoots) {
      if (cleanPath == root || cleanPath.startsWith('$root/')) {
        return true;
      }
    }
    return false;
  }

  String _normalizePath(String relativePath) {
    return relativePath
        .trim()
        .replaceAll('\\', '/')
        .replaceAll(RegExp(r'/+$'), '');
  }
}
