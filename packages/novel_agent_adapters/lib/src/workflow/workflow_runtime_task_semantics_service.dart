import 'package:novel_agent_core/novel_agent_core.dart';

class WorkflowRuntimeTaskSemanticsService {
  WorkflowRuntimeTaskSemanticsService({
    LongTaskModeService? longTaskModeService,
  }) : _longTaskModeService = longTaskModeService ?? LongTaskModeService();

  final LongTaskModeService _longTaskModeService;

  String semanticTaskType(JsonMap task) {
    final rawTaskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    if (rawTaskType.isEmpty || rawTaskType != 'agent_task') {
      return rawTaskType.isEmpty ? 'chapter' : rawTaskType;
    }
    final metadata = ValueReaders.mapValue(task['metadata']);
    final stage = ValueReaders.stringValue(metadata['stage']).trim();
    if (stage == 'planning' && _isLongTaskManagedWorkflowTask(task)) {
      return 'planning';
    }
    return rawTaskType;
  }

  JsonMap taskForRuntime(JsonMap task) {
    final rawTaskType = ValueReaders.stringValue(
      task['task_type'],
      'chapter',
    ).trim();
    final semanticType = semanticTaskType(task);
    if (semanticType == rawTaskType) {
      return ValueReaders.deepCopyMap(task);
    }
    final next = ValueReaders.deepCopyMap(task);
    final metadata = ValueReaders.deepCopyMap(
      ValueReaders.mapValue(task['metadata']),
    );
    metadata['runtime_semantic_task_type'] = semanticType;
    metadata['runtime_semantic_task_type_origin'] = rawTaskType;
    next['task_type'] = semanticType;
    next['metadata'] = metadata;
    return next;
  }

  bool _isLongTaskManagedWorkflowTask(JsonMap task) {
    final metadata = ValueReaders.mapValue(task['metadata']);
    if (ValueReaders.stringValue(metadata['plan_id']).trim().isNotEmpty ||
        ValueReaders.stringValue(
          metadata['runtime_baseline_id'],
        ).trim().isNotEmpty ||
        ValueReaders.stringValue(metadata['generated_by']).trim() ==
            'LongTaskPlanner') {
      return true;
    }
    final mode = _longTaskModeService.normalizeMode(
      ValueReaders.stringValue(task['mode']),
    );
    return mode == TaskRuntimeConstants.modeSeedToFullNovel ||
        mode == TaskRuntimeConstants.modeSupervisedChapterQueue;
  }
}
