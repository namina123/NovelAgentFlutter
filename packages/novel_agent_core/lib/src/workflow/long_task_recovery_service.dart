import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'chapter_delivery_state_statuses.dart';
import 'long_task_writing_execution_signal_service.dart';
import 'task_runtime_constants.dart';

class LongTaskRecoveryService {
  LongTaskRecoveryService({
    LongTaskWritingExecutionSignalService? writingExecutionSignalService,
  }) : _writingExecutionSignalService =
           writingExecutionSignalService ??
           const LongTaskWritingExecutionSignalService();

  final LongTaskWritingExecutionSignalService _writingExecutionSignalService;

  JsonMap recoveryPlan(
    JsonMap record,
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 崩溃恢复只给出宿主下一步建议，不直接替宿主自动改任务状态。
    final result = <String, Object?>{
      'ok': true,
      'record_id': ValueReaders.stringValue(record['id']),
      'status': ValueReaders.stringValue(record['status']),
      'safe_after_crash': ValueReaders.boolValue(
        options['safe_after_crash'],
        true,
      ),
    };
    if (record.isEmpty) {
      return <String, Object?>{
        ...result,
        'action': 'start_new',
        'reason': 'record_missing',
        'note': '没有可恢复的长任务运行记录。',
      };
    }
    final status = ValueReaders.stringValue(
      record['status'],
      TaskRuntimeConstants.statusRunning,
    );
    final writingExecutionRecovery = _writingExecutionRecoveryPlan(
      record,
      result,
    );
    if (writingExecutionRecovery.isNotEmpty) {
      return writingExecutionRecovery;
    }
    final deliveryRecovery = _deliveryRecoveryPlan(record, result);
    if (deliveryRecovery.isNotEmpty) {
      return deliveryRecovery;
    }
    final informationRecovery = _informationRecoveryPlan(record, result);
    if (informationRecovery.isNotEmpty) {
      return informationRecovery;
    }
    if (status == TaskRuntimeConstants.statusPaused) {
      final pausedStopReason = ValueReaders.stringValue(
        record['stop_reason'],
      ).trim();
      if (pausedStopReason == 'max_steps' || pausedStopReason == 'max_seconds') {
        return <String, Object?>{
          ...result,
          'action': 'resume_dispatch',
          'reason': 'budget_failed',
          'note': pausedStopReason == 'max_seconds'
              ? '上次运行达到时长预算边界，可从当前任务状态继续调度。'
              : '上次运行达到步数预算边界，可从当前任务状态继续调度。',
        };
      }
      return <String, Object?>{
        ...result,
        'action': 'resume_when_user_confirms',
        'reason': 'record_paused',
        'note': '运行记录已暂停，需要用户确认继续。',
      };
    }
    if (<String>[
      TaskRuntimeConstants.statusSucceeded,
      TaskRuntimeConstants.statusFailed,
      TaskRuntimeConstants.statusCancelled,
    ].contains(status)) {
      return <String, Object?>{
        ...result,
        'action': 'read_only',
        'reason': 'terminal_record',
        'note': '运行记录已经结束，只能查看或新建运行。',
      };
    }
    final failed = _firstTaskWithStatus(
      tasks,
      TaskRuntimeConstants.statusFailed,
    );
    if (failed.isNotEmpty) {
      return <String, Object?>{
        ...result,
        'action': 'pause_for_failure',
        'reason': 'failed_task',
        'note': '检测到失败任务，应先重试、跳过或人工修复。',
        'task': _taskSummaryForRecovery(failed),
      };
    }
    final running = _firstTaskWithStatus(
      tasks,
      TaskRuntimeConstants.statusRunning,
    );
    if (running.isNotEmpty &&
        ValueReaders.boolValue(result['safe_after_crash'], true)) {
      return <String, Object?>{
        ...result,
        'action': 'pause_for_review',
        'reason': 'stale_running_task',
        'note': '检测到上次退出时仍在运行的任务，为避免重复写入，先暂停等待用户确认。',
        'task': _taskSummaryForRecovery(running),
      };
    }
    return <String, Object?>{
      ...result,
      'action': 'resume_dispatch',
      'reason': 'record_running',
      'note': '可以从当前任务状态继续调度。',
    };
  }

  JsonMap _writingExecutionRecoveryPlan(JsonMap record, JsonMap result) {
    final signal = _writingExecutionSignalService.signalFromPayload(
      record: record,
      stopReason: ValueReaders.stringValue(record['stop_reason']),
      fallbackNote: ValueReaders.stringValue(record['stop_note']),
    );
    if (!ValueReaders.boolValue(signal['present'])) {
      return const <String, Object?>{};
    }
    final category = ValueReaders.stringValue(signal['category']).trim();
    if (category == 'success') {
      return const <String, Object?>{};
    }
    final recoveryAction = ValueReaders.stringValue(
      signal['recovery_action'],
    ).trim();
    if (recoveryAction.isEmpty) {
      return const <String, Object?>{};
    }
    final reason = switch (category) {
      'waiting_user' => 'writing_execution_waiting_user',
      'recoverable' => 'writing_execution_recoverable_failure',
      'content_quality_failed' => 'writing_execution_content_quality_failed',
      'technical_failed' => 'writing_execution_technical_failure',
      'budget_failed' => 'budget_failed',
      _ => 'writing_execution_signal',
    };
    return <String, Object?>{
      ...result,
      'action': recoveryAction,
      'reason': reason,
      'note': ValueReaders.stringValue(
        signal['note'],
        '共享写作结果要求当前长任务先停下处理。',
      ),
    };
  }

  JsonMap _deliveryRecoveryPlan(JsonMap record, JsonMap result) {
    final deliveryState = ValueReaders.stringValue(
      record['last_chapter_delivery_state'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(_lastStep(record))['chapter_delivery_state'],
      ),
    ).trim();
    switch (deliveryState) {
      case ChapterDeliveryStateStatuses.missingOutputRecoverable:
      case ChapterDeliveryStateStatuses.pathMismatchRecoverable:
      case ChapterDeliveryStateStatuses.deliveredNeedsRepair:
        return <String, Object?>{
          ...result,
          'action': 'pause_for_repair',
          'reason': 'delivery_recovery_required',
          'note': '最近一步的章节交付状态要求先进入 repair/recovery。',
        };
      case ChapterDeliveryStateStatuses.waitingUserChoice:
        return <String, Object?>{
          ...result,
          'action': 'resume_when_user_confirms',
          'reason': 'delivery_waiting_user_choice',
          'note': '最近一步的章节交付状态正在等待用户确认。',
        };
      case ChapterDeliveryStateStatuses.invalidOutputRewriteRequired:
      case ChapterDeliveryStateStatuses.manualAttentionRequired:
      case ChapterDeliveryStateStatuses.hardFailure:
        return <String, Object?>{
          ...result,
          'action': 'pause_for_manual_attention',
          'reason': 'delivery_manual_attention',
          'note': '最近一步的章节交付状态要求人工介入。',
        };
    }
    return const <String, Object?>{};
  }

  JsonMap _informationRecoveryPlan(JsonMap record, JsonMap result) {
    final informationCategory = ValueReaders.stringValue(
      record['last_information_risk_category'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(_lastStep(record))['information_risk_category'],
      ),
    ).trim();
    final informationSummary = ValueReaders.stringValue(
      record['last_information_summary'],
      ValueReaders.stringValue(
        ValueReaders.mapValue(_lastStep(record))['information_summary'],
      ),
    ).trim();
    switch (informationCategory) {
      case 'repair':
        return <String, Object?>{
          ...result,
          'action': 'pause_for_repair',
          'reason': 'information_repair_required',
          'note': informationSummary.isEmpty
              ? '最近一步的信息层信号要求先补研究、补上下文或处理设计冲突。'
              : informationSummary,
        };
      case 'manual_attention':
        return <String, Object?>{
          ...result,
          'action': 'pause_for_manual_attention',
          'reason': 'information_manual_attention',
          'note': informationSummary.isEmpty
              ? '最近一步的信息层信号要求人工介入。'
              : informationSummary,
        };
      case 'checkpoint_user':
        return <String, Object?>{
          ...result,
          'action': 'resume_when_user_confirms',
          'reason': 'information_waiting_user',
          'note': informationSummary.isEmpty
              ? '最近一步的信息层信号建议先停在用户确认点。'
              : informationSummary,
        };
    }
    return const <String, Object?>{};
  }

  JsonMap _firstTaskWithStatus(List<Object?> tasks, String status) {
    // 中文注释: 恢复规则只需要第一条命中的异常任务即可给宿主足够的决策信息。
    for (final rawTask in tasks) {
      final task = ValueReaders.mapValue(rawTask);
      if (ValueReaders.stringValue(task['status']) == status) {
        return task;
      }
    }
    return <String, Object?>{};
  }

  JsonMap _taskSummaryForRecovery(JsonMap task) {
    // 中文注释: 恢复场景只展示最小任务摘要，避免把完整任务 JSON 强塞给 UI。
    return <String, Object?>{
      'id': ValueReaders.stringValue(task['id']),
      'title': ValueReaders.stringValue(task['title']),
      'task_type': ValueReaders.stringValue(task['task_type']),
      'status': ValueReaders.stringValue(task['status']),
      'relative_path': ValueReaders.stringValue(task['relative_path']),
    };
  }

  JsonMap _lastStep(JsonMap record) {
    final steps = ValueReaders.mapList(record['steps']);
    if (steps.isEmpty) {
      return const <String, Object?>{};
    }
    return steps.last;
  }
}
