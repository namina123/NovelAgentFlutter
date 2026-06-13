import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../review/repair_lane_blocking_service.dart';
import '../review/repair_outcome.dart';
import '../review/repair_request.dart';
import '../review/repair_task.dart';
import '../runtime/long_task_run_status.dart';
import '../runtime/long_task_stop_outcome.dart';
import '../runtime/long_task_stop_outcome_resolver_service.dart';
import 'chapter_delivery_state_statuses.dart';
import 'long_task_recovery_state.dart';
import 'long_task_writing_execution_signal_service.dart';
import 'task_runtime_constants.dart';

class LongTaskRecoveryStateMachineService {
  const LongTaskRecoveryStateMachineService({
    LongTaskWritingExecutionSignalService? writingExecutionSignalService,
    LongTaskStopOutcomeResolverService? stopOutcomeResolverService,
    RepairLaneBlockingService? repairLaneBlockingService,
  }) : _writingExecutionSignalService =
           writingExecutionSignalService ??
           const LongTaskWritingExecutionSignalService(),
       _stopOutcomeResolverService =
           stopOutcomeResolverService ??
           const LongTaskStopOutcomeResolverService(),
       _repairLaneBlockingService =
           repairLaneBlockingService ?? const RepairLaneBlockingService();

  final LongTaskWritingExecutionSignalService _writingExecutionSignalService;
  final LongTaskStopOutcomeResolverService _stopOutcomeResolverService;
  final RepairLaneBlockingService _repairLaneBlockingService;

  LongTaskRecoveryState stateForRecord(
    JsonMap record,
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 恢复状态机只消费结构化 record/task/repair 合同，正式区分 retry、repair、waiting_user 与 exhausted。
    final mergedOptions = _mergedOptions(record, options);
    final retryBudget = _retryBudget(mergedOptions);
    if (record.isEmpty) {
      return LongTaskRecoveryState(
        present: true,
        state: LongTaskRecoveryStates.idle,
        runStatus: LongTaskRunStatus.readyToStart.id,
        recommendedAction: 'start_new',
        reason: 'record_missing',
        note: '没有可恢复的长任务运行记录。',
        retryBudget: retryBudget,
        retriesRemaining: retryBudget,
      );
    }
    final repairState = _repairBlockingState(record, options, retryBudget);
    if (repairState.present) {
      return repairState;
    }
    final status = ValueReaders.stringValue(
      record['status'],
      TaskRuntimeConstants.statusRunning,
    ).trim();
    final signal = _writingExecutionSignalService.signalFromPayload(
      record: record,
      stopReason: ValueReaders.stringValue(record['stop_reason']),
      fallbackNote: ValueReaders.stringValue(record['stop_note']),
    );
    if (_isPausedBudgetRecord(record)) {
      return LongTaskRecoveryState(
        present: true,
        state: LongTaskRecoveryStates.resumeReady,
        runStatus: LongTaskRunStatus.running.id,
        recommendedAction: 'resume_dispatch',
        reason: 'budget_failed',
        note: ValueReaders.stringValue(record['stop_reason']) == 'max_seconds'
            ? '上次运行达到时长预算边界，可从当前任务状态继续调度。'
            : '上次运行达到步数预算边界，可从当前任务状态继续调度。',
        retryBudget: retryBudget,
        retriesRemaining: retryBudget,
        stopOutcome: _stopOutcomeResolverService.fromLegacyStopReason(
          ValueReaders.stringValue(record['stop_reason']),
        ),
      );
    }
    if (_requiresWaitingUser(record, signal)) {
      return LongTaskRecoveryState(
        present: true,
        state: LongTaskRecoveryStates.waitingUser,
        runStatus: LongTaskRunStatus.waitingGate.id,
        recommendedAction: 'resume_when_user_confirms',
        reason: _waitingUserReason(record, signal),
        note: _signalOrRecordNote(
          signal,
          record,
          fallback: '运行记录已暂停，需要用户确认继续。',
        ),
        waitingUser: true,
        blocksProgress: true,
        retryBudget: retryBudget,
        retriesRemaining: retryBudget,
        stopOutcome: _stopOutcomeFromSignal(signal),
      );
    }
    if (_requiresManualAttention(record, signal)) {
      return LongTaskRecoveryState(
        present: true,
        state: LongTaskRecoveryStates.manualAttention,
        runStatus: LongTaskRunStatus.failedManualAttention.id,
        recommendedAction: 'pause_for_manual_attention',
        reason: _manualAttentionReason(record, signal),
        note: _signalOrRecordNote(
          signal,
          record,
          fallback: '最近一步的结构化结果要求人工介入。',
        ),
        manualAttentionRequired: true,
        blocksProgress: true,
        retryBudget: retryBudget,
        retriesRemaining: retryBudget,
        stopOutcome: _stopOutcomeFromSignal(signal),
      );
    }
    if (_requiresRepair(record, signal)) {
      return LongTaskRecoveryState(
        present: true,
        state: LongTaskRecoveryStates.repairRequired,
        runStatus: LongTaskRunStatus.recovering.id,
        recommendedAction: 'pause_for_repair',
        reason: _repairReason(record, signal),
        note: _signalOrRecordNote(
          signal,
          record,
          fallback: '最近一步的结构化结果要求先进入 repair/recovery。',
        ),
        requiresRepair: true,
        blocksProgress: true,
        retryBudget: retryBudget,
        retriesRemaining: retryBudget,
        stopOutcome: _stopOutcomeFromSignal(signal),
      );
    }
    if (<String>[
      TaskRuntimeConstants.statusSucceeded,
      TaskRuntimeConstants.statusFailed,
      TaskRuntimeConstants.statusCancelled,
    ].contains(status)) {
      return LongTaskRecoveryState(
        present: true,
        state: LongTaskRecoveryStates.terminal,
        runStatus: LongTaskRunStatus.stopped.id,
        recommendedAction: 'read_only',
        reason: 'terminal_record',
        note: '运行记录已经结束，只能查看或新建运行。',
        retryBudget: retryBudget,
        retriesRemaining: retryBudget,
      );
    }
    final failedTask = _firstTaskWithStatus(tasks, TaskRuntimeConstants.statusFailed);
    if (failedTask.isNotEmpty) {
      final taskId = ValueReaders.stringValue(failedTask['id']).trim();
      final retryCount = _retryCountForTask(record, taskId);
      final retriesRemaining = retryBudget <= retryCount
          ? 0
          : retryBudget - retryCount;
      final autoRetryEligible = _isAutoRetryEligible(signal, mergedOptions);
      if (autoRetryEligible && retriesRemaining > 0) {
        return LongTaskRecoveryState(
          present: true,
          state: LongTaskRecoveryStates.readyRetry,
          runStatus: LongTaskRunStatus.recovering.id,
          recommendedAction: 'auto_retry_failed_task',
          reason: 'auto_retry_failed_task',
          note: '检测到可重试失败，恢复状态机会在预算内自动重试当前失败任务。',
          retryCount: retryCount,
          retryBudget: retryBudget,
          retriesRemaining: retriesRemaining,
          autoRetryEligible: true,
          blocksProgress: true,
          taskId: taskId,
          taskTitle: ValueReaders.stringValue(failedTask['title']).trim(),
          taskPath: ValueReaders.stringValue(
            failedTask['relative_path'],
          ).trim(),
          stopOutcome: _stopOutcomeFromSignal(signal),
        );
      }
      if (autoRetryEligible && retriesRemaining <= 0) {
        return _exhaustedState(
          disposition: _exhaustedDisposition(mergedOptions),
          retryCount: retryCount,
          retryBudget: retryBudget,
          failedTask: failedTask,
        );
      }
      return LongTaskRecoveryState(
        present: true,
        state: LongTaskRecoveryStates.pausedFailure,
        runStatus: LongTaskRunStatus.paused.id,
        recommendedAction: 'pause_for_failure',
        reason: 'failed_task',
        note: '检测到失败任务，应先重试、跳过或人工修复。',
        retryCount: retryCount,
        retryBudget: retryBudget,
        retriesRemaining: retriesRemaining,
        autoRetryEligible: autoRetryEligible,
        blocksProgress: true,
        taskId: taskId,
        taskTitle: ValueReaders.stringValue(failedTask['title']).trim(),
        taskPath: ValueReaders.stringValue(
          failedTask['relative_path'],
        ).trim(),
        stopOutcome: _stopOutcomeFromSignal(signal),
      );
    }
    final runningTask = _firstTaskWithStatus(
      tasks,
      TaskRuntimeConstants.statusRunning,
    );
    if (runningTask.isNotEmpty &&
        ValueReaders.boolValue(mergedOptions['safe_after_crash'], true)) {
      return LongTaskRecoveryState(
        present: true,
        state: LongTaskRecoveryStates.reviewRequired,
        runStatus: LongTaskRunStatus.paused.id,
        recommendedAction: 'pause_for_review',
        reason: 'stale_running_task',
        note: '检测到上次退出时仍在运行的任务，为避免重复写入，先暂停等待用户确认。',
        retryBudget: retryBudget,
        retriesRemaining: retryBudget,
        blocksProgress: true,
        taskId: ValueReaders.stringValue(runningTask['id']).trim(),
        taskTitle: ValueReaders.stringValue(runningTask['title']).trim(),
        taskPath: ValueReaders.stringValue(
          runningTask['relative_path'],
        ).trim(),
      );
    }
    return LongTaskRecoveryState(
      present: true,
      state: LongTaskRecoveryStates.resumeReady,
      runStatus: LongTaskRunStatus.running.id,
      recommendedAction: 'resume_dispatch',
      reason: status == TaskRuntimeConstants.statusPaused
          ? 'record_paused'
          : 'record_running',
      note: status == TaskRuntimeConstants.statusPaused
          ? '运行记录已暂停，需要用户确认继续。'
          : '可以从当前任务状态继续调度。',
      retryBudget: retryBudget,
      retriesRemaining: retryBudget,
    );
  }

  JsonMap _mergedOptions(JsonMap record, JsonMap options) {
    return <String, Object?>{
      ...ValueReaders.deepCopyMap(ValueReaders.mapValue(record['options'])),
      ...ValueReaders.deepCopyMap(options),
    };
  }

  int _retryBudget(JsonMap options) {
    return ValueReaders.intValue(options['recovery_retry_budget'], 1).clamp(0, 10);
  }

  int _retryCountForTask(JsonMap record, String taskId) {
    final counts = ValueReaders.mapValue(record['recovery_retry_counts']);
    if (taskId.isEmpty) {
      return 0;
    }
    return ValueReaders.intValue(counts[taskId], 0).clamp(0, 999);
  }

  bool _isPausedBudgetRecord(JsonMap record) {
    if (ValueReaders.stringValue(record['status']) != TaskRuntimeConstants.statusPaused) {
      return false;
    }
    final reason = ValueReaders.stringValue(record['stop_reason']).trim();
    return reason == 'max_steps' || reason == 'max_seconds';
  }

  LongTaskRecoveryState _repairBlockingState(
    JsonMap record,
    JsonMap options,
    int retryBudget,
  ) {
    final requestJson = ValueReaders.mapValue(
      options['repair_request'] ?? record['repair_request'],
    );
    if (requestJson.isEmpty) {
      return const LongTaskRecoveryState();
    }
    final request = RepairRequest.fromJson(requestJson);
    final taskJson = ValueReaders.mapValue(
      options['repair_task'] ?? record['repair_task'],
    );
    final outcomeJson = ValueReaders.mapValue(
      options['repair_outcome'] ?? record['repair_outcome'],
    );
    final blocking = _repairLaneBlockingService.blockingState(
      request: request,
      task: taskJson.isEmpty ? null : RepairTask.fromJson(taskJson),
      outcome: outcomeJson.isEmpty ? null : RepairOutcome.fromJson(outcomeJson),
    );
    if (!blocking.blocksMainFlow) {
      return const LongTaskRecoveryState();
    }
    if (blocking.waitingUser) {
      return LongTaskRecoveryState(
        present: true,
        state: LongTaskRecoveryStates.waitingUser,
        runStatus: LongTaskRunStatus.waitingGate.id,
        recommendedAction: 'resume_when_user_confirms',
        reason: blocking.reason,
        note: '当前存在阻塞主链的 repair，并且仍在等待用户确认。',
        waitingUser: true,
        blocksProgress: true,
        retryBudget: retryBudget,
        retriesRemaining: retryBudget,
      );
    }
    if (blocking.manualAttentionRequired) {
      return LongTaskRecoveryState(
        present: true,
        state: LongTaskRecoveryStates.manualAttention,
        runStatus: LongTaskRunStatus.failedManualAttention.id,
        recommendedAction: 'pause_for_manual_attention',
        reason: blocking.reason,
        note: '当前存在阻塞主链的 repair，并且已经升级为人工处理。',
        manualAttentionRequired: true,
        blocksProgress: true,
        retryBudget: retryBudget,
        retriesRemaining: retryBudget,
      );
    }
    return LongTaskRecoveryState(
      present: true,
      state: LongTaskRecoveryStates.repairRequired,
      runStatus: LongTaskRunStatus.recovering.id,
      recommendedAction: 'pause_for_repair',
      reason: blocking.reason,
      note: '当前存在阻塞主链的 repair，必须先完成修复后才能继续。',
      requiresRepair: true,
      blocksProgress: true,
      retryBudget: retryBudget,
      retriesRemaining: retryBudget,
    );
  }

  bool _requiresWaitingUser(JsonMap record, JsonMap signal) {
    return ValueReaders.stringValue(signal['recovery_action']).trim() ==
            'resume_when_user_confirms' ||
        ValueReaders.stringValue(record['last_chapter_delivery_state']).trim() ==
            ChapterDeliveryStateStatuses.waitingUserChoice ||
        _recordInformationRiskCategory(record) ==
            'checkpoint_user';
  }

  bool _requiresManualAttention(JsonMap record, JsonMap signal) {
    return ValueReaders.stringValue(signal['recovery_action']).trim() ==
            'pause_for_manual_attention' ||
        _isManualDeliveryState(
          ValueReaders.stringValue(record['last_chapter_delivery_state']).trim(),
        ) ||
        _recordInformationRiskCategory(record) ==
            'manual_attention';
  }

  bool _requiresRepair(JsonMap record, JsonMap signal) {
    return ValueReaders.stringValue(signal['recovery_action']).trim() ==
            'pause_for_repair' ||
        _isRepairDeliveryState(
          ValueReaders.stringValue(record['last_chapter_delivery_state']).trim(),
        ) ||
        _recordInformationRiskCategory(record) ==
            'repair';
  }

  bool _isAutoRetryEligible(JsonMap signal, JsonMap options) {
    if (!ValueReaders.boolValue(options['auto_retry_failed_task'], true)) {
      return false;
    }
    if (!ValueReaders.boolValue(signal['retryable'])) {
      return false;
    }
    return ValueReaders.stringValue(signal['recovery_action']).trim() ==
            'pause_for_failure' ||
        ValueReaders.stringValue(signal['category']).trim() ==
            'technical_failed';
  }

  LongTaskRecoveryState _exhaustedState({
    required String disposition,
    required int retryCount,
    required int retryBudget,
    required JsonMap failedTask,
  }) {
    final taskId = ValueReaders.stringValue(failedTask['id']).trim();
    final taskTitle = ValueReaders.stringValue(failedTask['title']).trim();
    final taskPath = ValueReaders.stringValue(
      failedTask['relative_path'],
    ).trim();
    final stopOutcome = _stopOutcomeResolverService.fromLegacyStopReason(
      'recovery_exhausted',
      summary: '自动重试预算已耗尽，需要切换到人工处理或终止恢复。',
      metadata: <String, Object?>{
        'recovery_retry_count': retryCount,
        'recovery_retry_budget': retryBudget,
      },
    );
    switch (disposition) {
      case LongTaskRecoveryExhaustedDispositions.stopRun:
        return LongTaskRecoveryState(
          present: true,
          state: LongTaskRecoveryStates.exhausted,
          runStatus: LongTaskRunStatus.stopped.id,
          recommendedAction: 'stop_after_recovery_exhausted',
          reason: 'recovery_exhausted',
          note: '自动重试预算已耗尽，恢复状态机建议终止当前运行。',
          retryCount: retryCount,
          retryBudget: retryBudget,
          retriesRemaining: 0,
          autoRetryEligible: true,
          blocksProgress: true,
          exhausted: true,
          exhaustedDisposition: disposition,
          taskId: taskId,
          taskTitle: taskTitle,
          taskPath: taskPath,
          stopOutcome: stopOutcome,
        );
      case LongTaskRecoveryExhaustedDispositions.waitingUser:
        return LongTaskRecoveryState(
          present: true,
          state: LongTaskRecoveryStates.exhausted,
          runStatus: LongTaskRunStatus.waitingGate.id,
          recommendedAction: 'resume_when_user_confirms',
          reason: 'recovery_exhausted',
          note: '自动重试预算已耗尽，恢复状态机建议交由用户决定下一步。',
          retryCount: retryCount,
          retryBudget: retryBudget,
          retriesRemaining: 0,
          autoRetryEligible: true,
          blocksProgress: true,
          waitingUser: true,
          exhausted: true,
          exhaustedDisposition: disposition,
          taskId: taskId,
          taskTitle: taskTitle,
          taskPath: taskPath,
          stopOutcome: stopOutcome,
        );
      case LongTaskRecoveryExhaustedDispositions.pause:
        return LongTaskRecoveryState(
          present: true,
          state: LongTaskRecoveryStates.exhausted,
          runStatus: LongTaskRunStatus.paused.id,
          recommendedAction: 'pause_for_failure',
          reason: 'recovery_exhausted',
          note: '自动重试预算已耗尽，恢复状态机建议保留暂停并等待进一步处理。',
          retryCount: retryCount,
          retryBudget: retryBudget,
          retriesRemaining: 0,
          autoRetryEligible: true,
          blocksProgress: true,
          exhausted: true,
          exhaustedDisposition: disposition,
          taskId: taskId,
          taskTitle: taskTitle,
          taskPath: taskPath,
          stopOutcome: stopOutcome,
        );
      default:
        return LongTaskRecoveryState(
          present: true,
          state: LongTaskRecoveryStates.exhausted,
          runStatus: LongTaskRunStatus.failedManualAttention.id,
          recommendedAction: 'pause_for_manual_attention',
          reason: 'recovery_exhausted',
          note: '自动重试预算已耗尽，恢复状态机建议升级为人工处理。',
          retryCount: retryCount,
          retryBudget: retryBudget,
          retriesRemaining: 0,
          autoRetryEligible: true,
          blocksProgress: true,
          manualAttentionRequired: true,
          exhausted: true,
          exhaustedDisposition: LongTaskRecoveryExhaustedDispositions.manualAttention,
          taskId: taskId,
          taskTitle: taskTitle,
          taskPath: taskPath,
          stopOutcome: stopOutcome,
        );
    }
  }

  String _exhaustedDisposition(JsonMap options) {
    final clean = ValueReaders.stringValue(
      options['recovery_exhausted_disposition'],
      LongTaskRecoveryExhaustedDispositions.manualAttention,
    ).trim();
    if (LongTaskRecoveryExhaustedDispositions.knownValues.contains(clean)) {
      return clean;
    }
    return LongTaskRecoveryExhaustedDispositions.manualAttention;
  }

  LongTaskStopOutcome _stopOutcomeFromSignal(JsonMap signal) {
    return LongTaskStopOutcome.fromJson(
      ValueReaders.mapValue(signal['stop_outcome']),
    );
  }

  String _signalOrRecordNote(
    JsonMap signal,
    JsonMap record, {
    required String fallback,
  }) {
    return ValueReaders.stringValue(signal['note']).trim().isNotEmpty
        ? ValueReaders.stringValue(signal['note']).trim()
        : ValueReaders.stringValue(record['stop_note']).trim().isNotEmpty
        ? ValueReaders.stringValue(record['stop_note']).trim()
        : _recordInformationSummary(record).isNotEmpty
        ? _recordInformationSummary(record)
        : fallback;
  }

  String _waitingUserReason(JsonMap record, JsonMap signal) {
    if (_recordInformationRiskCategory(record) == 'checkpoint_user') {
      return 'information_waiting_user';
    }
    return ValueReaders.stringValue(
      ValueReaders.mapValue(signal['stop_outcome'])['reason'],
      ValueReaders.stringValue(record['stop_reason'], 'waiting_user'),
    ).trim();
  }

  String _manualAttentionReason(JsonMap record, JsonMap signal) {
    if (_recordInformationRiskCategory(record) == 'manual_attention') {
      return 'information_manual_attention';
    }
    return ValueReaders.stringValue(
      ValueReaders.mapValue(signal['stop_outcome'])['reason'],
      ValueReaders.stringValue(record['stop_reason'], 'manual_attention'),
    ).trim();
  }

  String _repairReason(JsonMap record, JsonMap signal) {
    if (_recordInformationRiskCategory(record) == 'repair') {
      return 'information_repair_required';
    }
    return ValueReaders.stringValue(
      ValueReaders.mapValue(signal['stop_outcome'])['reason'],
      ValueReaders.stringValue(record['stop_reason'], 'repair_required'),
    ).trim();
  }

  bool _isRepairDeliveryState(String value) {
    return value == ChapterDeliveryStateStatuses.deliveredNeedsRepair ||
        value == ChapterDeliveryStateStatuses.missingOutputRecoverable ||
        value == ChapterDeliveryStateStatuses.pathMismatchRecoverable;
  }

  bool _isManualDeliveryState(String value) {
    return value == ChapterDeliveryStateStatuses.invalidOutputRewriteRequired ||
        value == ChapterDeliveryStateStatuses.manualAttentionRequired ||
        value == ChapterDeliveryStateStatuses.hardFailure;
  }

  JsonMap _firstTaskWithStatus(List<Object?> tasks, String status) {
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['status']) == status) {
        return task;
      }
    }
    return const <String, Object?>{};
  }

  String _recordInformationRiskCategory(JsonMap record) {
    final category = ValueReaders.stringValue(
      record['last_information_risk_category'],
    ).trim();
    if (category.isNotEmpty) {
      return category;
    }
    return ValueReaders.stringValue(
      _lastStep(record)['information_risk_category'],
    ).trim();
  }

  String _recordInformationSummary(JsonMap record) {
    final direct = ValueReaders.stringValue(record['last_information_summary']).trim();
    if (direct.isNotEmpty) {
      return direct;
    }
    return ValueReaders.stringValue(_lastStep(record)['information_summary']).trim();
  }

  JsonMap _lastStep(JsonMap record) {
    final steps = ValueReaders.mapList(record['steps']);
    if (steps.isEmpty) {
      return const <String, Object?>{};
    }
    return steps.last;
  }
}
