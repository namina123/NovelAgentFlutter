import '../../information.dart';
import '../../continuity/narrative_state.dart';
import 'domain_tool_outcome.dart';
import 'domain_tool_permission_decision.dart';
import 'domain_tool_request.dart';
import 'information_domain_tool_handler_support.dart';
import 'narrative_domain_tool_capability.dart';
import 'narrative_domain_tool_handler.dart';
import 'narrative_domain_tool_names.dart';

class ProposeDesignElementHandler implements NarrativeDomainToolHandler {
  const ProposeDesignElementHandler({
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
        toolName: NarrativeDomainToolNames.proposeDesignElement,
        displayName: '提出设计元素',
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
    // 中文注释: 设计元素是本主线的一等信息对象，这里必须把巧思/结构设计单独收口为稳定结果。
    final card = DesignElementCard.fromJson(request.requestPayload);
    final validationErrors = card.validateBasics();
    if (validationErrors.isNotEmpty) {
      return _handlerSupport.buildInvalidPayloadOutcome(
        request: request,
        outcomeIdPrefix: NarrativeDomainToolNames.proposeDesignElement,
        errorCode: 'invalid_propose_design_element_payload',
        message: 'propose_design_element 的设计元素存在结构错误。',
        errorDetails: <String, Object?>{'validation_errors': validationErrors},
        metadata: <String, Object?>{
          'upstream_permission_decision': permissionDecision.toJson(),
        },
      );
    }

    final informationPermissionDecision = _permissionPolicyService
        .decideDesignElement(card);
    return _handlerSupport.buildStructuredOutcome(
      request: request,
      outcomeIdPrefix: NarrativeDomainToolNames.proposeDesignElement,
      informationPermissionDecision: informationPermissionDecision,
      upstreamPermissionDecision: permissionDecision,
      forbiddenErrorCode: 'forbidden_propose_design_element_payload',
      forbiddenMessage: '当前设计元素 proposal 包含禁止自动应用的 payload。',
      outcomePayload: <String, Object?>{
        'design_element': card.toJson(),
        'requires_user_confirmation':
            informationPermissionDecision.disposition ==
            InformationPermissionDispositions.needsUserConfirmation,
        'activation_policy': card.activationPolicy.toJson(),
        'usage_policy': card.usagePolicy.toJson(),
        'linked_ref_count': card.linkedRefs.length,
      },
      metadata: <String, Object?>{
        'design_namespace': card.designNamespace,
        'design_label': card.designLabel,
        'source_authorities': card.sourceRefs
            .map((entry) => entry.sourceAuthority)
            .toSet()
            .toList(growable: false),
      },
    );
  }
}
