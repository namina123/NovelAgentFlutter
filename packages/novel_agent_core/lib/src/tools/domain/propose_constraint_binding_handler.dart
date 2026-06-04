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

class ProposeConstraintBindingHandler implements NarrativeDomainToolHandler {
  const ProposeConstraintBindingHandler();

  @override
  NarrativeDomainToolCapability get capability =>
      const NarrativeDomainToolCapability(
        toolName: NarrativeDomainToolNames.proposeConstraintBinding,
        displayName: '提出约束绑定',
        supportedSourceTypes: <String>[
          NarrativeSourceTypes.user,
          NarrativeSourceTypes.system,
          NarrativeSourceTypes.deconstruction,
        ],
      );

  @override
  Future<DomainToolOutcome> handle({
    required DomainToolRequest request,
    required DomainToolPermissionDecision permissionDecision,
  }) async {
    final proposal = NarrativeConstraintBindingProposal.fromJson(
      request.requestPayload,
    );
    final validationErrors = proposal.validateBasics();
    if (validationErrors.isNotEmpty) {
      return _invalidPayloadOutcome(
        request: request,
        message: 'constraint binding proposal 存在结构错误。',
        errorDetails: <String, Object?>{'validation_errors': validationErrors},
      );
    }

    return DomainToolOutcome(
      outcomeId: 'propose_constraint_binding:${request.callId}',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: _outcomeStatusFor(permissionDecision.disposition),
      permissionDecision: permissionDecision,
      outcomePayload: <String, Object?>{
        'binding_proposal': proposal.toJson(),
        'requires_user_confirmation':
            permissionDecision.disposition ==
            DomainToolPermissionDispositions.needsUserConfirmation,
        'scope': proposal.scope.toJson(),
        'policy': proposal.policy.toJson(),
      },
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
      metadata: <String, Object?>{
        'constraint_type': proposal.constraintType,
        'applies_to': proposal.scope.appliesTo,
      },
    );
  }

  DomainToolOutcome _invalidPayloadOutcome({
    required DomainToolRequest request,
    required String message,
    JsonMap errorDetails = const <String, Object?>{},
  }) {
    return DomainToolOutcome(
      outcomeId: 'propose_constraint_binding:${request.callId}:invalid_payload',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
      permissionDecision: const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.accepted,
      ),
      error: DomainToolError(
        errorCode: 'invalid_propose_constraint_binding_payload',
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
