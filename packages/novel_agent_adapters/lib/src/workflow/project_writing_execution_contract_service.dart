import 'package:novel_agent_core/novel_agent_core.dart';

import '../projection/expression_constraint_status_projection_service.dart';

class ProjectWritingExecutionContractService {
  const ProjectWritingExecutionContractService({
    ExpressionConstraintStatusProjectionService?
    expressionConstraintStatusProjectionService,
  }) : _expressionConstraintStatusProjectionService =
           expressionConstraintStatusProjectionService ??
           const ExpressionConstraintStatusProjectionService();

  final ExpressionConstraintStatusProjectionService
  _expressionConstraintStatusProjectionService;

  ChapterDeliveryStateResult? chapterDeliveryStateFromDelivery({
    required JsonMap delivery,
    String fallbackState = '',
    String fallbackChapterPath = '',
  }) {
    final stateResult = ValueReaders.mapValue(delivery['state_result']);
    final state = ValueReaders.stringValue(
      stateResult['state'],
      ValueReaders.stringValue(delivery['delivery_state'], fallbackState),
    ).trim();
    if (state.isEmpty) {
      return null;
    }
    final metadata = ValueReaders.mapValue(stateResult['metadata']);
    final fallbackMetadata = <String, Object?>{};
    final chapterPath = ValueReaders.stringValue(
      delivery['chapter_path'],
      fallbackChapterPath,
    ).trim();
    if (chapterPath.isNotEmpty) {
      fallbackMetadata['chapter_path'] = chapterPath;
    }
    final resolvedChapterPath = ValueReaders.stringValue(
      delivery['resolved_chapter_path'],
    ).trim();
    if (resolvedChapterPath.isNotEmpty) {
      fallbackMetadata['resolved_chapter_path'] = resolvedChapterPath;
    }
    return ChapterDeliveryStateResult(
      deliveryId: ValueReaders.stringValue(
        stateResult['delivery_id'],
        ValueReaders.stringValue(delivery['delivery_id']),
      ),
      state: state,
      recommendedAction: ValueReaders.stringValue(
        stateResult['recommended_action'],
      ),
      suggestedOutcomeStatus: ValueReaders.stringValue(
        stateResult['suggested_outcome_status'],
      ),
      reason: ValueReaders.stringValue(stateResult['reason']),
      summary: ValueReaders.stringValue(stateResult['summary']),
      blocksProgress: ValueReaders.boolValue(stateResult['blocks_progress']),
      chapterBodyDelivered: ValueReaders.boolValue(
        stateResult['chapter_body_delivered'],
      ),
      submissionAccepted: ValueReaders.boolValue(
        stateResult['submission_accepted'],
      ),
      retryable: ValueReaders.boolValue(stateResult['retryable']),
      metadata: ValueReaders.deepCopyMap(
        metadata.isNotEmpty ? metadata : fallbackMetadata,
      ),
    );
  }

  WritingExecutionConstraintBridgeResult? constraintBridgeResult(
    JsonMap executionConstraints,
  ) {
    if (executionConstraints.isEmpty) {
      return null;
    }
    return WritingExecutionConstraintBridgeResult.fromJson(
      executionConstraints,
    );
  }

  ContextActivationReport? activationReportFromJson(JsonMap activationReport) {
    if (activationReport.isEmpty) {
      return null;
    }
    return ContextActivationReport.fromJson(activationReport);
  }

  JsonMap attachDerivedProjections(JsonMap writingExecutionResult) {
    if (writingExecutionResult.isEmpty) {
      return const <String, Object?>{};
    }
    final next = ValueReaders.deepCopyMap(writingExecutionResult);
    next['expression_constraint_projection'] =
        _expressionConstraintStatusProjectionService
            .fromWritingExecutionResult(next)
            .toJson();
    return next;
  }
}
