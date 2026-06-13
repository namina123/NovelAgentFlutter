import '../common/json_types.dart';
import '../common/value_readers.dart';
import 'task_runtime_constants.dart';
import 'writing_execution_outcome_statuses.dart';

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

  JsonMap resumeRecordAfterCheckpointConfirmation(
    JsonMap record, {
    String note = '',
    String checkpointReviewPath = '',
    String createdAt = '',
  }) {
    final next = resumeRecord(record, note: note, createdAt: createdAt);
    final summary = note.trim().isEmpty
        ? '用户已确认当前 checkpoint，长任务恢复继续调度。'
        : note.trim();
    next['last_writing_execution_result'] = <String, Object?>{
      'execution_id': '',
      'workflow_kind': 'long_task_checkpoint_acknowledged',
      'overall_status': WritingExecutionOutcomeStatuses.success,
      'summary': summary,
      'delivery': const <String, Object?>{},
      'constraints': const <String, Object?>{},
      'information': const <String, Object?>{
        'present': false,
        'risk_category': 'accept',
        'summary': '',
      },
      'collaboration': const <String, Object?>{},
      'recovery': const <String, Object?>{},
      'next_action': 'resume_dispatch',
      'blocks_progress': false,
      'retryable': false,
      'requires_user_action': false,
      'schema_version': 1,
      'metadata': <String, Object?>{
        'checkpoint_review_acknowledged': true,
        if (checkpointReviewPath.trim().isNotEmpty)
          'checkpoint_review_path': checkpointReviewPath.trim(),
      },
    };
    next['last_writing_execution_category'] = 'success';
    next['last_writing_execution_status'] =
        WritingExecutionOutcomeStatuses.success;
    next['last_writing_execution_summary'] = summary;
    next['last_writing_execution_next_action'] = 'resume_dispatch';
    next['last_information_risk_category'] = 'accept';
    next['last_information_summary'] = '';
    next['last_chapter_delivery_state'] = '';
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
