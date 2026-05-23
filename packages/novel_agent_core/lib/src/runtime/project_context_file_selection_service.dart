import '../common/json_types.dart';
import '../common/value_readers.dart';

class ProjectContextFileSelectionService {
  List<String> select(List<JsonMap> entries, {int maxFiles = 12}) {
    // 中文注释: 这里统一决定草稿生成优先读取哪些项目文件，避免宿主层自己散写目录优先级。
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
    return path.endsWith('.md') ||
        path.endsWith('.txt') ||
        path.endsWith('.json') ||
        path.endsWith('.yaml') ||
        path.endsWith('.yml');
  }

  int _priorityOf(String relativePath) {
    // 中文注释: 优先级规则沿着旧项目创作价值排序，让规格、风格和大纲先于杂项文件进入上下文。
    final normalized = relativePath.replaceAll('\\', '/').toLowerCase();
    const weights = <String, int>{
      'specs/': 0,
      'styles/': 1,
      'outline/': 2,
      'volume_outlines/': 3,
      'chapter_outlines/': 4,
      'world/': 5,
      'characters/': 6,
      'summaries/': 7,
      'drafts/': 8,
      'chapters/': 9,
      'knowledge/': 10,
      'inspiration/': 11,
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
