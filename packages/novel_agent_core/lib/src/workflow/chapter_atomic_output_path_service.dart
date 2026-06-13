import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_planning_artifact_path_service.dart';

class ChapterAtomicOutputPathService {
  ChapterAtomicOutputPathService({
    LongTaskPlanningArtifactPathService? planningArtifactPathService,
  }) : _planningArtifactPathService =
           planningArtifactPathService ??
           const LongTaskPlanningArtifactPathService();

  final LongTaskPlanningArtifactPathService _planningArtifactPathService;

  Map<String, Object?> proposedOutputPaths(JsonMap task) {
    // 中文注释: 拟写入路径只是计划合同，不表示已经真实落盘，因此在 core 里单独生成。
    final title = artifactTitle(task);
    final taskType = ValueReaders.stringValue(task['task_type'], 'chapter');
    if (_isPlanningStageWorkflowTask(task)) {
      if (taskType == 'planning') {
        return <String, Object?>{
          'spec': LongTaskPlanningArtifactPathService.projectSpecPath,
          'outline': _planningArtifactPathService.storyOutlinePath(),
          'chapter_plan': _planningArtifactPathService.chapterPlanPath(),
        };
      }
      return <String, Object?>{
        'primary': _firstOrDefault(
          ValueReaders.stringList(task['output_paths']),
          'outlines/story/$title.md',
        ),
        'planning_note': 'tracking/planning/$title.md',
        'memory_note': 'tracking/memory_updates/$title.md',
      };
    }
    switch (taskType) {
      case 'summary':
        return <String, Object?>{
          'summary': 'summaries/$title.md',
          'run_record': 'runs/<date>/<run_id>.json',
        };
      case 'revision':
        return <String, Object?>{
          'target': _firstOrDefault(
            ValueReaders.stringList(task['output_paths']),
            'chapters/$title.md',
          ),
          'backup': 'backups/<target>.<timestamp>.bak',
          'review': 'reviews/general/${title}_revision.md',
        };
      case 'review':
        final metadata = ValueReaders.mapValue(task['metadata']);
        var reviewType = ValueReaders.stringValue(
          metadata['review_type'],
          'general',
        ).trim();
        if (reviewType.isEmpty) {
          reviewType = 'general';
        }
        return <String, Object?>{
          'report': 'reviews/$reviewType/$title.md',
          'report_json': 'reviews/$reviewType/$title.json',
        };
      case 'planning':
        return <String, Object?>{
          'spec': LongTaskPlanningArtifactPathService.projectSpecPath,
          'outline': _planningArtifactPathService.storyOutlinePath(),
          'chapter_plan': _planningArtifactPathService.chapterPlanPath(),
        };
      case 'checkpoint':
        return <String, Object?>{
          'checkpoint_note': 'tracking/checkpoints/$title.md',
        };
      case 'world_update':
        return <String, Object?>{
          'world': 'world/$title.md',
          'tracking': 'tracking/memory_updates/$title.md',
        };
      default:
        return <String, Object?>{
          'chapter': _firstOrDefault(
            ValueReaders.stringList(task['output_paths']),
            'chapters/$title.md',
          ),
          'summary': 'summaries/$title.summary.md',
          'memory_note': 'tracking/memory_updates/$title.md',
          'review': 'reviews/continuity/$title.md',
        };
    }
  }

  String artifactTitle(JsonMap task) {
    // 中文注释: 产物标题优先使用章节名，没有时回退任务标题，再收敛成安全文件名片段。
    var value = ValueReaders.stringValue(task['chapter']).trim();
    if (value.isEmpty) {
      value = ValueReaders.stringValue(task['title'], 'chapter').trim();
    }
    return safeId(value.isEmpty ? 'chapter' : value);
  }

  String safeId(String value) {
    // 中文注释: 执行包和产物路径共享同一套安全 id 规则，避免写出无效文件名。
    var result = value.trim();
    for (final token in const <String>[
      '\\',
      '/',
      ':',
      '*',
      '?',
      '"',
      '<',
      '>',
      '|',
      '\n',
      '\r',
      '\t',
      ' ',
    ]) {
      result = result.replaceAll(token, '_');
    }
    if (result.isEmpty) {
      result = 'item_${DateTime.now().microsecondsSinceEpoch}';
    }
    if (result.length > 80) {
      result = result.substring(0, 80);
    }
    return result;
  }

  String firstWritableTarget(JsonMap task) {
    // 中文注释: 这个入口给后处理或宿主层拿默认目标路径时复用，不必重复推导。
    if (_isPlanningStageWorkflowTask(task)) {
      return _firstOrDefault(
        ValueReaders.stringList(task['output_paths']),
        ValueReaders.stringValue(task['task_type']).trim() == 'planning'
            ? LongTaskPlanningArtifactPathService.projectSpecPath
            : 'outlines/story/${artifactTitle(task)}.md',
      );
    }
    return _firstOrDefault(
      ValueReaders.stringList(task['output_paths']),
      'chapters/${artifactTitle(task)}.md',
    );
  }

  bool _isPlanningStageWorkflowTask(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    if (ValueReaders.stringValue(metadata['stage']).trim() != 'planning') {
      return false;
    }
    if (ValueReaders.stringValue(task['task_type']).trim() == 'planning') {
      return true;
    }
    if (ValueReaders.stringValue(metadata['plan_id']).trim().isNotEmpty ||
        ValueReaders.stringValue(
          metadata['runtime_baseline_id'],
        ).trim().isNotEmpty) {
      return true;
    }
    final generatedBy = ValueReaders.stringValue(
      metadata['generated_by'],
    ).trim();
    return generatedBy == 'LongTaskPlanner' ||
        generatedBy == 'LongTaskRevision';
  }

  String _firstOrDefault(List<String> values, String fallback) {
    // 中文注释: 只取第一个非空路径作为默认目标，保持执行包合同清晰。
    for (final value in values) {
      final text = value.trim();
      if (text.isNotEmpty) {
        return text;
      }
    }
    return fallback;
  }
}
