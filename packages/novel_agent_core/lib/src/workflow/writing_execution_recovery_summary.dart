import '../common/json_types.dart';
import '../common/value_readers.dart';

class WritingExecutionRecoverySummary {
  const WritingExecutionRecoverySummary({
    this.present = false,
    this.recommendedAction = '',
    this.reason = '',
    this.note = '',
    this.safeAfterCrash = true,
    this.waitingUser = false,
    this.requiresRepair = false,
    this.manualAttentionRequired = false,
    this.resumeAllowed = false,
    this.retryable = false,
    this.taskId = '',
    this.taskTitle = '',
    this.taskPath = '',
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final String recommendedAction;
  final String reason;
  final String note;
  final bool safeAfterCrash;
  final bool waitingUser;
  final bool requiresRepair;
  final bool manualAttentionRequired;
  final bool resumeAllowed;
  final bool retryable;
  final String taskId;
  final String taskTitle;
  final String taskPath;
  final JsonMap metadata;

  factory WritingExecutionRecoverySummary.fromJson(JsonMap json) {
    // 中文注释: recovery summary 需要独立回读，方便后续 supervisor、station 与 GUI 投影复用同一恢复建议。
    return WritingExecutionRecoverySummary(
      present: ValueReaders.boolValue(json['present']),
      recommendedAction: ValueReaders.stringValue(
        json['recommended_action'],
      ).trim(),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      note: ValueReaders.stringValue(json['note']).trim(),
      safeAfterCrash: ValueReaders.boolValue(json['safe_after_crash'], true),
      waitingUser: ValueReaders.boolValue(json['waiting_user']),
      requiresRepair: ValueReaders.boolValue(json['requires_repair']),
      manualAttentionRequired: ValueReaders.boolValue(
        json['manual_attention_required'],
      ),
      resumeAllowed: ValueReaders.boolValue(json['resume_allowed']),
      retryable: ValueReaders.boolValue(json['retryable']),
      taskId: ValueReaders.stringValue(json['task_id']).trim(),
      taskTitle: ValueReaders.stringValue(json['task_title']).trim(),
      taskPath: ValueReaders.stringValue(json['task_path']).trim(),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 恢复摘要只表达“宿主下一步该怎么做”，不把完整 run record 或 task JSON 再次透出。
    return <String, Object?>{
      'present': present,
      'recommended_action': recommendedAction,
      'reason': reason,
      'note': note,
      'safe_after_crash': safeAfterCrash,
      'waiting_user': waitingUser,
      'requires_repair': requiresRepair,
      'manual_attention_required': manualAttentionRequired,
      'resume_allowed': resumeAllowed,
      'retryable': retryable,
      'task_id': taskId,
      'task_title': taskTitle,
      'task_path': taskPath,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: 恢复摘要校验只保证动作和标志位成形，不替代恢复策略本身的业务判断。
    if (!present) {
      return const <String>[];
    }
    final result = <String>[];
    if (recommendedAction.trim().isEmpty) {
      result.add('missing_writing_execution_recovery_action');
    }
    if (reason.trim().isEmpty) {
      result.add('missing_writing_execution_recovery_reason');
    }
    return result;
  }
}
