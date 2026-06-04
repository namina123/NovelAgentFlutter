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
import 'profile_clarification_request.dart';

class RequestProfileClarificationHandler implements NarrativeDomainToolHandler {
  const RequestProfileClarificationHandler();

  @override
  NarrativeDomainToolCapability get capability =>
      const NarrativeDomainToolCapability(
        toolName: NarrativeDomainToolNames.requestProfileClarification,
        displayName: '请求规则澄清',
        supportedSourceTypes: <String>[
          NarrativeSourceTypes.writer,
          NarrativeSourceTypes.recovery,
          NarrativeSourceTypes.deconstruction,
          NarrativeSourceTypes.explainer,
          NarrativeSourceTypes.reviewer,
          NarrativeSourceTypes.system,
          NarrativeSourceTypes.user,
        ],
      );

  @override
  Future<DomainToolOutcome> handle({
    required DomainToolRequest request,
    required DomainToolPermissionDecision permissionDecision,
  }) async {
    final clarification = ProfileClarificationRequest.fromJson(
      request.requestPayload,
    );
    final validationErrors = clarification.validateBasics();
    if (validationErrors.isNotEmpty) {
      return _invalidPayloadOutcome(
        request: request,
        message: 'profile clarification 请求存在结构错误。',
        errorDetails: <String, Object?>{'validation_errors': validationErrors},
      );
    }

    return DomainToolOutcome(
      outcomeId: 'request_profile_clarification:${request.callId}',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: DomainToolOutcomeStatuses.needsUserConfirmation,
      permissionDecision: const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.needsUserConfirmation,
        reason: '需要用户提供最小规则澄清后再继续。',
        policyRef: 'policy.profile_clarification_waiting_user',
      ),
      outcomePayload: <String, Object?>{
        'clarification_request': clarification.toJson(),
        'question': clarification.question,
        'options': clarification.options
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'freeform_allowed': clarification.freeformAllowed,
        'blocking': clarification.blocking,
        'blocks_progress': clarification.blocking,
        'option_count': clarification.options.length,
      },
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
      metadata: ValueReaders.deepCopyMap(<String, Object?>{
        'reason': clarification.reason,
        'blocking': clarification.blocking,
        'permission_disposition': permissionDecision.disposition,
      }),
    );
  }

  DomainToolOutcome _invalidPayloadOutcome({
    required DomainToolRequest request,
    required String message,
    JsonMap errorDetails = const <String, Object?>{},
  }) {
    return DomainToolOutcome(
      outcomeId:
          'request_profile_clarification:${request.callId}:invalid_payload',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
      permissionDecision: const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.accepted,
      ),
      error: DomainToolError(
        errorCode: 'invalid_request_profile_clarification_payload',
        message: message,
        errorDetails: ValueReaders.deepCopyMap(errorDetails),
      ),
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
    );
  }
}
