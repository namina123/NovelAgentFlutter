import '../common/json_types.dart';
import '../common/value_readers.dart';

class ChapterDeliveryFailureCategories {
  static const String writeFailed = 'write_failed';
  static const String emptyBody = 'empty_body';
  static const String titleOnlyOutput = 'title_only_output';
  static const String bodyTooShort = 'body_too_short';
  static const String pathMismatch = 'path_mismatch';
  static const String sidecarMissing = 'sidecar_missing';
  static const String sidecarInvalid = 'sidecar_invalid';
  static const String deliveryEvidenceMissing = 'delivery_evidence_missing';

  static const Set<String> knownValues = <String>{
    writeFailed,
    emptyBody,
    titleOnlyOutput,
    bodyTooShort,
    pathMismatch,
    sidecarMissing,
    sidecarInvalid,
    deliveryEvidenceMissing,
  };

  const ChapterDeliveryFailureCategories._();
}

class ChapterDeliveryFailure {
  const ChapterDeliveryFailure({
    required this.category,
    this.reason = '',
    this.summary = '',
    this.deliveryState = '',
    this.chapterPath = '',
    this.resolvedChapterPath = '',
    this.retryable = false,
    this.chapterBodyDelivered = false,
    this.submissionAccepted = false,
    this.metadata = const <String, Object?>{},
  });

  final String category;
  final String reason;
  final String summary;
  final String deliveryState;
  final String chapterPath;
  final String resolvedChapterPath;
  final bool retryable;
  final bool chapterBodyDelivered;
  final bool submissionAccepted;
  final JsonMap metadata;

  factory ChapterDeliveryFailure.fromJson(JsonMap json) {
    return ChapterDeliveryFailure(
      category: ValueReaders.stringValue(json['category']).trim(),
      reason: ValueReaders.stringValue(json['reason']).trim(),
      summary: ValueReaders.stringValue(json['summary']).trim(),
      deliveryState: ValueReaders.stringValue(json['delivery_state']).trim(),
      chapterPath: ValueReaders.stringValue(json['chapter_path']).trim(),
      resolvedChapterPath: ValueReaders.stringValue(
        json['resolved_chapter_path'],
      ).trim(),
      retryable: ValueReaders.boolValue(json['retryable']),
      chapterBodyDelivered: ValueReaders.boolValue(
        json['chapter_body_delivered'],
      ),
      submissionAccepted: ValueReaders.boolValue(json['submission_accepted']),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }

  JsonMap toJson() {
    return <String, Object?>{
      'category': category,
      'reason': reason,
      'summary': summary,
      'delivery_state': deliveryState,
      'chapter_path': chapterPath,
      'resolved_chapter_path': resolvedChapterPath,
      'retryable': retryable,
      'chapter_body_delivered': chapterBodyDelivered,
      'submission_accepted': submissionAccepted,
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  List<String> validateBasics() {
    final result = <String>[];
    if (!ChapterDeliveryFailureCategories.knownValues.contains(category)) {
      result.add('invalid_chapter_delivery_failure_category');
    }
    if (reason.trim().isEmpty) {
      result.add('missing_chapter_delivery_failure_reason');
    }
    return result;
  }
}
