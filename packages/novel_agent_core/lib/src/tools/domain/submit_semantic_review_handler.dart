import '../../common/json_types.dart';
import '../../common/value_readers.dart';
import '../../continuity/narrative_state.dart';
import 'domain_tool_error.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_outcome_statuses.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_permission_dispositions.dart';
import 'domain_tool_request.dart';
import 'narrative_domain_tool_capability.dart';
import 'narrative_domain_tool_handler.dart';
import 'narrative_domain_tool_names.dart';

class SubmitSemanticReviewHandler implements NarrativeDomainToolHandler {
  const SubmitSemanticReviewHandler();

  @override
  NarrativeDomainToolCapability get capability =>
      const NarrativeDomainToolCapability(
        toolName: NarrativeDomainToolNames.submitSemanticReview,
        displayName: '提交语义复核',
        supportedSourceTypes: <String>[
          NarrativeSourceTypes.reviewer,
          NarrativeSourceTypes.deconstruction,
          NarrativeSourceTypes.explainer,
          NarrativeSourceTypes.explainerInterpreted,
          NarrativeSourceTypes.system,
          NarrativeSourceTypes.user,
        ],
      );

  @override
  Future<DomainToolOutcome> handle({
    required DomainToolRequest request,
    required DomainToolPermissionDecision permissionDecision,
  }) async {
    final review = NarrativeSemanticReview.fromJson(request.requestPayload);
    final validationErrors = review.validateBasics();
    if (validationErrors.isNotEmpty) {
      return _invalidPayloadOutcome(
        request: request,
        message: 'semantic review 存在结构错误。',
        errorDetails: <String, Object?>{'validation_errors': validationErrors},
      );
    }

    final blockingFindingCount = review.findings
        .where((entry) => entry.severity == SemanticReviewSeverity.blocking)
        .length;
    return DomainToolOutcome(
      outcomeId: 'submit_semantic_review:${request.callId}',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: _outcomeStatusFor(permissionDecision.disposition),
      permissionDecision: permissionDecision,
      outcomePayload: <String, Object?>{
        'review': review.toJson(),
        'review_advances_workflow': false,
        'finding_count': review.findings.length,
        'blocking_finding_count': blockingFindingCount,
        'suggested_claim_count': review.suggestedClaims.length,
      },
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
      metadata: <String, Object?>{
        'recommended_disposition': review.recommendedDisposition.id,
      },
    );
  }

  DomainToolOutcome _invalidPayloadOutcome({
    required DomainToolRequest request,
    required String message,
    JsonMap errorDetails = const <String, Object?>{},
  }) {
    return DomainToolOutcome(
      outcomeId: 'submit_semantic_review:${request.callId}:invalid_payload',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
      permissionDecision: const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.accepted,
      ),
      error: DomainToolError(
        errorCode: 'invalid_submit_semantic_review_payload',
        message: message,
        errorDetails: ValueReaders.deepCopyMap(errorDetails),
      ),
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
    );
  }

  String _outcomeStatusFor(String disposition) {
    switch (disposition) {
      case DomainToolPermissionDispositions.accepted:
        return DomainToolOutcomeStatuses.accepted;
      case DomainToolPermissionDispositions.proposed:
        return DomainToolOutcomeStatuses.proposed;
      case DomainToolPermissionDispositions.rejected:
        return DomainToolOutcomeStatuses.rejected;
      case DomainToolPermissionDispositions.needsUserConfirmation:
        return DomainToolOutcomeStatuses.needsUserConfirmation;
    }
    return DomainToolOutcomeStatuses.proposed;
  }
}
