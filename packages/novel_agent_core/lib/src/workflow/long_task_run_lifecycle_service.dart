import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'task_runtime_constants.dart';

class LongTaskRunLifecycleService {
  JsonMap pauseRecord(
    JsonMap record, {
    String reason = 'manual_pause',
    String note = '',
    String createdAt = '',
  }) {
    // 中文注释: 暂停只改变运行记录状态，不负责宿主线程或后台 worker 的真正停止动作。
    final next = ValueReaders.deepCopyMap(record);
    next['status'] = TaskRuntimeConstants.statusPaused;
    next['pause_requested'] = true;
    next['stop_reason'] = reason.trim().isEmpty ? 'manual_pause' : reason;
    next['stop_note'] = note.trim().isEmpty ? '长任务已暂停。' : note;
    next['updated_at'] = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    return next;
  }

  JsonMap resumeRecord(
    JsonMap record, {
    String note = '',
    String createdAt = '',
  }) {
    // 中文注释: 恢复只重置记录上的暂停标记，具体调度继续由宿主下一次 tick 决定。
    final next = ValueReaders.deepCopyMap(record);
    next['status'] = TaskRuntimeConstants.statusRunning;
    next['pause_requested'] = false;
    next['stop_reason'] = '';
    next['stop_note'] = note.trim().isEmpty
        ? '长任务已恢复，调度器会从当前 tasks 状态继续。'
        : note;
    next['updated_at'] = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    return next;
  }

  JsonMap finishRecord(
    JsonMap record, {
    String reason = 'completed',
    String note = '',
    String createdAt = '',
  }) {
    // 中文注释: 结束运行时根据原因收敛到 succeeded/failed/cancelled 三类终态。
    final next = ValueReaders.deepCopyMap(record);
    var cleanReason = reason.trim();
    if (cleanReason.isEmpty) {
      cleanReason = 'completed';
    }
    next['status'] = cleanReason == 'cancelled' || cleanReason == 'manual_stop'
        ? TaskRuntimeConstants.statusCancelled
        : (cleanReason == 'step_failed'
              ? TaskRuntimeConstants.statusFailed
              : TaskRuntimeConstants.statusSucceeded);
    next['pause_requested'] = false;
    next['stop_reason'] = cleanReason;
    next['stop_note'] = note;
    next['updated_at'] = createdAt.isEmpty
        ? DateTime.now().toIso8601String()
        : createdAt;
    return next;
  }
}
