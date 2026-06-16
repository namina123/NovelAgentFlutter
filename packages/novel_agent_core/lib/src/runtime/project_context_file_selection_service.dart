import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../information/information_projection_document.dart';
import '../project/project_support_document_catalog.dart';

class ProjectContextFileSelectionService {
  List<String> select(List<JsonMap> entries, {int maxFiles = 12}) {
    // 中文注释: 这里统一决定内容生成优先读取哪些项目文件，避免宿主层自己散写目录优先级。
    final candidates = entries.where(_isTextFile).toList(growable: false);
    final sorted = candidates.toList()
      ..sort((left, right) => _compare(left, right));
    return sorted
        .take(maxFiles)
        .map((entry) => ValueReaders.stringValue(entry['relative_path']))
        .where((path) => path.trim().isNotEmpty)
        .toList(growable: false);
  }

  int _compare(JsonMap left, JsonMap right) {
    // 中文注释: 文件排序优先考虑目录价值，其次考虑层级和路径名，尽量保持上下文稳定。
    final leftPath = ValueReaders.stringValue(left['relative_path']);
    final rightPath = ValueReaders.stringValue(right['relative_path']);
    final priorityCompare = _priorityOf(
      leftPath,
    ).compareTo(_priorityOf(rightPath));
    if (priorityCompare != 0) {
      return priorityCompare;
    }
    final depthCompare = _depthOf(leftPath).compareTo(_depthOf(rightPath));
    if (depthCompare != 0) {
      return depthCompare;
    }
    return leftPath.compareTo(rightPath);
  }

  bool _isTextFile(JsonMap entry) {
    // 中文注释: 当前只把常见文本文件纳入上下文候选，避免把二进制素材误读进提示词。
    if (ValueReaders.boolValue(entry['is_dir'])) {
      return false;
    }
    final path = ValueReaders.stringValue(entry['relative_path']).toLowerCase();
    if (_isInformationProjectionPath(path)) {
      return false;
    }
    if (ProjectSupportDocumentCatalog.isProjectOverviewPath(path)) {
      return false;
    }
    return path.endsWith('.md') ||
        path.endsWith('.txt') ||
        path.endsWith('.json') ||
        path.endsWith('.yaml') ||
        path.endsWith('.yml');
  }

  bool _isInformationProjectionPath(String normalizedLowerPath) {
    // 中文注释: information projection 已由结构化 activation bridge 单独注入，这里跳过可避免双源重复占预算。
    const projectionPaths = <String>{
      InformationProjectionDocument.knowledgeSummaryRelativePath,
      InformationProjectionDocument.designSummaryRelativePath,
      InformationProjectionDocument.researchSummaryRelativePath,
      InformationProjectionDocument.referenceBoundaryRelativePath,
    };
    return projectionPaths.contains(normalizedLowerPath);
  }

  int _priorityOf(String relativePath) {
    // 中文注释: 优先级规则沿着旧项目创作价值排序，让规格、风格和大纲先于杂项文件进入上下文。
    final normalized = relativePath.replaceAll('\\', '/').toLowerCase();
    const weights = <String, int>{
      'premise/': 0,
      'specs/': 0,
      'assets/styles/': 1,
      'styles/': 1,
      'outlines/story/': 2,
      'outline/': 2,
      'outlines/volumes/': 3,
      'volume_outlines/': 3,
      'outlines/chapters/': 4,
      'chapter_outlines/': 4,
      'assets/world/': 5,
      'world/': 5,
      'assets/characters/': 6,
      'assets/foreshadows/': 7,
      'world/foreshadows/': 7,
      'assets/timeline/': 8,
      'assets/relationships/': 9,
      'characters/': 18,
      'summaries/': 10,
      'chapters/': 11,
      'scenes/': 12,
      'knowledge/': 13,
      'inspiration/': 14,
    };
    for (final entry in weights.entries) {
      if (normalized.startsWith(entry.key)) {
        return entry.value;
      }
    }
    return 99;
  }

  int _depthOf(String relativePath) {
    // 中文注释: 同目录下优先浅层文件，可以降低一次读取过多局部碎片的概率。
    return relativePath
        .split('/')
        .where((part) => part.trim().isNotEmpty)
        .length;
  }
}
