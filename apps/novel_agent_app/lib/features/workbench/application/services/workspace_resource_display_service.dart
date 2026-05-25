import 'package:novel_agent_core/novel_agent_core.dart';

class WorkspaceResourceDisplayService {
  const WorkspaceResourceDisplayService();

  String titleOf(String relativePath, {required bool isDirectory}) {
    // 中文注释: 资源树展示名只负责把真实英文目录映射为中文显示，不改变任何底层真实路径。
    final cleanPath = _normalizePath(relativePath);
    if (cleanPath.isEmpty) {
      return '';
    }
    if (isDirectory) {
      final label = _directoryLabelOf(cleanPath);
      if (label.isNotEmpty) {
        return label;
      }
    }
    final segments = cleanPath.split('/');
    return segments.isEmpty ? cleanPath : segments.last;
  }

  bool shouldHidePath(String relativePath) {
    // 中文注释: 资源树默认隐藏内部元数据和无意义占位文件，避免用户误改系统文件或被旧骨架噪音干扰。
    final cleanPath = _normalizePath(relativePath).toLowerCase();
    if (cleanPath.isEmpty) {
      return false;
    }
    if (cleanPath == ProjectManifestCodecService.manifestRelativePath) {
      return true;
    }
    if (cleanPath.startsWith('.novel_agent/')) {
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

  int compareEntries(JsonMap left, JsonMap right) {
    // 中文注释: 资源树排序先按用户认知中的顶层分区，再保证目录优先和稳定字典序。
    final leftPath = _normalizePath(left['relative_path']?.toString() ?? '');
    final rightPath = _normalizePath(right['relative_path']?.toString() ?? '');
    final leftIsDirectory = left['is_dir'] == true;
    final rightIsDirectory = right['is_dir'] == true;
    final leftParent = _parentPathOf(leftPath);
    final rightParent = _parentPathOf(rightPath);
    if (leftParent.isEmpty && rightParent.isEmpty) {
      final topLevelOrder = _topLevelWorkspaceOrder();
      final leftRank = topLevelOrder.indexOf(leftPath.split('/').first);
      final rightRank = topLevelOrder.indexOf(rightPath.split('/').first);
      if (leftRank >= 0 || rightRank >= 0) {
        if (leftRank < 0) {
          return 1;
        }
        if (rightRank < 0) {
          return -1;
        }
        final compareRank = leftRank.compareTo(rightRank);
        if (compareRank != 0) {
          return compareRank;
        }
      }
    }
    if (leftIsDirectory != rightIsDirectory) {
      return leftIsDirectory ? -1 : 1;
    }
    return leftPath.compareTo(rightPath);
  }

  List<String> likelyOutlineDocumentCandidates() {
    // 中文注释: 新旧目录都保留候选列表，确保目录骨架迁移阶段用户仍能一键打开最可能的大纲文件。
    return const <String>[
      'outlines/story/story_outline.md',
      'outlines/story/project_outline.md',
      'outlines/volumes/index.md',
      'outlines/chapters/index.md',
      'outline/outline.md',
      'outline/project_outline.md',
      'volume_outlines/index.md',
      'chapter_outlines/index.md',
    ];
  }

  String _directoryLabelOf(String relativePath) {
    final cleanPath = _normalizePath(relativePath);
    for (final descriptor
        in ProjectWorkspaceCatalog.resourceTreeDirectoryDescriptors) {
      final descriptorPath = _normalizeDirectoryPath(descriptor.path);
      if (descriptorPath == cleanPath) {
        return descriptor.name;
      }
    }
    return '';
  }

  List<String> _topLevelWorkspaceOrder() {
    final orderedRoots = <String>[];
    for (final descriptor
        in ProjectWorkspaceCatalog.resourceTreeDirectoryDescriptors) {
      final root = _normalizeDirectoryPath(descriptor.path).split('/').first;
      if (root.isNotEmpty && !orderedRoots.contains(root)) {
        orderedRoots.add(root);
      }
    }
    return orderedRoots;
  }

  String _parentPathOf(String relativePath) {
    final slashIndex = relativePath.lastIndexOf('/');
    if (slashIndex <= 0) {
      return '';
    }
    return relativePath.substring(0, slashIndex);
  }

  String _normalizePath(String relativePath) {
    return relativePath.trim().replaceAll('\\', '/');
  }

  String _normalizeDirectoryPath(String relativePath) {
    return _normalizePath(relativePath).replaceAll(RegExp(r'/+$'), '');
  }
}
