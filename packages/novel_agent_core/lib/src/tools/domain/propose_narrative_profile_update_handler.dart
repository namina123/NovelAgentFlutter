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

class ProposeNarrativeProfileUpdateHandler
    implements NarrativeDomainToolHandler {
  const ProposeNarrativeProfileUpdateHandler();

  @override
  NarrativeDomainToolCapability get capability =>
      const NarrativeDomainToolCapability(
        toolName: NarrativeDomainToolNames.proposeNarrativeProfileUpdate,
        displayName: '提出项目叙事解释器更新',
        supportedSourceTypes: <String>[
          NarrativeSourceTypes.deconstruction,
          NarrativeSourceTypes.user,
          NarrativeSourceTypes.system,
          NarrativeSourceTypes.explainer,
          NarrativeSourceTypes.explainerInterpreted,
        ],
      );

  @override
  Future<DomainToolOutcome> handle({
    required DomainToolRequest request,
    required DomainToolPermissionDecision permissionDecision,
  }) async {
    final proposal = NarrativeProfileProposal.fromJson(request.requestPayload);
    final validationErrors = proposal.validateBasics();
    if (validationErrors.isNotEmpty) {
      return _invalidPayloadOutcome(
        request: request,
        message: 'profile proposal 存在结构错误。',
        errorDetails: <String, Object?>{'validation_errors': validationErrors},
      );
    }

    return DomainToolOutcome(
      outcomeId: 'propose_narrative_profile_update:${request.callId}',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: _outcomeStatusFor(permissionDecision.disposition),
      permissionDecision: permissionDecision,
      outcomePayload: <String, Object?>{
        'proposal': proposal.toJson(),
        'evidence_refs': ValueReaders.mapList(
          request.requestPayload['evidence_refs'],
        ),
        'uncertainty': ValueReaders.stringValue(
          request.requestPayload['uncertainty'],
        ).trim(),
        'requires_user_confirmation':
            permissionDecision.disposition ==
                DomainToolPermissionDispositions.needsUserConfirmation ||
            proposal.requiresUserConfirmation,
      },
      toolRoundEvidence: request.toolRoundEvidence,
      schemaVersion: request.schemaVersion,
      metadata: <String, Object?>{
        'proposal_status': proposal.proposalStatus.id,
        'target_profile_id': proposal.targetProfileId,
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
          'propose_narrative_profile_update:${request.callId}:invalid_payload',
      callId: request.callId,
      toolName: request.toolName,
      outcomeStatus: DomainToolOutcomeStatuses.invalidPayload,
      permissionDecision: const DomainToolPermissionDecision(
        disposition: DomainToolPermissionDispositions.accepted,
      ),
      error: DomainToolError(
        errorCode: 'invalid_propose_narrative_profile_update_payload',
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
