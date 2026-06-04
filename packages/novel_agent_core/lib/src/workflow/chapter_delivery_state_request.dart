import '../common/json_types.dart';
import '../common/value_readers.dart';
import '../continuity/narrative_state/chapter_narrative_submission.dart';

class ChapterDeliveryStateRequest {
  const ChapterDeliveryStateRequest({
    required this.deliveryId,
    required this.chapterPath,
    this.chapterContent = '',
    this.title = '',
    this.resolvedChapterPath = '',
    this.submission,
    this.writeSucceeded = true,
    this.retryableFailure = false,
    this.failureReason = '',
    this.gateDecision = const <String, Object?>{},
    this.metadata = const <String, Object?>{},
  });

  final String deliveryId;
  final String chapterPath;
  final String chapterContent;
  final String title;
  final String resolvedChapterPath;
  final ChapterNarrativeSubmission? submission;
  final bool writeSucceeded;
  final bool retryableFailure;
  final String failureReason;
  final JsonMap gateDecision;
  final JsonMap metadata;

  JsonMap toJson() {
    // 中文注释: request 只聚合状态机需要的内存信号，不承担文件读写或工具执行。
    return <String, Object?>{
      'delivery_id': deliveryId,
      'chapter_path': chapterPath,
      'chapter_content': chapterContent,
      'title': title,
      'resolved_chapter_path': resolvedChapterPath,
      'submission': submission?.toJson(),
      'write_succeeded': writeSucceeded,
      'retryable_failure': retryableFailure,
      'failure_reason': failureReason,
      'gate_decision': ValueReaders.deepCopyMap(gateDecision),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }
}
