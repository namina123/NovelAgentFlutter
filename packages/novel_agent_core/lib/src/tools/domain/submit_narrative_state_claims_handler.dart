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

class SubmitNarrativeStateClaimsHandler implements NarrativeDomainToolHandler {
  const SubmitNarrativeStateClaimsHandler();

  @override
  NarrativeDomainToolCapability get capability =>
      const NarrativeDomainToolCapability(
        toolName: NarrativeDomainToolNames.submitNarrativeStateClaims,
        displayName: '提交叙事状态声明',
        supportedSourceTypes: <String>[
          NarrativeSourceTypes.writer,
          NarrativeSourceTypes.reviewer,
          NarrativeSourceTypes.deconstruction,
          NarrativeSourceTypes.explainer,
          NarrativeSourceTypes.explainerInterpreted,
          NarrativeSourceTypes.user,
          NarrativeSourceTypes.system,
          NarrativeSourceTypes.recovery,
        ],
      );

  @override
  Future<DomainToolOutcome> handle({
    required DomainToolRequest request,
    required DomainToolPermissionDecision permissionDecision,
  }) async {
    final claimJsonList = ValueReaders.mapList(
      request.requestPayload['claims'],
    );
    if (claimJsonList.isEmpty && request.requestPayload['claims'] != null) {
      return _invalidPayloadOutcome(
        request: request,
        message: 'submit_narrative_state_claims 的 claims 必须是对象数组。',
      );
    }

    final claims = claimJsonList
        .map(NarrativeStateClaim.fromJson)
        .toList(growable: false);
    final validationErrors = claims
        .expand((claim) => claim.validateBasics())
        .toList(growable: false);
    if (validationErrors.isNotEmpty) {
      return _invalidPayloadOutcome(
        request: request,
        message: '提交的 narrative state claims 存在结构错误。',
        errorDetails: <String, Object?>{'validation_errors': validationErrors},
      );
    }

    return DomainToolOutcome(
      outcomeId: 'submit_narrative_state_claims:${request.callId}',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: _outcomeStatusFor(permissionDecision.disposition),
      permissionDecision: permissionDecision,
      outcomePayload: <String, Object?>{
        'source': request.source.toJson(),
        'claims': claims.map((entry) => entry.toJson()).toList(growable: false),
        'claim_count': claims.length,
        'claim_namespaces': claims
            .map((entry) => entry.claimNamespace)
            .toSet()
            .toList(growable: false),
        'evidence_refs': claims
            .expand((entry) => entry.evidenceRefs)
            .map((entry) => entry.toJson())
            .toList(growable: false),
        'metadata': ValueReaders.deepCopyMap(
          ValueReaders.mapValue(request.requestPayload['metadata']),
        ),
      },
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
      metadata: <String, Object?>{
        'claim_count': claims.length,
        'permission_disposition': permissionDecision.disposition,
      },
    );
  }

  DomainToolOutcome _invalidPayloadOutcome({
    required DomainToolRequest request,
    required String message,
    JsonMap errorDetails = const <String, Object?>{},
  }) {
    return DomainToolOutcome(
      outcomeId:
          'submit_narrative_state_claims:${request.callId}:invalid_payload',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
      permissionDecision: const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.accepted,
      ),
      error: DomainToolError(
        errorCode: 'invalid_submit_narrative_state_claims_payload',
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
