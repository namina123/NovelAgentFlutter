import '../common/json_types.dart';
import '../common/value_readers.dart';

class WritingExecutionDeliverySummary {
  const WritingExecutionDeliverySummary({
    this.present = false,
    this.deliveryId = '',
    this.state = '',
    this.recommendedAction = '',
    this.suggestedOutcomeStatus = '',
    this.reason = '',
    this.summary = '',
    this.chapterPath = '',
    this.resolvedChapterPath = '',
    this.blocksProgress = false,
    this.chapterBodyDelivered = false,
    this.submissionAccepted = false,
    this.retryable = false,
    this.metadata = const <String, Object?>{},
  });

  final bool present;
  final String deliveryId;
  final String state;
  final String recommendedAction;
  final String suggestedOutcomeStatus;
  final String reason;
  final String summary;
  final String chapterPath;
  final String resolvedChapterPath;
  final bool blocksProgress;
  final bool chapterBodyDelivered;
  final bool submissionAccepted;
  final bool retryable;
  final JsonMap metadata;

  factory WritingExecutionDeliverySummary.fromJson(JsonMap json) {
    // 中文注释: delivery summary 需要能从稳定 JSON 回读，供后续 runtime、probe 和 GUI 共享消费。
    return WritingExecutionDeliverySummary(
      present: ValueReaders.boolValue(json['present']),
      deliveryId: ValueReaders.stringValue(json['delivery_id']).trim(),
      state: ValueReaders.stringValue(json['state']).trim(),
      recommendedAction: ValueReaders.stringValue(
        json['recommended_action'],
      ).trim(),
      suggestedOutcomeStatus: ValueReaders.stringValue(
        json['suggested_outcome_status'],
      ).trim(),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      chapterPath: ValueReaders.stringValue(json['chapter_path']).trim(),
      resolvedChapterPath: ValueReaders.stringValue(
        json['resolved_chapter_path'],
      ).trim(),
      blocksProgress: ValueReaders.boolValue(json['blocks_progress']),
      chapterBodyDelivered: ValueReaders.boolValue(
        json['chapter_body_delivered'],
      ),
      submissionAccepted: ValueReaders.boolValue(json['submission_accepted']),
      retryable: ValueReaders.boolValue(json['retryable']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    // 中文注释: 这里把章节交付结论压成稳定壳层字段，避免后续调用点重新拼装旧状态机结果。
    return <String, Object?>{
      'present': present,
      'delivery_id': deliveryId,
      'state': state,
      'recommended_action': recommendedAction,
      'suggested_outcome_status': suggestedOutcomeStatus,
      'reason': reason,
      'summary': summary,
      'chapter_path': chapterPath,
      'resolved_chapter_path': resolvedChapterPath,
      'blocks_progress': blocksProgress,
      'chapter_body_delivered': chapterBodyDelivered,
      'submission_accepted': submissionAccepted,
      'retryable': retryable,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    // 中文注释: delivery summary 校验只关注共享合同是否成形，不重新执行章节状态机判断。
    if (!present) {
      return const <String>[];
    }
    final result = <String>[];
    if (deliveryId.trim().isEmpty) {
      result.add('missing_writing_execution_delivery_id');
    }
    if (state.trim().isEmpty) {
      result.add('missing_writing_execution_delivery_state');
    }
    if (recommendedAction.trim().isEmpty) {
      result.add('missing_writing_execution_delivery_action');
    }
    return result;
  }
}
