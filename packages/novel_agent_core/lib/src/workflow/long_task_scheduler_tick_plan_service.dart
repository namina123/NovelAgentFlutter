import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_mode_service.dart';
import 'long_task_next_batch_plan_service.dart';
import 'long_task_recovery_service.dart';
import 'long_task_run_center_contract_service.dart';
import 'task_runtime_constants.dart';

class LongTaskSchedulerTickPlanService {
  LongTaskSchedulerTickPlanService({
    required LongTaskModeService modeService,
    required LongTaskRecoveryService recoveryService,
    required LongTaskNextBatchPlanService nextBatchPlanService,
    required LongTaskRunCenterContractService runCenterContractService,
  }) : _modeService = modeService,
       _recoveryService = recoveryService,
       _nextBatchPlanService = nextBatchPlanService,
       _runCenterContractService = runCenterContractService;

  final LongTaskModeService _modeService;
  final LongTaskRecoveryService _recoveryService;
  final LongTaskNextBatchPlanService _nextBatchPlanService;
  final LongTaskRunCenterContractService _runCenterContractService;

  JsonMap schedulerTickPlan(
    JsonMap record,
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 调度 tick 计划负责把恢复、批次和运行中心合同收束成宿主下一步动作。
    if (!ValueReaders.boolValue(options['worker_enabled'], true)) {
      return _actionForDisabled(record, tasks, options);
    }
    if (ValueReaders.boolValue(options['stop_requested'])) {
      final plan = _basePlan(
        'stop_run',
        'stopped',
        'manual_stop',
        '用户请求停止后台长任务。',
        hostCommand: 'stop_long_task_run',
      );
      plan['should_persist_record'] = true;
      _attachCommon(plan, record, tasks, options);
      return plan;
    }
    if (ValueReaders.boolValue(options['pause_requested'])) {
      final plan = _basePlan(
        'pause',
        'paused',
        'manual_pause',
        '用户请求暂停后台长任务。',
        hostCommand: 'pause_long_task_run',
      );
      plan['requires_user'] = true;
      plan['should_persist_record'] = true;
      _attachCommon(plan, record, tasks, options);
      return plan;
    }
    if (record.isEmpty) {
      return _actionForMissingRecord(record, tasks, options);
    }

    final recovery = _recoveryService.recoveryPlan(
      record,
      tasks,
      options: options,
    );
    final recoveryAction = _actionForRecovery(record, tasks, options, recovery);
    if (recoveryAction.isNotEmpty) {
      return recoveryAction;
    }

    final batch = _nextBatchPlanService.nextBatchPlan(
      record,
      tasks,
      options: options,
    );
    return _actionForBatch(record, tasks, options, batch);
  }

  JsonMap _basePlan(
    String action,
    String state,
    String reason,
    String note, {
    String hostCommand = 'none',
  }) {
    // 中文注释: tick 计划公共字段集中在这里，避免各分支返回格式漂移。
    return <String, Object?>{
      'ok': true,
      'schema_version': 1,
      'action': action,
      'worker_state': state,
      'reason': reason,
      'note': note,
      'host_command': hostCommand,
      'requires_user': false,
      'should_dispatch': false,
      'should_snapshot': true,
      'should_persist_record': false,
      'next_wakeup_msec': 0,
    };
  }

  void _attachCommon(
    JsonMap plan,
    JsonMap record,
    List<Object?> tasks,
    JsonMap options,
  ) {
    // 中文注释: 公共挂件统一在这里拼接，保证任何出口都带上恢复、批次和运行中心视图。
    final recovery = _recoveryService.recoveryPlan(
      record,
      tasks,
      options: options,
    );
    final batch = _nextBatchPlanService.nextBatchPlan(
      record,
      tasks,
      options: options,
    );
    final center = _runCenterContractService.runCenterContract(
      record,
      tasks,
      options: options,
    );
    plan['run_id'] = ValueReaders.stringValue(record['id']);
    plan['run_path'] = ValueReaders.stringValue(record['relative_path']);
    plan['mode'] = _modeFromRecordOptions(record, options);
    plan['record_status'] = ValueReaders.stringValue(
      record['status'],
      TaskRuntimeConstants.statusRunning,
    ).trim();
    plan['task_count'] = tasks.length;
    plan['recovery_plan'] = recovery;
    plan['batch_plan'] = batch;
    plan['run_center_contract'] = center;
  }

  JsonMap _actionForDisabled(
    JsonMap record,
    List<Object?> tasks,
    JsonMap options,
  ) {
    // 中文注释: worker 被禁用时只返回只读信息，不推动任何自动调度。
    final plan = _basePlan(
      'disabled',
      'disabled',
      'worker_disabled',
      '后台调度未启用，宿主不会自动推进长任务。',
    );
    plan['should_snapshot'] = false;
    _attachCommon(plan, record, tasks, options);
    return plan;
  }

  JsonMap _actionForMissingRecord(
    JsonMap record,
    List<Object?> tasks,
    JsonMap options,
  ) {
    // 中文注释: 缺失运行记录时由宿主决定是否允许自动创建新运行。
    final allowStart = ValueReaders.boolValue(options['allow_start_new']);
    final plan = _basePlan(
      allowStart ? 'start_new_run' : 'idle',
      allowStart ? 'ready' : 'idle',
      'record_missing',
      allowStart ? '没有运行记录，宿主可以创建新的长任务运行。' : '没有运行记录，等待用户手动启动长任务。',
      hostCommand: allowStart ? 'start_long_task_run' : 'none',
    );
    plan['requires_user'] = !allowStart;
    plan['should_persist_record'] = allowStart;
    _attachCommon(plan, record, tasks, options);
    return plan;
  }

  JsonMap _actionForRecovery(
    JsonMap record,
    List<Object?> tasks,
    JsonMap options,
    JsonMap recovery,
  ) {
    // 中文注释: 恢复分支优先级高于普通批次规划，避免崩溃遗留状态被直接继续推进。
    final recoveryAction = ValueReaders.stringValue(recovery['action']).trim();
    JsonMap? plan;
    if (recoveryAction == 'resume_when_user_confirms') {
      final autoResume = ValueReaders.boolValue(options['auto_resume_paused']);
      plan = _basePlan(
        autoResume ? 'resume_run' : 'await_user_resume',
        autoResume ? 'ready' : 'paused',
        'record_paused',
        autoResume ? '运行记录处于暂停状态，策略允许自动恢复。' : '运行记录已暂停，等待用户点击继续。',
        hostCommand: autoResume ? 'resume_long_task_run' : 'none',
      );
      plan['requires_user'] = !autoResume;
      plan['should_persist_record'] = autoResume;
    } else if (recoveryAction == 'read_only') {
      plan = _basePlan(
        'read_only',
        'finished',
        'terminal_record',
        '运行记录已经结束，只展示摘要或新建运行。',
      );
      plan['requires_user'] = true;
    } else if (recoveryAction == 'pause_for_failure') {
      plan = _basePlan(
        'pause_for_failure',
        'blocked',
        'failed_task',
        ValueReaders.stringValue(recovery['note'], '检测到失败任务，暂停等待处理。'),
        hostCommand: 'pause_long_task_run',
      );
      plan['requires_user'] = true;
      plan['should_persist_record'] = true;
    } else if (recoveryAction == 'pause_for_repair') {
      plan = _basePlan(
        'pause_for_repair',
        'blocked',
        ValueReaders.stringValue(recovery['reason'], 'repair_required'),
        ValueReaders.stringValue(recovery['note'], '检测到可恢复失败，暂停等待修补。'),
        hostCommand: 'pause_long_task_run',
      );
      plan['requires_user'] = true;
      plan['should_persist_record'] = true;
    } else if (recoveryAction == 'pause_for_manual_attention') {
      plan = _basePlan(
        'pause_for_manual_attention',
        'blocked',
        ValueReaders.stringValue(recovery['reason'], 'manual_attention_required'),
        ValueReaders.stringValue(
          recovery['note'],
          '检测到需要人工介入的内容质量或交付风险。',
        ),
        hostCommand: 'pause_long_task_run',
      );
      plan['requires_user'] = true;
      plan['should_persist_record'] = true;
    } else if (recoveryAction == 'pause_for_review') {
      plan = _basePlan(
        'pause_for_review',
        'blocked',
        'stale_running_task',
        ValueReaders.stringValue(recovery['note'], '检测到疑似崩溃遗留的运行中任务。'),
        hostCommand: 'pause_long_task_run',
      );
      plan['requires_user'] = true;
      plan['should_persist_record'] = true;
    }
    if (plan == null) {
      return <String, Object?>{};
    }
    plan['task'] = ValueReaders.mapValue(recovery['task']);
    _attachCommon(plan, record, tasks, options);
    plan['recovery_plan'] = recovery;
    return plan;
  }

  JsonMap _actionForBatch(
    JsonMap record,
    List<Object?> tasks,
    JsonMap options,
    JsonMap batch,
  ) {
    // 中文注释: 普通 tick 最终动作完全由批次规划结果驱动，宿主只执行合同。
    final action = ValueReaders.stringValue(batch['action']).trim();
    late final JsonMap plan;
    if (action == 'dispatch_batch') {
      plan = _basePlan(
        'dispatch_batch',
        'ready',
        ValueReaders.stringValue(batch['boundary_reason'], 'ready_batch'),
        ValueReaders.stringValue(batch['note'], '下一批任务可以交给宿主逐步执行。'),
        hostCommand: 'run_long_task_batch',
      );
      plan['should_dispatch'] = true;
      plan['should_persist_record'] = true;
      plan['dispatch_options'] = _dispatchOptionsFromBatch(batch, options);
      plan['dispatch_task_ids'] = ValueReaders.objectList(batch['task_ids']);
      plan['dispatch_task_paths'] = ValueReaders.objectList(
        batch['task_paths'],
      );
      plan['next_wakeup_msec'] = ValueReaders.intValue(
        options['dispatch_wakeup_msec'],
        250,
      ).clamp(0, 60000);
    } else if (action == 'wait_user') {
      plan = _basePlan(
        'await_user',
        'blocked',
        ValueReaders.stringValue(batch['reason'], 'waiting_user'),
        ValueReaders.stringValue(batch['note'], '长任务等待用户处理。'),
      );
      plan['requires_user'] = true;
      plan['task'] = ValueReaders.mapValue(batch['task']);
    } else if (action == 'pause') {
      plan = _basePlan(
        'pause',
        'paused',
        ValueReaders.stringValue(batch['reason'], 'manual_pause'),
        ValueReaders.stringValue(batch['note'], '长任务已暂停。'),
        hostCommand: 'pause_long_task_run',
      );
      plan['requires_user'] = true;
      plan['should_persist_record'] = true;
    } else if (action == 'finish') {
      plan = _basePlan(
        'finish_run',
        'finished',
        ValueReaders.stringValue(batch['reason'], 'completed'),
        ValueReaders.stringValue(batch['note'], '长任务队列已完成。'),
        hostCommand: 'finish_long_task_run',
      );
      plan['should_persist_record'] = true;
    } else if (action == 'stop') {
      plan = _basePlan(
        'stop_run',
        'stopped',
        ValueReaders.stringValue(batch['reason'], 'manual_stop'),
        ValueReaders.stringValue(batch['note'], '用户请求停止长任务。'),
        hostCommand: 'stop_long_task_run',
      );
      plan['should_persist_record'] = true;
    } else {
      plan = _basePlan('idle', 'idle', 'no_dispatch', '当前没有需要后台调度的任务。');
    }
    _attachCommon(plan, record, tasks, options);
    plan['batch_plan'] = batch;
    return plan;
  }

  JsonMap _dispatchOptionsFromBatch(JsonMap batchPlan, JsonMap options) {
    // 中文注释: 派发参数继承宿主运行选项，但允许批次规划收紧本轮步数和原因。
    return <String, Object?>{
      ...ValueReaders.deepCopyMap(options),
      'max_steps': ValueReaders.intValue(
        batchPlan['recommended_max_steps'],
        ValueReaders.intValue(options['max_steps'], 1),
      ).clamp(1, 80),
      'max_seconds': ValueReaders.intValue(
        batchPlan['max_seconds'],
        ValueReaders.intValue(options['max_seconds'], 7200),
      ).clamp(30, 86400),
      'long_task_batch_action': ValueReaders.stringValue(batchPlan['action']),
      'long_task_batch_reason': ValueReaders.stringValue(
        batchPlan['boundary_reason'],
        ValueReaders.stringValue(batchPlan['reason']),
      ),
    };
  }

  String _modeFromRecordOptions(JsonMap record, JsonMap options) {
    // 中文注释: 调度计划需要带上规范化模式，方便宿主在无额外上下文时直接渲染。
    final rawMode = ValueReaders.stringValue(
      options['mode'],
      ValueReaders.stringValue(record['mode']),
    );
    return _modeService.normalizeMode(rawMode);
  }
}
