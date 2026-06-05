import '../../information.dart';
import '../../continuity/narrative_state.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_request.dart';
import 'information_domain_tool_handler_support.dart';
import 'narrative_domain_tool_capability.dart';
import 'narrative_domain_tool_handler.dart';
import 'narrative_domain_tool_names.dart';

class LinkInformationEvidenceHandler implements NarrativeDomainToolHandler {
  const LinkInformationEvidenceHandler({
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
        toolName: NarrativeDomainToolNames.linkInformationEvidence,
        displayName: '链接信息证据',
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
    // 中文注释: 信息链路只建立结构化证据关系，不读取正文语义，也不在这里推断关系真假。
    final link = InformationLink.fromJson(request.requestPayload);
    final validationErrors = link.validateBasics();
    if (validationErrors.isNotEmpty) {
      return _handlerSupport.buildInvalidPayloadOutcome(
        request: request,
        outcomeIdPrefix: NarrativeDomainToolNames.linkInformationEvidence,
        errorCode: 'invalid_link_information_evidence_payload',
        message: 'link_information_evidence 的信息链路存在结构错误。',
        errorDetails: <String, Object?>{'validation_errors': validationErrors},
        metadata: <String, Object?>{
          'upstream_permission_decision': permissionDecision.toJson(),
        },
      );
    }

    final informationPermissionDecision = _permissionPolicyService
        .decideInformationLink(link);
    return _handlerSupport.buildStructuredOutcome(
      request: request,
      outcomeIdPrefix: NarrativeDomainToolNames.linkInformationEvidence,
      informationPermissionDecision: informationPermissionDecision,
      upstreamPermissionDecision: permissionDecision,
      forbiddenErrorCode: 'forbidden_link_information_evidence_payload',
      forbiddenMessage: '当前信息链路包含禁止自动应用的 payload。',
      outcomePayload: <String, Object?>{
        'information_link': link.toJson(),
        'link_registered': true,
        'source_ref': link.sourceRef.toJson(),
        'target_ref': link.targetRef.toJson(),
      },
      metadata: <String, Object?>{
        'link_type': link.linkType,
        'created_by': link.createdBy,
      },
    );
  }
}
