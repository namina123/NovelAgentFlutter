import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_task_summary_service.dart';
import 'task_runtime_constants.dart';

class LongTaskRunStepRecorderService {
  LongTaskRunStepRecorderService({
    required LongTaskTaskSummaryService taskSummaryService,
  }) : _taskSummaryService = taskSummaryService;

  final LongTaskTaskSummaryService _taskSummaryService;

  JsonMap recordStep(
    JsonMap record,
    JsonMap task,
    JsonMap result, {
    String phase = 'model_step',
    String createdAt = '',
  }) {
    // 中文注释: 运行步骤记录只记审计所需摘要，不把完整 response 和任务正文塞进 record。
    final next = ValueReaders.deepCopyMap(record);
    final steps = ValueReaders.objectList(next['steps']);
    final response = ValueReaders.mapValue(result['response']);
    final toolNames = <String>[];
    for (final rawCall in ValueReaders.objectList(response['tool_calls'])) {
      final call = ValueReaders.mapValue(rawCall);
      final name = ValueReaders.stringValue(call['name']).trim();
      if (name.isNotEmpty && !toolNames.contains(name)) {
        toolNames.add(name);
      }
    }
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    steps.add(<String, Object?>{
      'index': steps.length + 1,
      'phase': phase,
      'task': _taskSummaryService.taskSummary(task),
      'ok': ValueReaders.boolValue(result['ok']),
      'error': ValueReaders.stringValue(result['error']),
      'output_paths': ValueReaders.stringList(result['output_paths']),
      'tool_names': toolNames,
      'created_at': now,
    });
    next['steps'] = steps;
    next['completed_steps'] = steps.length;
    next['last_task_id'] = ValueReaders.stringValue(task['id']);
    next['last_task_title'] = ValueReaders.stringValue(task['title']);
    next['last_output_paths'] = ValueReaders.stringList(result['output_paths']);
    next['updated_at'] = now;
    if (!ValueReaders.boolValue(result['ok'])) {
      next['failed_steps'] = ValueReaders.intValue(next['failed_steps']) + 1;
      next['status'] = TaskRuntimeConstants.statusPaused;
      next['stop_reason'] = 'step_failed';
      next['stop_note'] = ValueReaders.stringValue(
        result['error'],
        '任务单步失败，已暂停等待处理。',
      );
    }
    return next;
  }
}
