import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../workflow/long_task_run_path_service.dart';
import '../workflow/long_task_run_plan_identity_service.dart';
import '../workflow/long_task_run_record_service.dart';

class StartLongTaskRunUseCase {
  StartLongTaskRunUseCase({
    required LongTaskRunPlanIdentityService planIdentityService,
    required LongTaskRunRecordService runRecordService,
    required LongTaskRunPathService runPathService,
  }) : _planIdentityService = planIdentityService,
       _runRecordService = runRecordService,
       _runPathService = runPathService;

  final LongTaskRunPlanIdentityService _planIdentityService;
  final LongTaskRunRecordService _runRecordService;
  final LongTaskRunPathService _runPathService;

  JsonMap execute(
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
    JsonMap plan = const <String, Object?>{},
    String createdAt = '',
  }) {
    // 中文注释: 这个用例生成共享长任务运行记录与路径合同，但不处理任何文件写入。
    final resolvedPlan = plan.isEmpty
        ? _planIdentityService.planFromTasks(tasks, options: options)
        : ValueReaders.deepCopyMap(plan);
    final record = _runRecordService.startRecord(
      resolvedPlan,
      tasks,
      options: options,
      createdAt: createdAt,
    );
    final paths = _runPathService.buildPaths(
      ValueReaders.stringValue(record['id']),
    );
    final nextRecord = ValueReaders.deepCopyMap(record)
      ..['relative_path'] = paths['relative_path']
      ..['summary_path'] = paths['summary_path'];
    return <String, Object?>{
      'ok': true,
      'run_id': paths['run_id'],
      'relative_path': paths['relative_path'],
      'summary_path': paths['summary_path'],
      'record': nextRecord,
      'options': nextRecord['options'],
      'plan': resolvedPlan,
    };
  }
}
