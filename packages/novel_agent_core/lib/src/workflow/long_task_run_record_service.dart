import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_mode_service.dart';
import 'long_task_mode_strategy_service.dart';
import 'long_task_run_option_service.dart';
import 'long_task_task_summary_service.dart';
import 'task_runtime_constants.dart';

class LongTaskRunRecordService {
  LongTaskRunRecordService({
    required LongTaskModeService modeService,
    required LongTaskModeStrategyService strategyService,
    required LongTaskRunOptionService optionService,
    required LongTaskTaskSummaryService taskSummaryService,
  }) : _modeService = modeService,
       _strategyService = strategyService,
       _optionService = optionService,
       _taskSummaryService = taskSummaryService;

  final LongTaskModeService _modeService;
  final LongTaskModeStrategyService _strategyService;
  final LongTaskRunOptionService _optionService;
  final LongTaskTaskSummaryService _taskSummaryService;

  JsonMap startRecord(
    JsonMap plan,
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
    String createdAt = '',
  }) {
    // 中文注释: 长任务运行记录只表达调度状态和任务快照，不触碰宿主存储或线程控制。
    final cleanOptions = _optionService.normalizeOptions(options);
    final planId = ValueReaders.stringValue(
      plan['id'],
      ValueReaders.stringValue(options['plan_id'], 'long_task'),
    ).trim();
    var runId = ValueReaders.stringValue(cleanOptions['run_id']).trim();
    if (runId.isEmpty) {
      runId = '${planId}_run';
    }
    final mode = _modeService.normalizeMode(
      ValueReaders.stringValue(
        plan['mode'],
        ValueReaders.stringValue(options['mode']),
      ),
    );
    final snapshots = <JsonMap>[];
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (task.isNotEmpty) {
        snapshots.add(_taskSummaryService.taskSummary(task));
      }
    }
    final now = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    return <String, Object?>{
      'schema_version': 1,
      'kind': 'long_task_run',
      'id': runId,
      'plan_id': planId,
      'mode': mode,
      'runtime_baseline_id': ValueReaders.stringValue(
        cleanOptions['runtime_baseline_id'],
        ValueReaders.stringValue(
          ValueReaders.mapValue(plan['options'])['runtime_baseline_id'],
        ),
      ).trim(),
      'strategy': _strategyService.modeStrategy(mode),
      'status': TaskRuntimeConstants.statusRunning,
      'options': cleanOptions,
      'task_count': snapshots.length,
      'tasks_snapshot': snapshots,
      'steps': <Object?>[],
      'completed_steps': 0,
      'failed_steps': 0,
      'recovery_retry_counts': <String, Object?>{},
      'last_recovery_state': <String, Object?>{},
      'pause_requested': false,
      'stop_reason': '',
      'stop_note': '',
      'guidance_queue': <Object?>[],
      'created_at': now,
      'updated_at': now,
    };
  }
}
