import '../common/json_types.dart';
import '../common/value_readers.dart';

abstract final class ReferenceExtractionRunStatuses {
  static const String active = 'active';
  static const String technicalResumable = 'technical_resumable';
  static const String awaitingSemanticContinuation =
      'awaiting_semantic_continuation';
  static const String semanticContinuationInProgress =
      'semantic_continuation_in_progress';
  static const String completedPublishable = 'completed_publishable';
}

abstract final class ReferenceExtractionReentryActions {
  static const String startNew = 'start_new';
  static const String returnCompleted = 'return_completed';
  static const String resumeTechnical = 'resume_technical';
  static const String resumeSemantic = 'resume_semantic';
}

class ReferenceExtractionContinuationContext {
  const ReferenceExtractionContinuationContext({
    required this.roundIndex,
    this.targetBatchIds = const <String>[],
    this.focusDimensionIds = const <String>[],
    this.recommendedNextFocus = '',
    this.sourceContinuationRequestIds = const <String>[],
    this.sourceOmissionReportIds = const <String>[],
    this.metadata = const <String, Object?>{},
  });

  final int roundIndex;
  final List<String> targetBatchIds;
  final List<String> focusDimensionIds;
  final String recommendedNextFocus;
  final List<String> sourceContinuationRequestIds;
  final List<String> sourceOmissionReportIds;
  final JsonMap metadata;

  JsonMap toJson() {
    return <String, Object?>{
      'round_index': roundIndex,
      'target_batch_ids': ValueReaders.deepCopyList(
        targetBatchIds.cast<Object?>(),
      ),
      'focus_dimension_ids': ValueReaders.deepCopyList(
        focusDimensionIds.cast<Object?>(),
      ),
      'recommended_next_focus': recommendedNextFocus,
      'source_continuation_request_ids': ValueReaders.deepCopyList(
        sourceContinuationRequestIds.cast<Object?>(),
      ),
      'source_omission_report_ids': ValueReaders.deepCopyList(
        sourceOmissionReportIds.cast<Object?>(),
      ),
      'metadata': ValueReaders.deepCopyMap(metadata),
    };
  }

  static ReferenceExtractionContinuationContext fromJson(JsonMap json) {
    return ReferenceExtractionContinuationContext(
      roundIndex: ValueReaders.intValue(json['round_index']),
      targetBatchIds: ValueReaders.stringList(json['target_batch_ids']),
      focusDimensionIds: ValueReaders.stringList(json['focus_dimension_ids']),
      recommendedNextFocus: ValueReaders.stringValue(
        json['recommended_next_focus'],
      ).trim(),
      sourceContinuationRequestIds: ValueReaders.stringList(
        json['source_continuation_request_ids'],
      ),
      sourceOmissionReportIds: ValueReaders.stringList(
        json['source_omission_report_ids'],
      ),
      metadata: ValueReaders.deepCopyMap(
        ValueReaders.mapValue(json['metadata']),
      ),
    );
  }
}

class ReferenceExtractionReentryDecision {
  const ReferenceExtractionReentryDecision({
    required this.action,
    required this.nextRunStatus,
    this.rationale = '',
    this.targetBatchIds = const <String>[],
    this.continuationContext,
    this.metadata = const <String, Object?>{},
  });

  final String action;
  final String nextRunStatus;
  final String rationale;
  final List<String> targetBatchIds;
  final ReferenceExtractionContinuationContext? continuationContext;
  final JsonMap metadata;

  bool get shouldShortCircuit =>
      action == ReferenceExtractionReentryActions.returnCompleted;

  bool get isSemanticContinuation =>
      action == ReferenceExtractionReentryActions.resumeSemantic;

  bool get isTechnicalResume =>
      action == ReferenceExtractionReentryActions.resumeTechnical;
}
