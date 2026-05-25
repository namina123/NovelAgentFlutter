import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_path_policy_service.dart';

class LongTaskProjectFileSectionPlanService {
  LongTaskProjectFileSectionPlanService({
    required LongTaskPathPolicyService pathPolicyService,
  }) : _pathPolicyService = pathPolicyService;

  final LongTaskPathPolicyService _pathPolicyService;

  List<JsonMap> build(JsonMap task) {
    // 中文注释: 长任务执行包优先读取显式任务来源与长期约束路径，这里只负责生成结构化片段计划，不触碰文件系统。
    final metadata = ValueReaders.mapValue(task['metadata']);
    final persistentPaths = _pathPolicyService.stringList(
      metadata['persistent_context_paths'],
    );
    final sourcePaths = _pathPolicyService.stringList(task['source_paths']);
    final focusedPaths = <String>[];
    for (final path in sourcePaths) {
      if (!persistentPaths.contains(path)) {
        focusedPaths.add(path);
      }
    }
    final sections = <JsonMap>[];
    if (persistentPaths.isNotEmpty) {
      sections.add(
        _section(
          id: 'task_persistent_context',
          title: '长期约束',
          source: 'persistent_context_paths',
          priority: 92,
          maxChars: 2200,
          paths: persistentPaths,
        ),
      );
    }
    if (focusedPaths.isNotEmpty) {
      sections.add(
        _section(
          id: 'task_source_paths',
          title: '任务指定来源',
          source: 'source_paths',
          priority: 88,
          maxChars: 2200,
          paths: focusedPaths,
        ),
      );
    }
    return sections;
  }

  JsonMap _section({
    required String id,
    required String title,
    required String source,
    required int priority,
    required int maxChars,
    required List<String> paths,
  }) {
    return <String, Object?>{
      'id': id,
      'title': title,
      'source': source,
      'priority': priority,
      'max_chars': maxChars,
      'paths': paths,
    };
  }
}
