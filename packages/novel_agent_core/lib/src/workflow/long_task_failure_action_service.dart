import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_run_lifecycle_service.dart';
import 'task_runtime_constants.dart';

class LongTaskFailureActionService {
  LongTaskFailureActionService({
    required LongTaskRunLifecycleService lifecycleService,
  }) : _lifecycleService = lifecycleService;

  final LongTaskRunLifecycleService _lifecycleService;

  JsonMap failureAction(
    JsonMap record,
    JsonMap task,
    String command, {
    JsonMap options = const <String, Object?>{},
    String createdAt = '',
  }) {
    // 中文注释: 失败处理只生成建议状态和新 record，不直接修改原任务文件，由宿主后续应用。
    final clean = command.trim().toLowerCase();
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    if (clean == 'retry') {
      return <String, Object?>{
        'ok': true,
        'command': clean,
        'created_at': now,
        'task': _taskSummary(task),
        'record': _lifecycleService.resumeRecord(
          record,
          note: '失败任务将重试，调度器会从当前任务状态继续。',
          createdAt: now,
        ),
        'task_status': TaskRuntimeConstants.statusQueued,
        'note': '将失败任务重新排队。',
      };
    }
    if (clean == 'skip') {
      return <String, Object?>{
        'ok': true,
        'command': clean,
        'created_at': now,
        'task': _taskSummary(task),
        'record': _lifecycleService.resumeRecord(
          record,
          note: '用户选择跳过失败任务。',
          createdAt: now,
        ),
        'task_status': TaskRuntimeConstants.statusCancelled,
        'note': '将失败任务标记为取消，后续依赖是否可运行由任务依赖决定。',
      };
    }
    if (clean == 'cancel') {
      return <String, Object?>{
        'ok': true,
        'command': clean,
        'created_at': now,
        'task': _taskSummary(task),
        'record': _lifecycleService.finishRecord(
          record,
          reason: 'cancelled',
          note: '用户取消长任务运行。',
          createdAt: now,
        ),
        'task_status': TaskRuntimeConstants.statusCancelled,
        'note': '取消整个长任务运行。',
      };
    }
    return <String, Object?>{
      'ok': true,
      'command': clean,
      'created_at': now,
      'task': _taskSummary(task),
      'record': _lifecycleService.pauseRecord(
        record,
        reason: 'failed_task',
        note: ValueReaders.stringValue(options['note'], '失败任务暂停等待处理。'),
        createdAt: now,
      ),
      'task_status': TaskRuntimeConstants.statusFailed,
      'note': '保持暂停，等待用户选择重试、跳过或取消。',
    };
  }

  JsonMap _taskSummary(JsonMap task) {
    // 中文注释: 失败动作回包里只保留面向控制台或按钮动作需要的最小任务信息。
    return <String, Object?>{
      'id': ValueReaders.stringValue(task['id']),
      'title': ValueReaders.stringValue(task['title']),
      'task_type': ValueReaders.stringValue(task['task_type']),
      'status': ValueReaders.stringValue(task['status']),
      'relative_path': ValueReaders.stringValue(task['relative_path']),
    };
  }
}
