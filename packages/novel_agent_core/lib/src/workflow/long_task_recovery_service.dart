import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'long_task_recovery_state_machine_service.dart';
import 'long_task_writing_execution_signal_service.dart';

class LongTaskRecoveryService {
  LongTaskRecoveryService({
    LongTaskWritingExecutionSignalService? writingExecutionSignalService,
    LongTaskRecoveryStateMachineService? recoveryStateMachineService,
  }) : _writingExecutionSignalService =
           writingExecutionSignalService ??
           const LongTaskWritingExecutionSignalService(),
       _recoveryStateMachineService =
           recoveryStateMachineService ??
           const LongTaskRecoveryStateMachineService();

  final LongTaskWritingExecutionSignalService _writingExecutionSignalService;
  final LongTaskRecoveryStateMachineService _recoveryStateMachineService;

  JsonMap recoveryPlan(
    JsonMap record,
    List<Object?> tasks, {
    JsonMap options = const <String, Object?>{},
  }) {
    // 中文注释: 崩溃恢复现在统一委托给正式恢复状态机，再向旧消费方回放兼容 action/note/task 字段。
    final safeAfterCrash = ValueReaders.boolValue(
      options['safe_after_crash'],
      ValueReaders.boolValue(
        ValueReaders.mapValue(record['options'])['safe_after_crash'],
        true,
      ),
    );
    final state = _recoveryStateMachineService.stateForRecord(
      record,
      tasks,
      options: options,
    );
    final result = <String, Object?>{
      'ok': true,
      'record_id': ValueReaders.stringValue(record['id']),
      'status': ValueReaders.stringValue(record['status']),
      'safe_after_crash': safeAfterCrash,
      'action': state.recommendedAction,
      'reason': state.reason,
      'note': state.note,
      'retry_count': state.retryCount,
      'retry_budget': state.retryBudget,
      'retries_remaining': state.retriesRemaining,
      'auto_retry_eligible': state.autoRetryEligible,
      'exhausted': state.exhausted,
      'exhausted_disposition': state.exhaustedDisposition,
      'recovery_state': state.toJson(),
      'stop_outcome': state.stopOutcome.toJson(),
    };
    final taskSummary = _taskSummaryForRecovery(<String, Object?>{
      'id': state.taskId,
      'title': state.taskTitle,
      'relative_path': state.taskPath,
    });
    if (taskSummary.isNotEmpty) {
      result['task'] = taskSummary;
    }
    final signal = _writingExecutionSignalService.signalFromPayload(
      record: record,
      stopReason: ValueReaders.stringValue(record['stop_reason']),
      fallbackNote: ValueReaders.stringValue(record['stop_note']),
    );
    if (ValueReaders.boolValue(signal['present'])) {
      result['writing_execution_signal'] = signal;
    }
    return result;
  }

  JsonMap _taskSummaryForRecovery(JsonMap task) {
    // 中文注释: 恢复场景只展示最小任务摘要，避免把完整任务 JSON 强塞给 UI。
    final taskId = ValueReaders.stringValue(task['id']).trim();
    final title = ValueReaders.stringValue(task['title']).trim();
    final path = ValueReaders.stringValue(task['relative_path']).trim();
    if (taskId.isEmpty && title.isEmpty && path.isEmpty) {
      return const <String, Object?>{};
    }
    return <String, Object?>{
      'id': taskId,
      'title': title,
      'relative_path': path,
    };
  }
}
