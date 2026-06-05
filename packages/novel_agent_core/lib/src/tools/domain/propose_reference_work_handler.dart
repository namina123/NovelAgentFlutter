import '../../information.dart';
import '../../continuity/narrative_state.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_request.dart';
import 'information_domain_tool_handler_support.dart';
import 'narrative_domain_tool_capability.dart';
import 'narrative_domain_tool_handler.dart';
import 'narrative_domain_tool_names.dart';

class ProposeReferenceWorkHandler implements NarrativeDomainToolHandler {
  const ProposeReferenceWorkHandler({
    InformationPermissionPolicyService? permissionPolicyService,
    InformationDomainToolHandlerSupport? handlerSupport,
  }) : _permissionPolicyService =
           permissionPolicyService ??
           const InformationPermissionPolicyService(),
       _handlerSupport =
           handlerSupport ?? const InformationDomainToolHandlerSupport();

  final InformationPermissionPolicyService _permissionPolicyService;
  final InformationDomainToolHandlerSupport _handlerSupport;

  @override
  NarrativeDomainToolCapability get capability =>
      const NarrativeDomainToolCapability(
        toolName: NarrativeDomainToolNames.proposeReferenceWork,
        displayName: '提出引用作品边界',
        supportedSourceTypes: <String>[
          NarrativeSourceTypes.writer,
          NarrativeSourceTypes.reviewer,
          NarrativeSourceTypes.deconstruction,
          NarrativeSourceTypes.explainer,
          NarrativeSourceTypes.explainerInterpreted,
          NarrativeSourceTypes.user,
          NarrativeSourceTypes.system,
        ],
      );

  @override
  Future<DomainToolOutcome> handle({
    required DomainToolRequest request,
    required DomainToolPermissionDecision permissionDecision,
  }) async {
    // 中文注释: 引用作品边界只能先变成结构化提案，真正是否可长期采用仍交给后续确认链处理。
    final record = ReferenceWorkRecord.fromJson(request.requestPayload);
    final validationErrors = record.validateBasics();
    if (validationErrors.isNotEmpty) {
      return _handlerSupport.buildInvalidPayloadOutcome(
        request: request,
        outcomeIdPrefix: NarrativeDomainToolNames.proposeReferenceWork,
        errorCode: 'invalid_propose_reference_work_payload',
        message: 'propose_reference_work 的引用作品记录存在结构错误。',
        errorDetails: <String, Object?>{'validation_errors': validationErrors},
        metadata: <String, Object?>{
          'upstream_permission_decision': permissionDecision.toJson(),
        },
      );
    }

    final informationPermissionDecision = _permissionPolicyService
        .decideReferenceWork(record);
    return _handlerSupport.buildStructuredOutcome(
      request: request,
      outcomeIdPrefix: NarrativeDomainToolNames.proposeReferenceWork,
      informationPermissionDecision: informationPermissionDecision,
      upstreamPermissionDecision: permissionDecision,
      forbiddenErrorCode: 'forbidden_propose_reference_work_payload',
      forbiddenMessage: '当前引用作品记录包含禁止自动应用的 payload。',
      outcomePayload: <String, Object?>{
        'reference_work': record.toJson(),
        'requires_user_confirmation':
            informationPermissionDecision.disposition ==
            InformationPermissionDispositions.needsUserConfirmation,
        'risk_note_count': record.riskNotes.length,
        'relationship_to_project': record.relationshipToProject,
      },
      metadata: <String, Object?>{
        'reference_work_id': record.referenceWorkId,
        'requires_confirmation': record.requiresConfirmation,
      },
    );
  }
}
