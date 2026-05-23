import '../common/value_readers.dart';

class LongTaskPlanChangedPathsService {
  List<String> changedPaths(
    String planPath,
    String planMarkdownPath,
    List<Object?> createdTasks,
  ) {
    // 中文注释: 计划变更路径只做汇总，供宿主决定哪些文件需要写入或刷新索引。
    final result = <String>[planPath, planMarkdownPath];
    for (final task in ValueReaders.mapList(createdTasks)) {
      final path = ValueReaders.stringValue(task['relative_path']).trim();
      if (path.isNotEmpty) {
        result.add(path);
      }
    }
    return result;
  }
}
