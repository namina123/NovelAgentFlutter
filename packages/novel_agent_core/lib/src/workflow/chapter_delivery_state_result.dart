import '../common/json_types.dart';
import '../common/value_readers.dart';

class ChapterDeliveryStateResult {
  const ChapterDeliveryStateResult({
    required this.deliveryId,
    required this.state,
    required this.recommendedAction,
    required this.suggestedOutcomeStatus,
    this.reason = '',
    this.summary = '',
    this.blocksProgress = false,
    this.chapterBodyDelivered = false,
    this.submissionAccepted = false,
    this.retryable = false,
    this.metadata = const <String, Object?>{},
  });

  final String deliveryId;
  final String state;
  final String recommendedAction;
  final String suggestedOutcomeStatus;
  final String reason;
  final String summary;
  final bool blocksProgress;
  final bool chapterBodyDelivered;
  final bool submissionAccepted;
  final bool retryable;
  final JsonMap metadata;

  JsonMap toJson() {
    // 中文注释: 状态机结果后续会被 tool outcome/runtime/supervisor 共同消费，这里先固定最小输出结构。
    return <String, Object?>{
      'delivery_id': deliveryId,
      'state': state,
      'recommended_action': recommendedAction,
      'suggested_outcome_status': suggestedOutcomeStatus,
      'reason': reason,
      'summary': summary,
      'blocks_progress': blocksProgress,
      'chapter_body_delivered': chapterBodyDelivered,
      'submission_accepted': submissionAccepted,
      'retryable': retryable,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
